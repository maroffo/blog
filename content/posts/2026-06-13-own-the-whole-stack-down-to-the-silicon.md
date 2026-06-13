---
title: "Own the Whole Stack, Down to the Silicon"
date: 2026-06-13
summary: "A US export letter switched off two frontier models overnight. For anyone building AI in Europe, that was a fire drill, and we should not waste it."
tags: ["ai", "llm", "security", "europe", "sovereignty"]
draft: false
cover:
  image: "images/cover-own-the-whole-stack.png"
  alt: "Own the Whole Stack, Down to the Silicon"
  relative: false
---

On the evening of June 12, the US government sent Anthropic a letter. By the time most of Europe had read about it, Fable 5 and Mythos 5 were already gone.

The directive cited national security and ordered Anthropic to cut off both models for every foreign national, inside the United States and out, its own employees included. Anthropic complied within hours. It also said, in plain language, that it thinks the call was a mistake.

Here is the detail that makes it real. The "jailbreak" the government is worried about, by Anthropic's own account, comes down to asking the model to read a specific codebase and fix the flaws it finds. That is not an exotic weapon. It is what defenders do every day, and the same capability ships in other public models, GPT-5.5 among them.

I work on AI security, so I read this twice.

***

### Two ways to read one letter

The first reading is professional. There is no such thing as perfect jailbreak resistance, not for Anthropic and not for anyone else. You cannot prove a model will never be talked into something it should refuse, and anyone who tells you otherwise is selling something. The serious response is the same as it is for networks: defense in depth. Narrow what a bypass can reach, make it expensive to build, watch the traffic, keep the logs that let you reconstruct an attack, and shut real ones down fast. On that reading, recalling a model used by hundreds of millions of people over one narrow, non-universal bypass is hard to justify on the technical facts. That is more or less Anthropic's position, and I find it convincing.

But the security argument is not why I have been distracted since the news broke. The second reading is.

For those of us building in Europe, the jailbreak debate is almost a luxury. We were watching something simpler and more uncomfortable: one government, with one letter, switching off two of the most capable tools on the planet overnight, with no warning and no vote for anyone outside its borders. The jailbreak is the pretext. The dependency is the lesson.

***

### Three problems I cannot put down

I spent this morning talking it through with Mauro Medda, who founded HikmaAI, where I work. Local, decentralized inference is something he has pushed for long before any of this, so the directive landed in the middle of a conversation we keep having anyway. Three problems came out of it, and I have not managed to set any of them down since.

**The first is timing.** American companies get the most capable models first, sometimes months before the rest of us. In a market that moves this fast, a few months of better tools is not a rounding error. It is a real lead, and it compounds the whole time. We are not starting level and slipping behind. We are starting behind.

**The second is the kill switch.** Mauro put it more bluntly than I would have: cut the access, and you can send a modern company back to the stone age in an afternoon. He is not exaggerating by much. Capabilities that took years to build into a product, or into the public services and infrastructure a country runs on, can be turned off by a decision made somewhere you have no say. Yesterday that stopped being a thought experiment. We watched it happen to Anthropic's own customers, and one of them was us. In the first days of June, ENISA, the European Union's own cybersecurity agency, became the first EU institution allowed into Anthropic's Project Glasswing, using Mythos to hunt zero-day flaws in critical infrastructure. On June 12 that access went dark with everyone else's. Europe was defending its own networks with a switch that sits in Washington.

**The third one caught me off guard, because I had quietly underestimated it.** Say Europe gets serious. Say we build our own data and train our own models. They would still run on chips designed in the United States, mostly by Nvidia. Nvidia sells to us today, but a sale is just a tap that happens to be open. A policy shift in Washington could narrow it, or move American buyers to the front of the line. That is not speculation either. There is already a provision moving through Congress, the GAIN AI Act, that the Senate passed inside this year's defense bill, and it would give American buyers a right of first refusal on the best chips before any foreign order ships. Not law yet, but the intent is on the record. So even a fully European model would sit on hardware we neither make nor control the queue for.

Put the three together and the conclusion is uncomfortable but simple. Owning the data is not enough, and neither is renting the models or self-hosting someone else's open weights. If we are serious about this, we own the whole stack, down to the silicon.

I know how that sounds. A right of first refusal on chips is protectionism when Washington does it, and somehow industrial strategy when I want Europe to do the same. Fair enough. The difference I actually care about is not who holds the switch, it is whether it sits on my desk or on someone else's.

***

### The part that actually gives me hope

I want to be careful here, because "European tech sovereignty" is a phrase that has launched a thousand press releases and very little working software. So let me stay concrete.

At AI Week in Milan on May 19, HikmaAI shared a stage with Andrea Pili and the team at Xference. I have skin in this, so discount what follows accordingly. But the talk was not a vision deck. It was about something you can point at: sovereign and secure inference, built on products from Italian companies.

Those two words only work together. The sovereign half is private, local inference on European infrastructure, the kind where your data never leaves your perimeter, GDPR and AI Act compliant because that is how it was built, not because a lawyer bolted it on at the end. That part is Xference. The secure half is the one I work on: bringing a model in-house only helps if you can also defend it, and the Fable case is the cleanest argument I have for why. Owning a model is worth very little if you cannot trust how it behaves under pressure. Sovereign and insecure is just a more expensive way to get breached.

That covers two layers of the stack. The third, the silicon, is the one everyone waves away as hopeless. I am not so sure.

The hardware layer is not a closed door for Europe. It is a door we keep pretending is locked. ARM, the architecture behind most of the world's efficient chips, was born in Cambridge (yes, post-Brexit Britain) and is still designed there. It is owned by SoftBank now, and that caveat is real, so I will not call it European and have someone correct me in the comments. But the design knowledge, and the people, are here. Apple's M-series runs on that same architecture, and it has already shown you can put serious AI workloads, capable open models included, on a laptop instead of a hall full of Nvidia parts. Apple is American, so that proves the architecture, not European independence; the architecture is the part that was born here. The architecture is not the only card, either. Axelera AI, out of Eindhoven, designs AI inference chips on a RISC-V base, part-funded by an EU program named, without irony, Digital Autonomy with RISC-V for Europe. The sovereignty case is starting to get made in silicon, not just in slides. And the machines that print the most advanced chips on Earth, Nvidia's very much included, come from one company: ASML, in the Netherlands. Nobody makes a leading-edge chip without them.

None of that is a finished alternative. ARM answers to Tokyo, the leading fabs are in Taiwan, and a laptop is not a training cluster. But the pieces are sitting right there, and we keep behaving as if they are not.

***

### What this is going to cost

I am not going to pretend the scale gap is small. Mistral, our most credible frontier lab, has raised a few billion dollars across its whole life. OpenAI and Anthropic are each valued near a trillion, and Anthropic's single funding round this May was bigger than everything Mistral has ever raised. European AI gets a small slice of global investment, and too many of our best researchers still board planes for California. Those are the real numbers, and they are not flattering.

Some of that gap is self-inflicted, and it would be dishonest to skip it. The same AI Act that lets Xference say "compliant by design" is also, fairly or not, blamed for slowing European builders down. Both can be true at once. Sovereignty you regulate yourself out of ever reaching is not sovereignty either.

Matteo Flora made the sharper version of this point, and it changed how I read the whole episode. What Washington used on June 12 was not an AI law, it was an export control, the same instrument the US once aimed at cryptography. A written rule you can read, predict, and take to a judge. A switch flipped at 5:21 in the afternoon you cannot. The freedom of a tech ecosystem is not measured by how many rules it carries, but by whether the power over it is visible and contestable or invisible and absolute. By that test the AI Act, slow and public and easy to resent, looks less like the problem and more like the only kind of power you ever get to argue with.

So I am not selling optimism, and the economics are not on my side either. For most companies today, renting the best American model is the rational call: cheaper and faster and sitting right there behind an API. I am not arguing about that default. I am arguing about the floor, the handful of capabilities you cannot afford to have switched off from somewhere you do not get to vote. The inference layer is moving, and moving fast, and the work HikmaAI and Xference showed in Milan is a small, concrete piece of that. The chips are the long game, and that one is not a startup's job to solve. It is an industrial choice, the kind only governments and very patient capital can make, and Europe has spent a decade not quite making it.

The money was even there. NextGenerationEU was the largest recovery program Europe has aimed at itself in generations, and Italy's share of it, the PNRR, was the biggest slice of the lot. If we had found the nerve to put even half of that into technological infrastructure and research, we might be a little less vulnerable today. Instead, at least in Italy, we built roundabouts.

What changed yesterday is that the cost of not deciding got a face. For years, "strategic dependency" was a phrase for panel discussions. On June 12 it became a letter, and an afternoon, and a product that worked in the morning and did not by dinner.

People far closer to this than I am, Mistral's CEO among them, keep saying the window to fix this is short, measured in a few years and not decades. I think they are right, and the honest move is to act like we believe them.

There are two ways to pay for this. One is now, in money and effort and decisions nobody enjoys making. The other is later, in a letter we never got the chance to read.

***

### Sources and further reading

1. Anthropic, ["Statement on the US government directive to suspend access to Fable 5 and Mythos 5"](https://www.anthropic.com/news/fable-mythos-access) - June 12, 2026
2. Fortune, ["Anthropic disables Fable and Mythos AI models following U.S. government export ban"](https://fortune.com/2026/06/13/anthropic-disables-fable-mythos-export-controls-national-security-threat/) - June 13, 2026
3. AI Magazine, ["What is the GAIN AI Act and Why Does Nvidia Oppose it?"](https://aimagazine.com/news/what-is-the-gain-ai-act-and-why-does-nvidia-oppose-it), and the [US Senate Banking Committee release](https://www.banking.senate.gov/newsroom/minority/banks-warren-cotton-schumer-mccormick-coons-introduce-landmark-bipartisan-gain-ai-act-to-maintain-us-position-as-worlds-leader-in-critical-artificial-intelligence-chips) on the GAIN AI Act
4. ["Xference launches European private AI infrastructure from Aruba data centres"](https://www.intelligentcio.com/eu/2026/04/28/xference-launches-european-private-ai-infrastructure-from-aruba-data-centres/) - Intelligent CIO Europe, April 2026
5. ["Mistral is rumored to be raising €3B at €20B valuation"](https://techcrunch.com/2026/06/12/mistral-is-rumored-to-be-raising-e3b-at-e20-valuation/) - TechCrunch, June 2026
6. ARM history and SoftBank ownership, and ASML's EUV lithography monopoly - public filings and reporting
7. Matteo Flora, ["MITHOS BLOCCATO: 17.21 è l'ora in cui gli USA hanno bloccato l'Intelligenza Artificiale"](https://mgpf.it/2026/06/13/mithos-bloccato.html) - mgpf.it, June 13, 2026
8. ["Anthropic scales Claude Mythos to critical infrastructure in 15+ countries"](https://techcrunch.com/2026/06/02/anthropic-scales-claude-mythos-to-critical-infrastructure-in-15-countries/) - TechCrunch, June 2026, and ["Anthropic to give the EU's cybersecurity agency access to Mythos"](https://www.bloomberg.com/news/articles/2026-06-01/anthropic-to-give-eu-s-cybersecurity-agency-access-to-mythos) - Bloomberg, June 2026
9. HikmaAI - [hikmaai.io](https://hikmaai.io)
10. ["Axelera AI launches inferencing chiplet, supported by funding from the EU's RISC-V project"](https://www.datacenterdynamics.com/en/news/axelera-ai-launches-inferencing-chiplet-supported-by-funding-from-eus-risc-v-project/) - Data Center Dynamics, March 2025

***

_**Methodology note:** This one started as a long chat with Claude about a LinkedIn post and turned into something I wanted more room for. I wrote it with AI assistance (Claude Code), checked every factual claim against current sources (the funding figures and the GAIN AI Act status both moved while I was writing), and ran the prose through my own humanizer pipeline to strip the AI tells. The opinions are mine, and so is the call to quote Mauro by name. If you catch an AI-ism I missed, I owe you a coffee._
