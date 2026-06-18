---
title: "The AI Said Mandatory. I Measured 23% Slower."
date: 2026-06-17
summary: "An AI reviewer told me a hash swap was mandatory and 300 to 400 percent faster. It was 23 percent slower. The lesson is not about hashing, it is about what an LLM can and cannot know about your code."
tags: ["ai", "llm", "engineering", "go", "opinion"]
draft: false
cover:
  image: "images/cover-the-ai-said-mandatory.png"
  alt: "A hand-drawn confident pointing hand casting a shadow shaped like a question mark"
  relative: false
---

Gemini told me a hash swap was mandatory. Rip out the hash I had, drop in a faster, more modern one, on a hash-heavy hot path in a service I work on. Not recommended, mandatory. The suggestion came with a number, 300 to 400 percent faster, and it was specific, complete, and ready to paste in.

I almost just did it. Then I benchmarked it, the way I usually do, and it came back 23 percent slower.

The honest reason I almost skipped it is more boring than deference, and more useful to know about myself: it was late, I was not especially focused (the kind of [tired that comes from judging decisions all day, not from writing code]({{< ref "2026-03-06-ai-didnt-reduce-my-cognitive-load-it-moved-it" >}})), and the suggestion already had the shape of a finished decision. Running a benchmark is what I normally do here without thinking about it. That evening it felt like the optional step at the end of a long day, and the path of least resistance was to take the confident, complete-looking answer and move on.

The AI was not lying and it was not hallucinating. It was doing the one thing it cannot help doing. An LLM is a semantic engine, not an execution engine. It has read everything ever written about hashing. It has never once seen what my code does when it runs. Most days those two overlap enough that you forget they are different things. This was not one of those days.

***

### The benchmark it quoted was real

The hash it told me to switch to really is one of the fastest on the planet, for large contiguous inputs. The 300 to 400 percent figure is the kind of number you see in every hash shootout, measured in gigabytes per second. The model was quoting real benchmarks. The benchmarks just describe a workload that has nothing to do with mine.

My hot path hashes short keys, a few hundred per call, most of them 15 to 40 bytes. The hash I already had walks each key's bytes in place, `b[k]`, folds them in as it goes, and allocates almost nothing. The faster hash wants a single contiguous buffer it can read end to end, so I would have to assemble each key first: one allocation per key. The benchmark made it concrete, 234 allocations on a call that used to make one. For the shortest keys, around five bytes, the two were a wash. For my actual inputs, the allocation overhead ate the entire theoretical win and then kept eating.

This is the kind of thing the model cannot see. It knew everything written about the faster hash. It did not know that my code never materializes the buffer that hash needs. The memory layout, the allocation, the exact spot where "use the faster hash" turns into an allocation that was not there before: none of that is in the text it learned from. It reasoned about my code the way a very well read critic reasons about a novel they have not read, only the reviews.

***

### Slow is the good outcome

Slow I caught in twenty minutes. The same review had a second suggestion, and that one bothered me more once I understood it.

That hot path feeds a Bloom-filter-style structure that needs two independent hash functions. The model suggested the standard trick: take one 64-bit hash and split it into a high half and a low half, call them h1 and h2. Clean. Idiomatic. One hash call instead of two. You can find it in textbooks.

It is not obviously wrong, and that is the problem. The construction I use, `h_i = h1 + i*h2`, comes from Kirsch and Mitzenmacher, and it leans on h1 and h2 being independent enough. Splitting one 64-bit hash into two halves can give you that, and for a well-mixing hash it usually does. The catch is in "usually": whether it holds comes down to that specific hash's avalanche, not a law, and the suggestion never raises it, because it cannot see which hash I use or how well it mixes. Take the bet and the filter still runs. It still returns answers. If the bet is wrong, it just carries a higher false-positive rate than the math promised, quietly, for as long as it lives. You can find out which case you are in, but only by deliberately measuring the realized false-positive rate against representative data. I went with two independent hashes instead. Not because the split is wrong, it usually isn't, but because the trade is lopsided: the safe version costs one extra hash call on a path that already makes hundreds, while a wrong bet would cost a silently degraded filter forever.

Same blind spot, quieter failure. Whether the split is safe lives in my running code, in the hash I actually use; the textbook version of the trick is all the model has. The slow suggestion announced itself the moment I ran a benchmark. This one could have passed every test I had, shipped, and quietly cost a filter the false-positive rate it was supposed to guarantee, by an amount I would never have measured, because nothing in my suite measures "the statistical guarantee you assumed you still had." Loudly wrong advice is the safe kind. You catch it. The advice that quietly degrades something and never trips an alarm is the one that costs you.

***

### "You just prompted it wrong"

This is where a certain kind of engineer says: skill issue. You prompted it badly. If you had told it "15 to 40 byte keys, allocation-sensitive hot path, double hashing that needs independence," it would have answered correctly.

Some of that is fair. I knew this was an allocation-sensitive hot path with tiny keys before I ran anything, and a model told "no heap allocations here" would probably have balked at the buffer. That constraint was mine to give, and I didn't. But notice the two different things tangled in that defense. A constraint, no allocations on this path, is something I knew and could have typed. The verdict, 23 percent slower once the allocation is paid, is not: for five-byte keys the same swap was a wash, so whether it nets out faster or slower depends on my key sizes, which is an execution fact, not a constraint. A better prompt buys a better hypothesis. Only the benchmark buys the verdict. You cannot prompt your way to a measurement you have not taken.

There is a tidier story you could tell about all this, that the real lesson is the model's confidence. It is true as far as it goes. The model was equally certain about the speedup and the split, right and wrong in the same flat voice, so how sure it sounds tells you nothing. But the confidence is the symptom. The cause is that it reasons about text while your code is busy executing, and execution is where both of these bugs lived.

***

### Sort by what it costs you to check

So you cannot lean on how sure it sounds. You need something else to sort on, and the only thing left is how much it costs you to check the claim against the execution the model cannot see. That collapses into a small discipline I now run almost by reflex.

If the claim is cheap to check, treat it as a hypothesis and check it. The hash speedup cost me one benchmark. Fine trade: let the model raise the question, then go measure the answer.

If the answer is deterministic, take the model out of the loop entirely. Some questions are not opinions, they are functions. I hit this with Postgres tuning recently: real temptation to ask the model for config values, and the right move was to port PGTune, a deterministic formula that has been beaten on across thousands of deployments, and never ask. You do not verify the model here. You delete it from the path.

If checking it is expensive or easy to skip, distrust it by default. That is the Kirsch-Mitzenmacher bucket: you can measure the realized false-positive rate, but it is no ten-minute benchmark and nothing forces you to, so the safe default is not to bet the guarantee on the model's say-so. It is also why I still trust the JVM's garbage collector and Postgres's planner without auditing them: not because they cannot be checked, but because someone else already paid the verification cost, across millions of deployments. A confident one-off suggestion has not.

Notice that two of those three buckets barely involve the model at all. One says go and measure it yourself. The other says take the model out of the loop. The discipline is less "trust but verify" and more "decide, claim by claim, whether the model belongs in the loop."

I am not arguing you should switch it off. I [put Gemini in my review loop on purpose]({{< ref "2025-10-18-from-rubber-ducks-to-gemini-ai-powered-code-reviews-in-gitlab-ci" >}}), and I still run the agents even after watching [how loudly they can go wrong]({{< ref "2026-04-05-agents-delete-good-code-heres-how-im-stopping-them" >}}). A wrong, confident, mandatory suggestion is the only reason I benchmarked that hot path at all, and the only reason I now know, with numbers, why my own design was right. The value was the question, not the answer. Let the model raise the question. Do not let it close one.

That is the bonus, though, not the rule. The rule is the thing I nearly skipped the evening I almost merged a 23 percent regression, not because the AI talked me into it, but because I was tired and it was already written. The discipline is not for the days you are sharp. Sharp-you already benchmarks. It is for the other days. Never let confident prose stand in for a measurement or a formula, least of all when you are too tired to want to.

***

*Written with help from the same kind of tool it is about. The hashing, the Bloom filter, and the numbers are real and from production; I have left out what the service does. If a claim in here is cheap for you to verify, please do.*
