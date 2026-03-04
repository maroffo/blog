---
title: "Building a Smart ECS Deployment Notifier with AWS Lambda, GitLab, and Slack"
date: 2025-10-03
summary: "How we built automated Slack notifications for ECS deployments with smart commit filtering, SSM state tracking, and Terraform IaC at Wishew."
tags: ["aws", "devops", "automation", "wishew"]
draft: false
cover:
  image: "images/cover-ecs-notifier.png"
  alt: "Building a Smart ECS Deployment Notifier with AWS Lambda, GitLab, and Slack"
  relative: false
---

## A new chapter: from CTO to individual contributor

After nearly 25 years in tech, I made a decision that some might see as unconventional: I left my CTO and Tech Lead roles, said goodbye to Bologna, and returned home to Sardinia to work as a Cloud Engineer and Architect at [Wishew](https://wishew.com/).

In the last two companies, I focused on people management and cybersecurity, first as Tech Lead at Shopfully, then as CTO at Iungo. While rewarding, sometimes I found myself missing the hands-on technical work that originally drew me to this field. When Wishew came looking for someone to help them move faster on their automation and infrastructure, and to transition away from an unwieldy third-party partner, it felt like the perfect opportunity to reset and return to my roots.

Some might view this as a step back in my career. For me, at this point in my life, it’s been incredibly lucky. Wishew is full of energy. Three exceptionally competent and committed founders, a CTO (older than me, thankfully! 😄) from whom I can still learn, and an extremely skilled and tight-knit team.

I won’t lie: I was a bit intimidated. Going from “the boss” to being one of the contributors was a situation I hadn’t experienced in many years. But so far, it’s going remarkably well. I hope to have more time to write about what I’m building.

This is the first of what I hope will be many posts documenting the technical work I’m doing at Wishew.

## Why we built this

When managing microservices on AWS ECS, staying informed about deployments matters. We needed a solution that would:

* **Notify our team instantly** when deployments start, succeed, or fail
* **Show what changed** between deployments by fetching GitLab commits
* **Filter noise** by removing merge commits and duplicates
* **Support multiple environments** (Staging and Production)

Instead of checking AWS console or CloudWatch logs manually, we built an automated notification system that delivers rich, contextual information directly to Slack.

## The architecture

Here’s what we built:

**Key Components:**

1. **EventBridge Rule**: Captures ECS deployment state changes
2. **Lambda Function**: Processes events and orchestrates notifications
3. **SSM Parameter Store**: Tracks the last deployed Docker image tag
4. **GitLab API**: Fetches commits between deployments
5. **Slack Webhook**: Delivers formatted notifications to our team

## How it works

### 1. Event detection

When an ECS deployment occurs, EventBridge captures three types of events:

* SERVICE\_DEPLOYMENT\_IN\_PROGRESS
* SERVICE\_DEPLOYMENT\_COMPLETED
* SERVICE\_DEPLOYMENT\_FAILED

### 2. Tag comparison

The Lambda function:

1. Queries ECS API to get the current Docker image tag
2. Retrieves the last deployed tag from SSM Parameter Store
3. Compares tags to determine if this is a new deployment

### 3. Fetching commits

If the tags differ, we query GitLab’s API to get all commits between the two versions:

```
def get_gitlab_commits_between_tags(from_tag, to_tag):
    url = f"{GITLAB_URL}/api/v4/projects/{GITLAB_PROJECT_ID}/repository/compare"
    params = {"from": from_tag, "to": to_tag}

    response = http.request(
        "GET",
        f"{url}?{urllib3.request.urlencode(params)}",
        headers={"PRIVATE-TOKEN": GITLAB_TOKEN}
    )
    return json.loads(response.data.decode("utf-8")).get("commits", [])
```

### 4. Smart filtering

We apply filtering to show only meaningful commits:

```
def format_commits_for_slack(commits, from_tag, to_tag):
    seen_titles = set()
    filtered_commits = []

    for commit in commits:
        title = commit.get("title", "No title")

        # Skip merge commits
        if title.lower().startswith("merge branch"):
            continue

        # Skip duplicates
        if title in seen_titles:
            continue

        seen_titles.add(title)
        filtered_commits.append(commit)

    # Limit to 10 commits
    return filtered_commits[:10]
```

### 5. Slack notification

We send formatted notifications using Slack’s Block Kit:

### 6. State persistence

On successful deployments, we save the current tag to SSM for the next comparison:

```
def save_deployed_tag(service_name, tag):
    param_name = f"/ecs/deployments/{service_name}/last-tag"
    ssm_client.put_parameter(
        Name=param_name,
        Value=tag,
        Type="String",
        Overwrite=True
    )
```

### Infrastructure as code

We initially deployed this Lambda manually, but quickly realized the need for automation. We structured the project to separate concerns: application code is isolated from IaC code.

```
ecs-deployment-notifier/
├── src/                      # Lambda source code
│   └── lambda_function.py
├── terraform/               # Infrastructure as Code
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── terraform.tfvars.example
└── README.md
```

### Terraform configuration

The main infrastructure components:

```
# Lambda Function
resource "aws_lambda_function" "ecs_notifier" {
  filename         = data.archive_file.lambda.output_path
  function_name    = var.function_name
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.11"

  environment {
    variables = {
      SLACK_WEBHOOK_URL  = var.slack_webhook_url
      GITLAB_TOKEN       = var.gitlab_token
      GITLAB_PROJECT_ID  = var.gitlab_project_id
    }
  }
}

# EventBridge Rule
resource "aws_cloudwatch_event_rule" "ecs_deployment" {
  event_pattern = jsonencode({
    source      = ["aws.ecs"]
    detail-type = ["ECS Deployment State Change"]
    detail = {
      eventName = [
        "SERVICE_DEPLOYMENT_IN_PROGRESS",
        "SERVICE_DEPLOYMENT_COMPLETED",
        "SERVICE_DEPLOYMENT_FAILED"
      ]
    }
  })
}
```

### Required permissions

The Lambda needs these IAM permissions:

```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:DescribeServices",
        "ecs:DescribeTaskDefinition"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:PutParameter"
      ],
      "Resource": "arn:aws:ssm:*:*:parameter/ecs/deployments/*"
    }
  ]
}
```

## Key learnings

### 1. Filter noise early

Without filtering, our Slack notifications were cluttered with merge commits and duplicates. Adding the filtering logic made the notifications actually useful.

### 2. Use SSM for state

SSM Parameter Store is perfect for storing small pieces of state like the last deployed tag. It’s serverless, cheap, and integrates natively with Lambda.

### 3. Idempotency matters

The Lambda can be invoked multiple times for the same event. We handle this gracefully by checking if the tag has actually changed before fetching commits.

## Conclusion

This ECS deployment notifier gave us clear visibility into what gets deployed and when, without checking the AWS console. By combining EventBridge, Lambda, SSM, and GitLab API, we built a simple solution that sends the right information to Slack at the right time.

The key to success was:

* **Separation of concerns** (src/ vs terraform/)
* **Smart filtering** (removing noise from commits)
* **State management** (tracking last deployed tags)
* **Infrastructure as Code** (Terraform for reproducibility)

If you’re running more than a couple of ECS services, automated deployment notifications save a lot of context-switching.

Want to implement this yourself? Check out the full source code and Terraform configuration on our [GitLab repository](https://gitlab.com/wishew/public/ecs-deploy-slack-notifier/).

_This solution was built for the Wishew platform but is applicable to any ECS-based infrastructure. Special thanks to the AWS and GitLab communities for excellent documentation._
