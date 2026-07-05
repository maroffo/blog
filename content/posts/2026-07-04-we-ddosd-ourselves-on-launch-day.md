---
title: "We DDoS'd Ourselves on Launch Day"
date: 2026-07-04
summary: "At 17:00 UTC on cutover day, a re-engagement cron pushed notifications to ~100K freshly migrated users. Every device token belonged to the old Firebase project, every call failed, every failure retried, and the whole backend was pinned to one instance. Nobody attacked us. We did."
tags: ["engineering", "devops", "cloud"]
draft: false
cover:
  image: "images/cover-we-ddosd-ourselves.png"
  alt: "We DDoS'd Ourselves on Launch Day"
  relative: false
---

Nobody attacked us. That is the embarrassing part.

The symptom read like a capacity problem: latency climbing on Cloud Run, Google login timing out. On the day you move production to a new cloud, that is the reading your brain reaches for: we sized something wrong. We had, but not in the way we thought. At 17:00 UTC sharp, our own re-engagement cron had woken up and begun, with perfect punctuality, to take the platform down.

A successful migration, a friendly reminder notification, standard retry logic, and a single configuration line. None of the four was broken. Together they were a denial of service we ran against ourselves. (Strictly speaking, not even a distributed one: one cron, one instance. The first D is honorary.)

***

### The setup

We had just finished moving a production social app, roughly 100K users, from a legacy AWS Rails stack to GCP. The cutover itself went smoothly, mostly because a trial migration a month earlier had de-risked the runbook. Data migrated, counts matched, services deployed, health checks green. The migration scripts reported success, and by every measure they knew about, they were right.

I wrote recently about [a program with 372 passing tests that had never worked once]({{< ref "2026-06-25-372-passing-tests-and-a-dead-program" >}}). The thesis of that post was that green is a proxy, and a system left alone will optimize the proxy instead of the outcome. A migration that reports success is the same proxy wearing operations clothing. The rows were copied. Whether the data still *meant* anything in its new home was a question nobody had asked it.

Among the migrated rows: every user's push notification device tokens, imported faithfully from the old stack's database dump.

***

### Four ingredients, all of them fine

Here is the full parts list of the outage. Read each line and notice that none of them, alone, is a bug.

| Ingredient | On its own |
|---|---|
| ~100K device tokens imported from the legacy database | Correct data, faithfully migrated |
| A daily cron that sends a re-engagement push to every user | A product feature, worked for years |
| Retry logic around failed notification calls | Standard resilience practice |
| `max_instances = 1` on the backend service | A deliberate scaling cap |

Now compose them.

A device token is not just a row: it is a credential, a binding between a device, an app install, and a specific Firebase project. Our migration had moved the tokens, but production now ran on a *new* Firebase project. Every single one of those 100K tokens was bound to the old one. From FCM's point of view, we were trying to send messages to someone else's users: every call failed with `messaging/mismatched-credential`, a SenderId mismatch. The token was well-formed. The credential was valid. They just belonged to different worlds.

At 17:00 UTC the daily `access-reminder` cron fired and started iterating all ~100K migrated users, sending each one a push. Each call was guaranteed to fail. Each failure was retried, because the retry logic treated every error as a hiccup that patience would cure. And all of this ran on a backend pinned to a single Cloud Run instance. The API and the queue workers lived in the same service, so the storm saturated the only instance the platform had. The mechanics matter here: queue jobs are not inbound requests, so nothing about them counted against Cloud Run's request concurrency. The starvation happened inside the runtime, where a hundred thousand doomed calls held sockets, stacked pending promises, and competed with incoming requests on the same event loop. User-facing traffic, including the OAuth callbacks that make Google login work, starved behind them.

From the outside: "latency in Cloud Run". From the inside: a denial-of-service attack executed by our most loyal client, our own scheduler, against a target with no capacity headroom, using ammunition we had migrated ourselves.

***

### The firefight

Mid-incident you do not refactor. You look for the biggest OFF switch you can reach.

Ours was the job queue. The crons ran through BullMQ, so the move was to pause the `scheduled` queue directly in Redis with `queue.pause()`. One detail here earned its place in the runbook: the paused flag lives *in Redis*, so it survives a backend restart. Deleting the repeatable job does not help on its own, because our backend re-registers its repeatables at boot. If we had "fixed" the incident by removing the job and redeploying, the next deploy would have quietly re-armed the gun. Pause first, in the state store the workers actually consult; then remove the `access-reminder` repeatable.

Second move: `max_instances` from 1 to 20, to un-starve everything that had been queueing behind the storm. Login came back. The platform recovered. The tokens, of course, were still dead, but now they were dead quietly, which is the correct way for 100K invalid credentials to be dead.

End to end, the degraded window lasted under an hour, and most of that hour was diagnosis, not fix: once we understood what we were looking at, the actual moves took minutes. And here is the anticlimax this war story owes you: in all likelihood, nobody noticed but us. The apps had just landed in the stores and no marketing campaign was live yet, so the people being starved out of Google login were, with decent probability, mostly the people fixing it. The incident cost an hour of adrenaline and taught the lesson at a discount. The next one would not have been discounted.

***

### Moral #1: post-migration state is guilty until proven valid

The migration did not lie. It copied rows and it said so. The failure was in what we let that success message imply.

There is a class of data that does not survive re-homing, no matter how faithfully you copy it: data that encodes identity or trust in an external system. Push tokens bound to a Firebase project. API keys. OAuth refresh tokens. Webhook URLs with embedded secrets. Signed URLs. Each of these is only meaningful in a context, and a migration, by definition, changes the context. Copy them perfectly and you have manufactured a perfectly-formed lie: data that passes every structural check and fails on first contact with reality.

Our 100K tokens were dead the moment they landed in the new project, and they were *going* to stay dead until each user logged in again on the new stack and minted a fresh token. The outage itself went unnoticed, but the product consequence outlived it: for every user who did not come back on their own, the push channel stayed silent. A re-engagement campaign is a strange thing to lose to a re-engagement cron. That was not a defect of the migration; it is how Firebase credentials work. The defect was treating "migration succeeded" as "migrated state is valid". Those are different claims. The first is about transfer. The second is about meaning, and only the destination environment gets a vote on meaning.

The operational rule I take away: after a migration, every piece of state that references an external system is guilty until proven valid *in the new context*. Row counts prove nothing here. The only proof is exercising the state against the world it now lives in, on a sample, before anything automated exercises it against all of it at once. Our rehearsal a month earlier had validated exactly the wrong half: it proved the transfer, and nothing in it exercised push against the new project. That is the class of trap that looks fine until the first daily cron fires.

Because that is the other half of the trap: we did not discover the dead tokens by validating. The cron discovered them for us, at production scale, all at once. A daily batch job is a validation pass you did not design, running at a time you did not pick, with a blast radius you did not choose.

***

### Moral #2: batch work must not share a blast radius with users

The second moral is about why a failing *notification* job took down *login*.

It took down login because there was nothing between them. One service, one instance, one queue of work. The bulkhead pattern exists precisely for this: partition the system so that saturation in one compartment cannot drown the others. Background and batch work, especially anything that iterates all users, belongs in its own failure domain: its own worker pool, its own scaling limits, ideally its own service. A re-engagement push is the definition of deferrable work. An OAuth callback is the definition of not. Making them queue for the same CPU is choosing, in advance, that the deferrable thing can starve the critical one.

And `max_instances = 1` deserves its own line, because it was not an oversight. The service was a from-scratch redesign, the apps had only just shipped to the stores, and with no marketing live the expected traffic was close to zero: capping a quiet platform at one instance looked like prudence. But the cap priced in *user* traffic, and the cron was not user traffic. It delivered a hundred thousand users' worth of load onto a platform sized for roughly none, because batch load does not wait for your launch calendar. With exactly one instance to saturate, any local saturation (a batch job, a slow query, a retry storm) is instantly promoted to a global outage. Horizontal headroom is not just about handling more users; it is about containing the failures you have not imagined yet.

***

### The part the retry-storm story buries

None of this is novel. The retry storm has its own entry in the [Azure Architecture Center's antipattern catalog](https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/). Google's CRE team wrote the canonical ["how to avoid a self-inflicted DDoS"](https://cloud.google.com/blog/products/gcp/how-to-avoid-a-self-inflicted-ddos-attack-cre-life-lessons) years ago. Dan Lebrero told a [browser-fleet version of the same story](https://danlebrero.com/2022/02/02/stability-pattern-steady-state-self-inflicted-ddos-distributed-denial-of-service-attack/) in 2022. There is even a recent paper, [RetryGuard](https://arxiv.org/abs/2511.23278), on preventing self-inflicted retry storms in microservices. The concept is commodity. We stepped on a very well-documented rake.

And to be fair, the guidance exists: Azure's [transient-fault best practices](https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults) open by telling you to determine whether a fault is transient at all before retrying it. But the retry-storm story itself centers a *transient* trigger. A service blips, clients pile on retries, the recovering service gets trampled by its own rescue party. The headline prescriptions follow that shape (exponential backoff, jitter, circuit breakers, retry budgets), so if the storm is what you are reading about, classification is not what you walk away with. Round the problem down to tuning, as we effectively had, and you miss our case entirely.

Our storm never had a transient phase. `messaging/mismatched-credential` is a *permanent* error. No amount of backoff cures a token that belongs to a different Firebase project; the ten-thousandth retry is exactly as doomed as the first. Retrying a permanent error is not resilience. It is a metronome for hitting yourself. And the blind retries were ours, not the platform's: the FCM SDK does not retry a mismatched credential; our job layer did, because it never read the error code. Backoff and jitter would have blunted the saturation (retries parked in Redis instead of hammering the same instance), and for genuinely transient failures they are the right tool. Against a permanent error they only smear the doom over a longer window.

The platform tells you which is which. FCM's error taxonomy distinguishes retryable conditions (server unavailable, internal errors) from terminal ones: a mismatched credential means stop, and a token no longer registered means stop *and delete the token*. The cheapest fix in this whole story is not a circuit breaker or a fancier queue: read the error code and sort failures into two buckets, the ones patience can cure and the ones patience amplifies. Backoff strategies are tuning for bucket one. Bucket two needs a bin, not a schedule.

***

### The checklist I'd run today

What I would gate the next cutover on, in the order the pain taught it:

1. **Inventory context-bound state.** Everything that encodes identity or trust in an external system: tokens, keys, webhooks, signed anything. Assume all of it is invalid in the new environment until a sample proves otherwise. A probe against a hundred tokens costs minutes; the cron's version of the same test cost an outage.
2. **Disarm the crons before they validate for you.** Pause every batch job that iterates users before cutover; re-enable them one at a time, after the state they touch is proven valid.
3. **Classify errors before retrying them.** Terminal errors drop and clean up (dead tokens get deleted, not revisited). Only transient errors earn a retry, with backoff and a budget.
4. **Give batch work its own failure domain.** Separate queue, separate workers, separate scaling pool. A job that touches every user should be physically incapable of starving login.
5. **No single-instance user-facing production, ever.** A singleton background worker can have its reasons; the service your users log in through does not. This holds especially during the pre-launch quiet window, when the cap feels prudent: "quiet" applies to your users, not to your own batch jobs.
6. **Kill-switches must survive restarts.** A pause flag that lives in Redis beats an in-process one, and beats deleting a job definition the boot sequence will happily restore.

***

The migration told us it succeeded, and it was not lying about what it measured. The tests in my last post told me the code was green, and they were not lying either. The lie, both times, lived in the gap between the report and the outcome, and both times something eventually walked into that gap at full speed. Last time it was me, typing the first real prompt into a dead program. This time it was a cron, dutifully trusting the migration's word 100,000 times in a row.

The report is not the outcome. The success message of a migration is a claim about the past (copied rows), not about the future (working state). Something will always be the first to test that claim against reality. Given the choice, be the something. It is much cheaper when it is you, on purpose, with one token, than when it is your own scheduler, at 17:00 UTC, with all of them.

***

### Methodology note

This article was written with AI assistance (Claude Code for drafting and source retrieval; manual editing throughout). The incident details, error codes, and fixes come from the internal retrospective written right after the cutover; the duration, the reasoning behind the scaling cap, and the impact assessment come from memory. Nothing narrative was invented around them.

### Sources

- Microsoft Azure Architecture Center. [Retry Storm antipattern](https://learn.microsoft.com/en-us/azure/architecture/antipatterns/retry-storm/).
- Microsoft Azure Architecture Center. [Best practices for transient fault handling](https://learn.microsoft.com/en-us/azure/architecture/best-practices/transient-faults).
- Microsoft Azure Architecture Center. [Bulkhead pattern](https://learn.microsoft.com/en-us/azure/architecture/patterns/bulkhead).
- Google Cloud Blog, CRE life lessons. [How to avoid a self-inflicted DDoS attack](https://cloud.google.com/blog/products/gcp/how-to-avoid-a-self-inflicted-ddos-attack-cre-life-lessons).
- Lebrero, D. (2022). [The self-inflicted denial-of-service (DDoS) attack](https://danlebrero.com/2022/02/02/stability-pattern-steady-state-self-inflicted-ddos-distributed-denial-of-service-attack/).
- [RetryGuard: Preventing Self-Inflicted Retry Storms in Cloud Microservices Applications](https://arxiv.org/abs/2511.23278). arXiv:2511.23278 (2025).
- Firebase documentation. [Admin SDK error handling / FCM error codes](https://firebase.google.com/docs/cloud-messaging/send-message#admin_sdk_error_reference).
