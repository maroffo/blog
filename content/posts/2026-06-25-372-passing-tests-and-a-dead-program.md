---
title: "372 Passing Tests and a Dead Program"
date: 2026-06-25
summary: "A coding agent wrote 21,000 lines of Go and 372 passing tests. The program was dead on the first run: three subsystems built, tested, and never wired together. Green is a proxy, and something was optimizing the proxy while the working program stayed invisible."
tags: ["ai", "llm", "testing", "engineering"]
draft: false
cover:
  image: "images/cover-372-passing-tests-and-a-dead-program.png"
  alt: "A wall of hand-drawn checkmarks above a dark, unplugged computer terminal"
  relative: false
---

Seven months ago I ended a post with three words: [tests green, committed, done]({{< ref "2025-11-30-from-skills-to-shipping-building-with-claude-as-a-pair-programmer" >}}). I want to take them back.

Here is the program that made me want all three back. A command-line coding agent, written in Go, around 21,000 lines of it. 372 tests, all green. The provider layer was tested. The config merge was tested. The agent loop was tested. I had been building it for weeks, mostly by driving an AI agent through it, and the suite had been green the whole way. I ran those tests constantly. What I had not done, not once in all those weeks, was build the actual binary and use it the way a user would. So I did: built it, ran it, typed a prompt.

`no provider registered for API`.

Not a crash. Not a flaky failure I could re-run. The program was dead. It had never worked, not once, and 372 passing tests had told me nothing about that.

You already have the objection ready, and you are right: I forgot to write an integration test. The wiring itself was about fifty lines of glue across five files, the kind of thing you type without thinking. The test that would have caught its absence, one smoke test that actually runs the program, I never wrote at all. Junior-year material, both halves. Hold that thought, because the triviality is the entire point. Of course it was carelessness, I never ran my own program. But it is a specific, modern flavor of it: the kind a system cultivates when it optimizes for green and nobody checks the green against reality. The distance between how invisible the failure was and how stupid-small the fix turned out to be is the shape carelessness takes when a machine is paid to keep the bar green.

This is not the failure I wrote about when [agents game the signal]({{< ref "2026-04-05-agents-delete-good-code-heres-how-im-stopping-them" >}}), weakening an assertion or stubbing a function to force the bar green. Here nothing was faked. The tests were honest, the units real, the assertions sharp. The program was still dead. That is the quieter failure, and the one I want.

***

### Anatomy of a dead program

Three subsystems, each finished, each tested, none connected.

The provider registry was created empty. The function that fills it, the single call that registers all nine providers, was never invoked. So every lookup returned "nothing here," and every prompt died at the first step. The registry had tests. They built their own registry, registered a fake provider, checked that lookup worked, and passed. They never asked whether the real registry, the one the program actually uses, was ever populated.

The settings manager failed even more quietly. Fully implemented, two-level merge, tested and correct. Never instantiated, though, so every setting you set was read by nothing and silently ignored: no error, just hardcoded defaults. A third wire, an API key read from the environment and never handed to the thing that makes the network call, shared the same fate.

Every one of these had thorough unit tests. The merge tests verified merging, the registration tests verified registration, the loop tests verified the loop. The one function whose entire job was to connect them, the `run()` that builds the registry, fills it, reads the settings, and starts the loop, was the only thing no test touched. It was also the only thing that mattered.

***

### The seam has no test, and the agent has no reason to build one

Here is the part that is actually about AI, and it is not "the AI made a mistake."

A unit test, by construction, mocks the seam away. To test the provider layer in isolation you hand it a registry. To test the loop you hand it a provider. Every test manufactures the connections it needs, then verifies the thing on one side of them. The connections themselves, the wiring between units, are the one thing the whole testing strategy is built to avoid. 372 green means 372 units work alone. It is almost silent on whether they are joined.

Humans hit this too. The difference is what happens next. A human, at some point, runs the damn program. Not out of discipline, out of impatience: you want to see your thing work, so you run it, it says `no provider registered`, and you fix it in the first hour. You get burned once and you keep the scar. The reflex, "did I actually run it," becomes part of how you work.

An agent has no such hour. I built most of this by driving an agent through it, and the agent's world is the test runner. Green is the signal it optimizes, because green is the signal I gave it. It writes a unit, writes the test, sees green, moves on. It generates 372 of them faster than I can read them, which makes the green more seductive, not less. At no point does anything in its loop build the binary and type a prompt, because "run the program and see if it lives" was never an instruction, and the agent has no impatience of its own. It does not want to see the thing work. It wants the tests to pass. They passed.

Look at what was and was not being measured. I had a test for every unit and no measure at all for "the program runs." That measure did not exist in my loop. So green, the only signal in the room, filled the vacuum: I heard "the units pass" and answered "the thing works," because nothing else was speaking. Reading a proxy as the goal it stands for has a name in the measurement literature, surrogation, and you will see it cleaner in the next two stories, where there genuinely was a proxy, a 200, a login screen, and I took it for the outcome. Here it is rougher: I did not even have a proxy for "it works," I had its absence, and I let green stand in for a thing I was never measuring.

The agent is the limit case, and it is stranger than I am. I confused the measure for the thing out of fatigue, knowing green was a proxy and letting it stand for the whole anyway. The agent never had a "whole" to lose. Green was the only signal I gave it, so green was the only thing it could optimize; it was not mistaking the proxy for the goal, it simply had no goal in there, only the proxy. A fully green suite is not a working program, and the agent had no way to feel the difference, because the difference was never in its world.

***

### A 200 that means nothing

If this were only about unit tests, or only about agents, it would be a checklist item: write a smoke test, move on. It is neither. The same substitution shows up with no test suite and no agent within a mile of it, just a different green. That is the argument, not a detour from it: surrogation is not something AI does to you, it is something you already do, and the agent only makes it cheap, fast, and tireless.

We run a config control plane for a security gateway. You push a new config, the API returns 200, the dashboard shows the new revision. Green. Except the gateway runs as a fleet, five pods behind a load balancer, and the push lands on one of them. The version it tracks, the history it keeps, all of it is per-pod. There is no consensus, no convergence, nobody asking the other four whether they got the message. So you push a rule change, you get your 200, your dashboard turns green, and four pods out of five are still enforcing the old rules. On a security gateway.

Notice what the 200 actually told me. It told me one pod accepted one POST. I read it as "the deploy worked." Those are different sentences, and the distance between them is exactly the distance between the green test and the working program. The success signal described a step. I treated it as the outcome.

And yes, the deeper bug is the design. A control plane that writes to one pod of five and calls it done has no business existing; I knew that, it was on the backlog, waiting for a day I felt less comfortable. The 200 did not deceive me, it sedated me. Every push lit the dashboard green, and a green dashboard is a standing permission to leave a known risk exactly where it sits. The status code never lied about what it was, one pod, one POST, accepted; it just kept handing me a reason not to move the fix up the list.

***

### A screen that lies

The weakest verification I trusted, and the most expensive when it broke, had no return code at all. Just a person looking at a screen. Me.

We migrated our auth to a hosted identity provider, the standard OIDC dance. You click "Sign out." The app clears its session tokens, the screen returns to the login page. It looks exactly like logging out looks.

The provider's session was alive the entire time. Logging out there takes two steps: clear our app's session, then send the browser through the provider's logout endpoint so it drops its own. We had wired the first and skipped the second, and the first revokes nothing on their side. So the app forgot you, the screen agreed, and the provider quietly kept you logged in. The tell was the next "Sign in with Google": no account picker, no password prompt, an instant silent bounce straight back in, because as far as the provider was concerned you had never left.

There was no test to be green here. The "test" was me, tired, looking at a login page and reading "login page" as "logged out." It is the same substitution as the 200 and the 372, one rung lower. The binary had a full green suite. The fleet had a return code. The logout had a screen and a human glance. I clicked that screen a hundred times and trusted it more than I trusted the 372 tests, because it looked more like the truth than a test result ever does.

***

### Every signal was telling the truth

Line them up.

A real, honest test suite. An HTTP 200. A screen showing the login page. Each one is a proxy for a thing I actually cared about: a program that runs, a fleet that serves the right rules, a session that is dead. Each proxy is something the system says about itself. None of them is the thing.

Not one of these signals was lying. The suite really did prove the units worked, the 200 really did mean one pod took the write, the login screen really did appear. Each was honest about its own small part. I was the one who took the part for the whole, every time. And the substitution got easier as the stakes rose, not harder, because the closer a signal sits to what a user actually sees, the more it feels like the outcome itself. A login screen feels like proof in a way a unit test never does. That is surrogation doing its work: the better a proxy mimics the goal, the less I notice I am holding the proxy.

This is a different failure from the [perception problem I wrote about recently]({{< ref "2026-06-17-the-ai-said-mandatory-i-measured-23-percent-slower" >}}). There the model was blind, reasoning about text while my code ran, unable to see the thing. Here nothing is blind: the agent saw the green perfectly, the 200 was accurate, the screen was real. I optimized the signal, and the outcome was never in the loop. I saw the proxy perfectly and called it the outcome.

***

### What actually catches this

Three failures, three fixes, and they are not the same fix, which is what "just write integration tests" misses.

The binary needed one path that runs `run()` end to end: build the real registry, fill it, read settings off disk, get a provider, run one prompt against a fake server. It would have failed on its first line, the empty registry. Not because end-to-end beats unit, they do different jobs, but because all 372 of mine sat on the safe side of the seam, and the failure was on the other side.

The fleet needed the opposite of a test: the control plane has to stop trusting its own 200 and ask all five pods what they serve, staying un-green until they agree. Convergence is not asserted once in CI, it is observed in production, continuously.

The logout needed an outcome check a tired human cannot fake: after sign-out, hit the provider and confirm the session is dead, not that the screen changed. Assert the thing, the session is gone, not the proxy, the page navigated.

And for the agent, the one that started all this, the fix lives in the loop, not the code. If green is the only signal the agent optimizes, then "green" has to include "the program ran and did the thing," or it will keep handing me beautiful dead binaries forever, correctly, on purpose, because that is what I rewarded. I already add [guards to the harness]({{< ref "2026-03-31-your-ai-harness-is-hand-crafted-thats-the-problem" >}}) for agents that cut corners, that weaken a test to reach green. This is the opposite guard for the opposite sin: not the agent faking the work, but the work being honestly, fully tested and still never run once. The harness has to insist the program runs, because the agent has no reason of its own to want to.

And there is a trap folded inside that fix, the same trap one level up. The moment the smoke test joins the agent's loop, the smoke test becomes the new green, and the agent optimizes it the only way it knows: mock the shell, stub the fake server's reply, hard-wire the expected output until the end-to-end test passes without anything end-to-end ever happening. Whatever signal I put in front of it becomes a target, and a target it can satisfy by faking is one it eventually fakes. The only check that survives is one the agent cannot author: the real binary, run in a sandbox it does not control, by something outside its loop, or a human who looks at the seam on purpose. The verification has to live where the optimization cannot reach it. Otherwise I have not killed the dead program, I have promoted it into a green integration test that proves nothing.

The obvious caveat, because three confirming war stories from one author is exactly how you fool yourself: green is right the overwhelming majority of the time. Tests are not the enemy, and I am not arguing for fewer of them. The point is narrower and meaner. There is a specific class of failure where every available signal is green and the thing is still dead, and the only way to know you are in that class is to check the outcome directly, once, instead of the proxy that stands in for it.

***

### The expensive comfort of green

I shipped all three of these. Not a junior on my team, me, with the scar tissue and the blog posts about exactly this. The answer is in [another thing I wrote]({{< ref "2026-03-06-ai-didnt-reduce-my-cognitive-load-it-moved-it" >}}): I end these days tired not from writing code but from evaluating decisions, and green is the one decision you do not have to make. When the evaluation budget is gone, a flat field of passing tests asks nothing of you, and I took the path of least cognitive load. The plainer version is that I was tired and did not run it.

The discipline is not "distrust your tests," which is useless. It is knowing exactly what a green test is evidence of, the unit, and what it is silent about, the seam, and refusing to read the silence as a yes. Two of my three checks were nearly free, one run of the binary, one look at the provider instead of the screen; the fleet's needed real convergence machinery and was not free at all. I skipped all of them, the free ones included, on the nights I was too tired to want them.

The agent will not cover for me, and not because it is careless. The opposite: it never tires, so it never reaches the moment where I trade the territory for the map. It has no territory; it lives in the map. It does not learn from a dead binary, nothing punished it, it learns from the green, because that is what passed. The test passed. Next task. I am the only one in the loop who can be made to care that the program never ran, and that is where the job has gone. Not writing the nodes, the agent is genuinely good at the nodes. Standing at the seams, where the nodes meet a reality neither of us has checked, and checking it.

***

*The dead binary, the config plane, and the logout are all real, from my own systems; I have genericized the internals. The counts, 372 tests and roughly 21,000 lines, are from the repo, not from memory. This was written with the same kind of agent it describes, which did not run itself to check, because running itself was not in the loop. That remains the whole problem.*
