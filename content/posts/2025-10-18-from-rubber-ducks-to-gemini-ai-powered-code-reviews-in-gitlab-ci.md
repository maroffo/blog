---
title: "From Rubber Ducks to Gemini: AI-Powered Code Reviews in GitLab CI"
date: 2025-10-18
summary: "A follow-up to our automation journey, where we integrate AI-powered code reviews directly into our CI/CD pipelines, and discover that Gemini is a much better conversation partner than a rubber duck."
tags: ["ai", "devops", "code-review", "wishew"]
draft: false
cover:
  image: "images/cover-rubber-ducks-gemini.png"
  alt: "From Rubber Ducks to Gemini: AI-Powered Code Reviews in GitLab CI"
  relative: false
---

In my [previous article](/blog/posts/2025-10-03-building-a-smart-ecs-deployment-notifier-with-aws-lambda-gitlab-and-slack/), I shared how we built an ECS deployment notification system. That was one of the first steps in my return to hands-on infrastructure work at Wishew, with the goal of improving automation processes. But notifications are just the beginning. The real objective is to create a development ecosystem that is as efficient, consistent, and automated as possible, allowing the team to focus on what truly matters: writing quality code.

Now, I want to share another chapter in this journey: how we transformed our GitLab CI pipelines from simple build and test runners into true development assistants, using reusable templates and, most importantly, integrating a code reviewer based on Google’s Gemini AI.

## The foundation: GitLab CI templates

Let me start with something that might sound boring but is actually game-changing: **GitLab CI Templates**.

When I started focusing on our automation processes at Wishew, the CI/CD setup was fragmented. Our backend services used GitLab CI, while our mobile apps were built on CircleCI. As we planned to introduce new, standardized features across all projects, like the AI code reviewer this article is about, we faced a choice: either build the same logic multiple times on different platforms, or create a unified foundation.

To me, the path forward was clear. We decided to do things the right way from the start. For any new, shared CI/CD logic, we would standardize on GitLab and leverage its powerful template engine. We created a central repository, **_automation/ci-templates_**, to host all our standardized logic. Think of it as a library of reusable pipeline components that any project can include and use

### Why this matters

This approach gives us some serious advantages:

1. **Consistency**: All projects use the same, battle-tested procedures. No more “but it works in the iOS project” mysteries.
2. **Maintainability**: Need to fix a bug or add a feature? Change it once in the template, and it automatically propagates to all projects that use it.
3. **Reusability**: Complex logic, like interacting with external APIs or setting up deployment notifications, is written once and reused everywhere.
4. **Experimentation**: Want to try a new tool or approach? Test it in one template without touching every project’s pipeline.

## How it works in practice

Using a template is incredibly simple. A project just needs to include it in its **_.gitlab-ci.yml_**:

```
# .gitlab-ci.yml in an application project

include:
  # Always include Gemini code review
  - project: "wishew/automation/ci-templates"
    ref: main
    file: "/gemini-review.yml"

stages:
  - review
```

That’s it. Three lines of code, and your project now has AI-powered code reviews. Want to add security scanning? Include another template. Need deployment notifications? Another include statement.

Simple, clean, and powerful. This template system became the foundation for everything else we built, including our AI code reviewer.

## Gemini: our AI code reviewer

Code review is an essential activity, but let’s be honest: it’s also time-consuming and sometimes tedious. To make it faster and more objective, we decided to integrate an AI agent directly into our pipeline. Whenever a Merge Request (MR) is opened, a specific job analyzes the changes and leaves precise comments, just like a human reviewer would, but without the coffee breaks.

At the core of this system is our **_gemini-review.yml_** template.

### How it works

The template defines a job, **_gemini\_cli\_code\_review_**, that only runs for Merge Requests. Here are the key components:

**1. The Docker Image**

We use an official image provided by Google, **_us-docker.pkg.dev/gemini-code-dev/gemini-cli/sandbox_**, which contains the Gemini CLI and all the necessary tools.

**2. The Prompt**

We define the AI’s “personality” and instructions through environment variables. This is the most important part, where we turn a generic model into a specialized assistant:

```
variables:
  GEMINI_PROMPT_PERSONA: |
    You are a code reviewer. Your task is to review the merge request !${CI_MERGE_REQUEST_IID} in the GitLab project ${CI_MERGE_REQUEST_PROJECT_URL}...
  GEMINI_PROMPT_GUIDELINES: |
    Check also test coverage and whether testing coverage of the changes could be improved. Do not check test coverage on code that was already present...
  GEMINI_PROMPT_INSTRUCTIONS: |
    When you post your review, you must make it clear that it was performed by an AI agent by starting your comment with "AI Code Review:"...
```

We instruct the AI to identify itself, check for test coverage, and follow a precise workflow for adding its comments. The prompt engineering here matters a lot; we spent a lot of time refining these instructions to get meaningful feedback.

**3. The Tools**

To allow Gemini to interact with GitLab, we use a component called **_gitlab-mcp_**. This component connects Gemini to our repository, turning it from a passive text generator into an active agent. It exposes GitLab’s API as a set of “tools” that the AI can invoke, such as **_discussion\_new_** to create a new comment or **_get\_merge\_request\_changes_** to analyze the code. The configuration for these tools is dynamically written to the Gemini CLI’s **_settings.json_** file.

**4. The Execution**

Finally, we run the CLI in non-interactive mode ( **_--yolo_**), passing it the complete prompt. The AI analyzes the code, compares the changes against the guidelines, and if it finds something to report, it uses the available tools to leave comments directly on the Merge Request.

The result is a first layer of automated review that catches common errors, suggests improvements, and checks test coverage, freeing human reviewers to focus on business logic and architecture.

## Customizing the AI reviewer

The true power of this template-based approach lies in its flexibility. While the central **_gemini-review.yml_** template provides a solid foundation, each project can **override** its configuration to transform the generic AI reviewer into a specialist for its specific technology stack.

This is possible because of how GitLab CI merges configurations: any keys defined in a project’s **_.gitlab-ci.yml_** will take precedence over the keys in an included template.

### Example 1: an expert iOS reviewer

For our **iOS** projects, we need the AI to focus on Swift-specific best practices. In the project’s **_.gitlab-ci.yml_**, we simply redefine the **_gemini\_cli\_code\_review_** job and override its variables:

```
# .gitlab-ci.yml for an iOS project
include:
  - project: "wishew/automation/ci-templates"
    ref: main
    file: "/gemini-review.yml"

# Override the Gemini review job to provide a custom prompt for iOS/Swift.
gemini_cli_code_review:
  variables:
    GEMINI_PROMPT_PERSONA: |
      You are an expert iOS and Swift code reviewer.
    GEMINI_PROMPT_GUIDELINES: |
      You must follow these guidelines during your review:
      - **Swift Best Practices:** Check for proper use of optionals, error handling (try/catch), and immutability (let vs. var).
      - **Architecture:** Ensure the code follows the project's architecture (e.g., MVVM, VIPER). Look for "Massive View Controllers".
      - **UI (SwiftUI/UIKit):** Review UI code for performance, layout issues, and adherence to Apple's Human Interface Guidelines.
      - **Concurrency:** Check for correct use of Grand Central Dispatch (GCD), async/await, and thread safety.
      - **Memory Management:** Look for retain cycles and memory leaks.
```

By changing a few variables, we’ve transformed our generalist reviewer into an iOS expert that understands optionals, retain cycles, and Apple’s HIG.

### Example 2: a detail-oriented Ruby on Rails reviewer

For our **Ruby on Rails** backend, the requirements are completely different. We need to enforce strict conventions around security, performance, and architectural patterns like Service Objects:

```
# In a Ruby on Rails project's .gitlab-ci.yml
gemini_cli_code_review:
  variables:
    GEMINI_PROMPT_PERSONA: |
      You are an expert Ruby and Ruby on Rails code reviewer.
    GEMINI_PROMPT_GUIDELINES: |
      - **Security:** Check for common Rails vulnerabilities like SQL injection, XSS, and mass assignment.
      - **Performance:** Look for N+1 queries and suggest using `includes`. Advise caching where appropriate.
      - **Project Best Practices & Conventions:** Ensure that no business logic is in the models or controllers. Ensure that CRUD operations are contained within Service objects.
      - **Testing:** Ensure that code is covered by RSpec specs and that API endpoints are documented using RSwag.
```

### Example 3: the Android exception

Interestingly, for our **Android** project, we found that no specific customization was needed. The default prompt, which was our starting point for all other specializations, worked almost perfectly out of the box.

I have a couple of theories for this. The optimistic one is that Gemini, being a Google product, “plays at home” when dealing with the Android ecosystem. The more realistic, and likely, theory is that Filippo, who dedicated a significant amount of time to refining the base prompt, is an Android developer himself. He may have unconsciously crafted a “perfect” generic prompt that was already heavily biased toward Android best practices.

This happy accident is a good reminder: the “default” state of your tools is often shaped by the expertise and biases of those who build them.

This level of customization allows us to codify our team’s best practices and institutional knowledge directly into our CI/CD pipeline, ensuring that every line of code is held to the same high standard, regardless of the project.

## When your team becomes a team of one

Here’s something we didn’t anticipate when we set up Gemini: it would become most valuable during the times we least expected.

Wishew is a startup, which means we have a small team. And in a small team, when someone goes on vacation, you often end up being the only person working on a particular project. Suddenly, you’re reviewing your own code, and that’s when things can get risky.

We’ve all been there. You write some code, you read it over, it looks good to you (of course it does… you wrote it!), and you merge it. Then, three weeks later, someone else looks at it and asks, “Why did you do it this way?” And you realize that, yeah, maybe that wasn’t the best approach after all.

The classic solution to this problem is rubber duck debugging, explaining your code to an inanimate object to catch errors. But here’s the thing: the rubber duck doesn’t talk back. It doesn’t suggest better approaches. It doesn’t catch your subtle logic errors or remind you that you forgot to add tests.

Gemini does.

## Better than a rubber duck

When I’m working solo on a feature and open a merge request, Gemini is there, reviewing my changes. It points out things like:

* “This function doesn’t have test coverage.”
* “You’re using a deprecated API here.”
* “This could be simplified using \[some Swift/Ruby/JavaScript feature I forgot about].”
* “This change might introduce a retain cycle.”

Sure, it’s not perfect. Sometimes it flags false positives, and it doesn’t understand business logic the way a human reviewer would. But it’s remarkably effective at catching the technical issues that are easy to miss when you’re too close to the code.

More importantly, it forces me to think twice. Even when I disagree with Gemini’s suggestion, the act of considering it and articulating why I’m doing something differently makes me a better developer. It’s accountability without needing to wait for a human reviewer who might be on a beach in Thailand.

In a startup environment where we’re moving fast and the team is often stretched thin, having Gemini as a safety net has been invaluable. It’s not replacing human code review; we still do proper peer reviews. But it fills a real gap when human reviewers aren’t available.

## Key learnings

### 1. Prompt engineering is critical

The quality of AI reviews depends heavily on well-crafted prompts. We invested significant time refining our persona, guidelines, and instructions to get meaningful feedback. The difference between a generic “review this code” prompt and a well-structured one with clear guidelines is night and day.

### 2. Tool integration requires patience

We’ve found that Gemini doesn’t always recognize the full suite of tools made available by **_gitlab-mcp_**, sometimes leading to failures. Robust error handling and continuous prompt refinement are essential for a stable integration. This is still an evolving technology, and you need to be comfortable with occasional hiccups.

### 3. Balance automation with human judgment

Despite these occasional challenges, the AI has become a valuable addition to our review process. The suggestions are almost always on-point and useful, catching common issues while rarely suggesting dangerous changes. This frees human reviewers to focus on higher-level concerns like architecture and business logic.

## The road ahead: proactive security

This template system has already taken us far, but we’re not stopping here. The next goal is to integrate **security scanning** directly into our pipelines. We are evaluating tools like **Snyk** or **Trivy** to analyze our code and its dependencies for known vulnerabilities.

The idea is to create a new template, **_security-scan.yml_**, that can be easily added to any project to introduce another layer of control, making security an integral and automated part of our development lifecycle.

## Conclusion

Starting from the simple need for notifications, we’ve built a CI/CD framework that acts as a true partner to our development team. By centralizing logic in GitLab CI templates, we’ve created a scalable and maintainable system that automates code reviews with AI and fits naturally into our existing workflows.

The ability to override and specialize these templates on a per-project basis is key to this system’s success. It provides the perfect balance between centralized consistency and project-specific flexibility.

More importantly, we’ve discovered that AI code review isn’t just about catching bugs; it’s about ensuring that even when the team is stretched thin, there’s always someone (or something) providing a second pair of eyes. It won’t replace human reviewers, but it’s a hell of a lot better than talking to a rubber duck.

## Acknowledgments

This system wouldn’t exist without the team’s effort in refining the code review process. Setting up the prompts, testing the integration, and iterating on the feedback took significant time and patience.

A special thanks goes to Filippo, who sacrificed himself and did both alpha and beta testing while cursing at the AI. His feedback and persistence in working through the rough edges were invaluable in getting us to where we are today. Every time Gemini successfully catches a bug, we owe a small debt to Filippo’s willingness to be the guinea pig.

## Tools mentioned

Here are the links to the various tools and technologies discussed in this article:

* [**GitLab CI**](https://docs.gitlab.com/ee/ci/): The CI/CD platform used to build our automation pipelines.
* [**Google Gemini**](https://gemini.google.com/): The family of AI models powering our code reviewer.
* [**Gemini CLI**](https://github.com/google-gemini/gemini-cli): The command-line interface for interacting with the Gemini API.
* [**gitlab-mcp**](https://gitlab.com/fforster/gitlab-mcp): The Model Control Plane that provides tools for Gemini to interact with GitLab.
* [**Snyk**](https://snyk.io/): A developer security platform we are considering for future integration.
* [**Trivy**](https://trivy.dev/): An open-source security scanner we are also evaluating.

_This solution was built for the Wishew platform but is applicable to any GitLab-based infrastructure. Special thanks to the GitLab and Google Gemini communities for excellent documentation._
