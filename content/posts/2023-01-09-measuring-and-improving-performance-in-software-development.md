---
title: "Measuring and Improving Performance in Software Development"
date: 2023-01-09
summary: "How can you tell if a development team is working effectively and meeting its objectives on time? Some insights from scientific research."
tags: ["engineering", "productivity", "metrics"]
draft: false
cover:
  image: "images/cover-measuring-performance.png"
  alt: "Measuring and Improving Performance in Software Development"
  relative: false
---

_This is an English translation of an article I originally published in Italian in January 2023. Three years later, I wrote a follow-up piece exploring what has changed since then: ["Measuring Software Performance: What Changed in 3 Years?"]({{< ref "2026-01-01-measuring-software-performance-what-changed-in-3-years" >}})_

---

Performance measurement is essential for evaluating business management and quantifying the value generated for customers and stakeholders. Measurements are also used in process control as a foundation for continuous performance improvement. The strategic importance of performance measurement is simply described by Kaplan and Norton with their now-famous phrase: ***what gets measured, gets managed***.¹

For these reasons, measuring performance in software development is a constant challenge for any organization dealing with software and information systems. Unfortunately, despite decades of research on the topic, measuring the productivity of a software development team is never easy. Even the definition of developer productivity is an elusive concept.

Last summer, while studying the subject and reading **Rethinking Productivity in Software Engineering**,² I stumbled upon the excellent newsletter [Software Engineering Research](https://abinoda.substack.com/) written by [Abi Noda](https://www.linkedin.com/in/abinoda/). Each issue of the newsletter contains a summary of an article or scientific research, or references to industry best practices. Thanks to Abi's newsletter, I managed to stay focused and continue studying the topic.

Here I briefly report what I have studied so far, with references to the research suggested by Abi.

### What is developer productivity? How can it be measured?

Developer productivity should measure the value created by the software development process. Unfortunately, in our industry there is no alignment on what this really means: developers, managers, and stakeholders define productivity differently,³ and developers themselves have different views on what it means to be productive.⁴

A common myth about developer productivity is that it can be measured through a single "universal" metric, that this metric can be used to evaluate the overall work of a team or to compare the work of different teams within an organization and even across an industry. This is clearly not true: productivity is the sum of different "dimensions" of work and is strongly influenced by the context in which the work is performed. For this reason, productivity should be a multi-dimensional measure and should not be reduced to a single metric.⁵

Metrics should be chosen carefully, specifying what each one is intended to measure, but also what their limitations are when the metric is used alone or in the wrong context. When choosing a metric, it is therefore essential to be clear about what you intend to achieve from the measurement and who will need to make decisions based on the collected data.

There are several frameworks that help measure productivity, including **SPACE** (*Satisfaction and well-being, Performance, Activity, Collaboration and communication, and Efficiency and flow*)⁶ and Google's **QUANTS** (*Quality of the code, Attention from engineers, Intellectual complexity, Tempo and velocity, and Satisfaction*).⁷ These frameworks help understand the difficulty of measurement and make explicit that organizations should adopt metrics that cover all facets of productivity.

Measurement should take personal perception into account. This means measuring whether a developer feels productive and whether they perceive that a tool or process is effective.⁶ Developer satisfaction is one of the parameters that is always measured in these frameworks because, on one hand, satisfaction and productivity are positively and bidirectionally correlated,⁸ and on the other hand, dissatisfaction can cause reduced intellectual performance, difficulty concentrating, and lead to writing lower quality code.⁹

Metrics can be obtained either through surveys or by extracting data from the systems used to manage the development process.¹⁰ Survey-based measurements can provide a global view of the process through periodic data collection. Measurements collected from systems provide a continuous view of the process, although they are limited to the data managed by those systems.

### How is productivity influenced?

One way to improve productivity is to try to reduce waste.¹¹ Among the various types of waste, we find rework (the need to modify completed work because it doesn't meet specifications), the implementation of unnecessary features, or unnecessarily complex solutions.

Several studies have examined which factors affect productivity, such as:

* **Technical debt.** Research shows that nearly a quarter of developers' working hours can be wasted due to technical debt. This time is generally spent on refactoring not planned in the project plan or on the need for additional testing.¹² To address technical debt, some possible strategies are suggested: clear end-to-end project ownership, creating teams responsible for reducing technical debt, and introducing automated code compliance checks.¹³
* **Code quality.** Poor code quality is actually a type of technical debt.¹³ It deserves a separate point because, in a study conducted by Google, satisfaction with code quality had the strongest causal relationship with perceived productivity.¹⁴ One strategy to improve source code quality is to focus on code ownership.¹⁵
* **Flaky tests.** Flaky tests hinder Continuous Integration and lead to productivity loss. Developers who frequently deal with unreliable tests are also more likely to ignore potentially real test failures.¹⁶
* **Happiness.** Since personal satisfaction and productivity are strongly correlated,¹⁷ it is very important to understand what makes developers unhappy. Some of the main causes of unhappiness include being stuck on problem-solving, poor quality of produced code, and feeling inadequate for the job.¹⁸

### Conclusions

Software development productivity is a key factor in creating a successful software product or service in a sustainable way for a company. As we have seen, there are different approaches to measuring productivity and many factors that influence it. To date, there is still no universally accepted measurement method, and each organization should probably focus on the metrics that best fit their own context.

To learn more about the topic, I leave you with the bibliography references and suggest you subscribe to [Abi Noda's newsletter](https://abinoda.substack.com/), where you can find many tips and best practices to increase your development team's productivity.

I also leave you the link to [the company where I currently work](https://iungo.com/lavora-con-noi), in case you are interested in working at a company that constantly tries to put the above into practice or in writing a thesis on this topic.

### References

\[1\] R. S. Kaplan and D. P. Norton, 'The Balanced Scorecard — Measures that Drive Performance', Harvard Business Review, Jan. 01, 1992 \[Online\]. Available: [https://hbr.org/1992/01/the-balanced-scorecard-measures-that-drive-performance-2](https://hbr.org/1992/01/the-balanced-scorecard-measures-that-drive-performance-2). \[Accessed: Jan. 10, 2023\]

\[2\] C. Sadowski and T. Zimmermann, Eds., Rethinking Productivity in Software Engineering. Berkeley, CA: Apress, 2019 \[Online\]. Available: [https://link.springer.com/10.1007/978-1-4842-4221-6](https://link.springer.com/10.1007/978-1-4842-4221-6). \[Accessed: Jan. 10, 2023\]

\[3\] M.-A. Storey, B. Houck, and T. Zimmermann, 'How Developers and Managers Define and Trade Productivity for Quality', 2021, doi: 10.48550/ARXIV.2111.04302. \[Online\]. Available: [https://arxiv.org/abs/2111.04302](https://arxiv.org/abs/2111.04302). \[Accessed: Jan. 10, 2023\]

\[4\] A. N. Meyer, G. C. Murphy, T. Fritz, and T. Zimmermann, 'Developers' Diverging Perceptions of Productivity', in Rethinking Productivity in Software Engineering, C. Sadowski and T. Zimmermann, Eds. Berkeley, CA: Apress, 2019, pp. 137–146 \[Online\]. Available: [https://link.springer.com/10.1007/978-1-4842-4221-6\_12](https://link.springer.com/10.1007/978-1-4842-4221-6_12). \[Accessed: Jan. 10, 2023\]

\[5\] C. Jaspan, 'No Single Metric Captures Productivity', in Rethinking Productivity in Software Engineering, C. Sadowski and T. Zimmermann, Eds. Berkeley, CA: Apress, 2019 \[Online\]. Available: [https://link.springer.com/book/10.1007/978-1-4842-4221-6](https://link.springer.com/book/10.1007/978-1-4842-4221-6). \[Accessed: Jan. 10, 2023\]

\[6\] N. Forsgren, M.-A. Storey, C. Maddila, T. Zimmermann, B. Houck, and J. Butler, 'The SPACE of Developer Productivity: There's more to it than you think.', Queue, vol. 19, no. 1, pp. 20–48, Feb. 2021, doi: 10.1145/3454122.3454124. \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3454122.3454124](https://dl.acm.org/doi/10.1145/3454122.3454124). \[Accessed: Jan. 10, 2023\]

\[7\] C. Jaspen, 'Measuring Engineering Productivity', in Software Engineering at Google, R. Macnamara, Ed. O'Reilly Media, Inc., 2020 \[Online\]. Available: [https://abseil.io/resources/swe-book/html/ch07.html](https://abseil.io/resources/swe-book/html/ch07.html). \[Accessed: Jan. 10, 2023\]

\[8\] M.-A. Storey, T. Zimmermann, C. Bird, J. Czerwonka, B. Murphy, and E. Kalliamvakou, 'Towards a Theory of Software Developer Job Satisfaction and Perceived Productivity', IEEE Trans. Software Eng., vol. 47, no. 10, pp. 2125–2142, Oct. 2021, doi: 10.1109/TSE.2019.2944354. \[Online\]. Available: [https://ieeexplore.ieee.org/document/8851296/](https://ieeexplore.ieee.org/document/8851296/). \[Accessed: Jan. 10, 2023\]

\[9\] D. Graziotin, F. Fagerholm, X. Wang, and P. Abrahamsson, 'What happens when software developers are (un)happy', Journal of Systems and Software, vol. 140, pp. 32–47, Jun. 2018, doi: 10.1016/j.jss.2018.02.041. \[Online\]. Available: [https://linkinghub.elsevier.com/retrieve/pii/S0164121218300323](https://linkinghub.elsevier.com/retrieve/pii/S0164121218300323). \[Accessed: Jan. 10, 2023\]

\[10\] N. Forsgren and M. Kersten, 'DevOps Metrics: Your biggest mistake might be collecting the wrong data.', Queue, vol. 15, no. 6, pp. 19–34, Dec. 2017, doi: 10.1145/3178368.3182626. \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3178368.3182626](https://dl.acm.org/doi/10.1145/3178368.3182626). \[Accessed: Jan. 10, 2023\]

\[11\] T. Sedano, P. Ralph, and C. Peraire, 'Software Development Waste', in 2017 IEEE/ACM 39th International Conference on Software Engineering (ICSE), Buenos Aires, May 2017, pp. 130–140, doi: 10.1109/ICSE.2017.20 \[Online\]. Available: [http://ieeexplore.ieee.org/document/7985656/](http://ieeexplore.ieee.org/document/7985656/). \[Accessed: Jan. 10, 2023\]

\[12\] T. Besker, A. Martini, and J. Bosch, 'Technical debt cripples software developer productivity: a longitudinal study on developers' daily software development work', in Proceedings of the 2018 International Conference on Technical Debt, Gothenburg Sweden, May 2018, pp. 105–114, doi: 10.1145/3194164.3194178 \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3194164.3194178](https://dl.acm.org/doi/10.1145/3194164.3194178). \[Accessed: Jan. 10, 2023\]

\[13\] T. Cochran and C. Nygard, 'Bottleneck \#01: Tech Debt', martinfowler.com, Mar. 09, 2022\. \[Online\]. Available: [https://martinfowler.com/articles/bottlenecks-of-scaleups/01-tech-debt.html](https://martinfowler.com/articles/bottlenecks-of-scaleups/01-tech-debt.html). \[Accessed: Jan. 10, 2023\]

\[14\] L. Cheng et al., 'What improves developer productivity at google? code quality', in Proceedings of the 30th ACM Joint European Software Engineering Conference and Symposium on the Foundations of Software Engineering, Singapore Singapore, Nov. 2022, pp. 1302–1313, doi: 10.1145/3540250.3558940 \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3540250.3558940](https://dl.acm.org/doi/10.1145/3540250.3558940). \[Accessed: Jan. 10, 2023\]

\[15\] M. Greiler, K. Herzig, and J. Czerwonka, 'Code Ownership and Software Quality: A Replication Study', in 2015 IEEE/ACM 12th Working Conference on Mining Software Repositories, Florence, Italy, May 2015, pp. 2–12, doi: 10.1109/MSR.2015.8 \[Online\]. Available: [http://ieeexplore.ieee.org/document/7180062/](http://ieeexplore.ieee.org/document/7180062/). \[Accessed: Jan. 10, 2023\]

\[16\] O. Parry, G. M. Kapfhammer, M. Hilton, and P. McMinn, 'Surveying the developer experience of flaky tests', in Proceedings of the 44th International Conference on Software Engineering: Software Engineering in Practice, Pittsburgh Pennsylvania, May 2022, pp. 253–262, doi: 10.1145/3510457.3513037 \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3510457.3513037](https://dl.acm.org/doi/10.1145/3510457.3513037). \[Accessed: Jan. 10, 2023\]

\[17\] T. A. Judge, C. J. Thoresen, J. E. Bono, and G. K. Patton, 'The job satisfaction–job performance relationship: A qualitative and quantitative review.', Psychological Bulletin, vol. 127, no. 3, pp. 376–407, 2001, doi: 10.1037/0033–2909.127.3.376. \[Online\]. Available: [http://doi.apa.org/getdoi.cfm?doi=10.1037/0033-2909.127.3.376](http://doi.apa.org/getdoi.cfm?doi=10.1037%2F0033-2909.127.3.376). \[Accessed: Jan. 10, 2023\]

\[18\] D. Graziotin, F. Fagerholm, X. Wang, and P. Abrahamsson, 'On the Unhappiness of Software Developers', 2017, doi: 10.48550/ARXIV.1703.04993. \[Online\]. Available: [https://arxiv.org/abs/1703.04993](https://arxiv.org/abs/1703.04993). \[Accessed: Jan. 10, 2023\]
