---
title: "Misurazione e miglioramento delle performance nello sviluppo software"
date: 2023-01-09
summary: "Come si può sapere se un team di sviluppo sta lavorando in modo efficace e se sta raggiungendo i suoi obiettivi in modo tempestivo? Qualche spunto dalla ricerca scientifica."
tags: ["engineering", "productivity", "metrics", "italian"]
draft: false
cover:
  image: "images/cover-measuring-performance.png"
  alt: "Misurazione e miglioramento delle performance nello sviluppo software"
  relative: false
---

La misurazione delle performance è indispensabile per la valutazione della gestione aziendale e per la quantificazione del valore generato verso clienti e stakeholder. Le misurazioni vengono utilizzate anche nel controllo dei processi, come base per il miglioramento costante delle prestazioni. L’importanza strategica della misurazione delle performance viene descritta in maniera semplice da Kaplan e Norton con la frase ormai celebre ***ciò che viene misurato, viene fatto***.¹

Per queste ragioni, misurare le performance nello sviluppo software è una sfida costante per qualsiasi organizzazione che si occupi di software e sistemi informatici. Purtroppo, nonostante l’argomento sia stato ampiamente sviscerato in decenni di ricerca, misurare la produttività di un team di sviluppo software non è mai facile. Persino la definizione di produttività degli sviluppatori è un concetto sfuggente.

Quest’estate, mentre studiavo l’argomento ed ero impegnato nella lettura di **Rethinking Productivity in Software Engineering**,² mi sono imbattuto per caso nell’ottima newsletter [Software Engineering Research](https://abinoda.substack.com/) scritta da [Abi Noda](https://www.linkedin.com/in/abinoda/). Ogni numero della newsletter contiene un riassunto di un articolo o di una ricerca scientifica, o qualche riferimento a best practice del settore. Grazie alla newsletter di Abi sono riuscito a non perdere il focus per continuare a studiare l’argomento.

Riporto qui brevemente quanto ho studiato finora, con i riferimenti alle ricerche suggerite da Abi.

### **Cos’è la produttività degli sviluppatori? Come è possibile misurarla?**

La produttività degli sviluppatori dovrebbe misurare il valore creato dal processo di sviluppo software. Purtroppo nel nostro settore non si è allineati su cosa questo significhi veramente: gli sviluppatori, i manager e gli stakeholder definiscono la produttività in modo diverso³ e gli sviluppatori hanno punti di vista diversi tra loro su cosa significhi essere produttivi.⁴

Un mito comune sulla produttività degli sviluppatori è che possa essere misurata attraverso una singola metrica “universale”, che questa metrica possa essere utilizzata per valutare il lavoro complessivo di un team o per mettere a confronto il lavoro di diversi team di un’organizzazione e persino di un settore industriale. Chiaramente questo non è vero, la produttività è la somma di diverse “dimensioni” del lavoro ed è fortemente influenzata dal contesto in cui il lavoro viene svolto. Per questo motivo la produttività dovrebbe essere una misura multi-dimensionale e non dovrebbe essere ridotta a una sola metrica.⁵

Le metriche andrebbero scelte con cura, evidenziando ciò che che si intende misurare con ognuna di essa, ma anche quali sono i loro limiti se quando la metrica viene usata da sola o in un contesto sbagliato. Quando si sceglie una metrica, è quindi fondamentale aver chiaro cosa si intende ottenere dalla misurazione e chi dovrà prendere le decisioni in base ai dati raccolti.

Ci sono diversi framework che aiutano a misurare la produttività, tra cui **SPACE** (*Satisfaction and well-being, Performance, Activity, Collaboration and communication, and Efficiency and flow*)⁶ e **QUANTS** di Google (*Quality of the code, Attention from engineers, Intellectual complexity, Tempo and velocity, and Satisfaction*).⁷ Questi framework aiutano a comprendere la difficoltà della misurazione e rendono esplicito che le organizzazioni dovrebbero adottare metriche che coprono tutte le sfaccettature della produttività.

La misurazione dovrebbe tenere conto della percezione personale. Ciò significa misurare se uno sviluppatore si sente produttivo e se percepisce che uno strumento utilizzato o un processo sia efficace.⁶ La soddisfazione degli sviluppatori è uno dei parametri che viene sempre misurato in questi framework poiché da un lato soddisfazione e produttività sono correlati positivamente e bidirezionalmente⁸ e dall’altro l’insoddisfazione può causare minori prestazioni intellettuali, difficoltà di concentrazione e portare alla scrittura di codice di minore qualità.⁹

Le metriche possono essere ricavate sia utilizzando sondaggi che estraendo dati dai sistemi utilizzati per gestire il processo di sviluppo.¹⁰ Le misurazioni basate su sondaggi possono fornire una visione globale del processo attraverso la raccolta di dati periodica. Le misure raccolte dai sistemi forniscono una visione continua del processo, sebbene siano limitati ai dati che vengono gestiti dagli stessi.

### **Come viene influenzata la produttività?**

Uno dei modi per migliorare la produttività è cercare di ridurre gli sprechi.¹¹ Tra i vari tipi di spreco troviamo il rework, cioè la necessità di modificare un lavoro terminato poiché non rispetta le specifiche, l’implementazione di funzionalità non utili o le soluzioni inutilmente complesse.

Diversi studi hanno esaminato quali fattori incidono sulla produttività, come per esempio:

* **Debito tecnico**. Dalle ricerche emerge che può essere sprecato quasi un quarto dell’orario di lavoro degli sviluppatori a causa del debito tecnico. Questo tempo viene generalmente impiegato per eseguire del refactoring non previsto nel piano di progetto o per la necessità di test aggiuntivi.¹² Per affrontare il debito tecnico, vengono suggerite alcune possibili strategie: la chiara ownership end-to-end del progetto, la creazione di team responsabili della riduzione del debito tecnologico, l’introduzione di controlli automatici di conformità del codice.¹³
* **Qualità del codice.** La scarsa qualità del codice è in realtà un tipo di debito tecnico.¹³ Merita un punto a parte perché, in uno studio condotto da Google, la soddisfazione per la qualità del codice ha avuto la relazione causale più forte con la produttività percepita.¹⁴ Una delle strategie per migliorare la qualità del codice sorgente è concentrarsi sulla ownership dello stesso.¹⁵
* **Test instabili**. I test instabili ostacolano la Continuous Integration e portano a una perdita di produttività. Gli sviluppatori che hanno a che fare con test inaffidabili frequentemente hanno anche maggiori probabilità di ignorare potenziali veri e propri fallimenti dei test.¹⁶
* **Felicità.** Poiché la soddisfazione personale e la produttività sono fortemente correlate,¹⁷ è molto importante capire cosa rende infelici gli sviluppatori. Alcune delle principali cause di infelicità includono l’essere bloccati nella risoluzione dei problemi, la scarsa qualità del codice prodotto e il sentirsi inadeguati al lavoro.¹⁸

### **Conclusioni**

La produttività dello sviluppo software è un fattore chiave nella creazione di un prodotto o servizio software di successo in maniera sostenibile per un’azienda. Come abbiamo visto ci sono diversi approcci per la misurazione della produttività e molti fattori che influiscono su di essa. Ad oggi non c’è ancora un metodo di misurazione universalmente accettato, e probabilmente ogni organizzazione dovrebbe concentrarsi sulle metriche che si adattano meglio al proprio contesto.

Per approfondire l’argomento vi lascio i riferimenti alla bibliografia e vi suggerisco di iscrivervi alla [newsletter](https://abinoda.substack.com/) di Abi Noda, dove potrete trovare molti consigli e best practice per aumentare la produttività del vostro team di sviluppo.

Vi lascio anche il link al [sito dell’azienda in cui lavoro attualmente](https://iungo.com/lavora-con-noi), nel caso siate interessati a lavorare in un’azienda che cerca costantemente di mettere in pratica quanto appena visto o a scrivere una tesi di laurea su questo argomento.

### **Riferimenti**

\[1\] R. S. Kaplan and D. P. Norton, ‘The Balanced Scorecard — Measures that Drive Performance’, Harvard Business Review, Jan. 01, 1992 \[Online\]. Available: [https://hbr.org/1992/01/the-balanced-scorecard-measures-that-drive-performance-2](https://hbr.org/1992/01/the-balanced-scorecard-measures-that-drive-performance-2). \[Accessed: Jan. 10, 2023\]

\[2\] C. Sadowski and T. Zimmermann, Eds., Rethinking Productivity in Software Engineering. Berkeley, CA: Apress, 2019 \[Online\]. Available: [https://link.springer.com/10.1007/978-1-4842-4221-6](https://link.springer.com/10.1007/978-1-4842-4221-6). \[Accessed: Jan. 10, 2023\]

\[3\] M.-A. Storey, B. Houck, and T. Zimmermann, ‘How Developers and Managers Define and Trade Productivity for Quality’, 2021, doi: 10.48550/ARXIV.2111.04302. \[Online\]. Available: [https://arxiv.org/abs/2111.04302](https://arxiv.org/abs/2111.04302). \[Accessed: Jan. 10, 2023\]

\[4\] A. N. Meyer, G. C. Murphy, T. Fritz, and T. Zimmermann, ‘Developers’ Diverging Perceptions of Productivity’, in Rethinking Productivity in Software Engineering, C. Sadowski and T. Zimmermann, Eds. Berkeley, CA: Apress, 2019, pp. 137–146 \[Online\]. Available: [https://link.springer.com/10.1007/978-1-4842-4221-6\_12](https://link.springer.com/10.1007/978-1-4842-4221-6_12). \[Accessed: Jan. 10, 2023\]

\[5\] C. Jaspan, ‘No Single Metric Captures Productivity’, in Rethinking Productivity in Software Engineering, C. Sadowski and T. Zimmermann, Eds. Berkeley, CA: Apress, 2019 \[Online\]. Available: [https://link.springer.com/book/10.1007/978-1-4842-4221-6](https://link.springer.com/book/10.1007/978-1-4842-4221-6). \[Accessed: Jan. 10, 2023\]

\[6\] N. Forsgren, M.-A. Storey, C. Maddila, T. Zimmermann, B. Houck, and J. Butler, ‘The SPACE of Developer Productivity: There’s more to it than you think.’, Queue, vol. 19, no. 1, pp. 20–48, Feb. 2021, doi: 10.1145/3454122.3454124. \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3454122.3454124](https://dl.acm.org/doi/10.1145/3454122.3454124). \[Accessed: Jan. 10, 2023\]

\[7\] C. Jaspen, ‘Measuring Engineering Productivity’, in Software Engineering at Google, R. Macnamara, Ed. O’Reilly Media, Inc., 2020 \[Online\]. Available: [https://abseil.io/resources/swe-book/html/ch07.html](https://abseil.io/resources/swe-book/html/ch07.html). \[Accessed: Jan. 10, 2023\]

\[8\] M.-A. Storey, T. Zimmermann, C. Bird, J. Czerwonka, B. Murphy, and E. Kalliamvakou, ‘Towards a Theory of Software Developer Job Satisfaction and Perceived Productivity’, IIEEE Trans. Software Eng., vol. 47, no. 10, pp. 2125–2142, Oct. 2021, doi: 10.1109/TSE.2019.2944354. \[Online\]. Available: [https://ieeexplore.ieee.org/document/8851296/](https://ieeexplore.ieee.org/document/8851296/). \[Accessed: Jan. 10, 2023\]

\[9\] D. Graziotin, F. Fagerholm, X. Wang, and P. Abrahamsson, ‘What happens when software developers are (un)happy’, Journal of Systems and Software, vol. 140, pp. 32–47, Jun. 2018, doi: 10.1016/j.jss.2018.02.041. \[Online\]. Available: [https://linkinghub.elsevier.com/retrieve/pii/S0164121218300323](https://linkinghub.elsevier.com/retrieve/pii/S0164121218300323). \[Accessed: Jan. 10, 2023\]

\[10\] N. Forsgren and M. Kersten, ‘DevOps Metrics: Your biggest mistake might be collecting the wrong data.’, Queue, vol. 15, no. 6, pp. 19–34, Dec. 2017, doi: 10.1145/3178368.3182626. \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3178368.3182626](https://dl.acm.org/doi/10.1145/3178368.3182626). \[Accessed: Jan. 10, 2023\]

\[11\] T. Sedano, P. Ralph, and C. Peraire, ‘Software Development Waste’, in 2017 IEEE/ACM 39th International Conference on Software Engineering (ICSE), Buenos Aires, May 2017, pp. 130–140, doi: 10.1109/ICSE.2017.20 \[Online\]. Available: [http://ieeexplore.ieee.org/document/7985656/](http://ieeexplore.ieee.org/document/7985656/). \[Accessed: Jan. 10, 2023\]

\[12\] T. Besker, A. Martini, and J. Bosch, ‘Technical debt cripples software developer productivity: a longitudinal study on developers’ daily software development work’, in Proceedings of the 2018 International Conference on Technical Debt, Gothenburg Sweden, May 2018, pp. 105–114, doi: 10.1145/3194164.3194178 \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3194164.3194178](https://dl.acm.org/doi/10.1145/3194164.3194178). \[Accessed: Jan. 10, 2023\]

\[13\] T. Cochran and C. Nygard, ‘Bottleneck \#01: Tech Debt’, martinfowler.com, Mar. 09, 2022\. \[Online\]. Available: [https://martinfowler.com/articles/bottlenecks-of-scaleups/01-tech-debt.html](https://martinfowler.com/articles/bottlenecks-of-scaleups/01-tech-debt.html). \[Accessed: Jan. 10, 2023\]

\[14\] L. Cheng et al., ‘What improves developer productivity at google? code quality’, in Proceedings of the 30th ACM Joint European Software Engineering Conference and Symposium on the Foundations of Software Engineering, Singapore Singapore, Nov. 2022, pp. 1302–1313, doi: 10.1145/3540250.3558940 \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3540250.3558940](https://dl.acm.org/doi/10.1145/3540250.3558940). \[Accessed: Jan. 10, 2023\]

\[15\] M. Greiler, K. Herzig, and J. Czerwonka, ‘Code Ownership and Software Quality: A Replication Study’, in 2015 IEEE/ACM 12th Working Conference on Mining Software Repositories, Florence, Italy, May 2015, pp. 2–12, doi: 10.1109/MSR.2015.8 \[Online\]. Available: [http://ieeexplore.ieee.org/document/7180062/](http://ieeexplore.ieee.org/document/7180062/). \[Accessed: Jan. 10, 2023\]

\[16\] O. Parry, G. M. Kapfhammer, M. Hilton, and P. McMinn, ‘Surveying the developer experience of flaky tests’, in Proceedings of the 44th International Conference on Software Engineering: Software Engineering in Practice, Pittsburgh Pennsylvania, May 2022, pp. 253–262, doi: 10.1145/3510457.3513037 \[Online\]. Available: [https://dl.acm.org/doi/10.1145/3510457.3513037](https://dl.acm.org/doi/10.1145/3510457.3513037). \[Accessed: Jan. 10, 2023\]

\[17\] T. A. Judge, C. J. Thoresen, J. E. Bono, and G. K. Patton, ‘The job satisfaction–job performance relationship: A qualitative and quantitative review.’, Psychological Bulletin, vol. 127, no. 3, pp. 376–407, 2001, doi: 10.1037/0033–2909.127.3.376. \[Online\]. Available: [http://doi.apa.org/getdoi.cfm?doi=10.1037/0033-2909.127.3.376](http://doi.apa.org/getdoi.cfm?doi=10.1037%2F0033-2909.127.3.376). \[Accessed: Jan. 10, 2023\]

\[18\] D. Graziotin, F. Fagerholm, X. Wang, and P. Abrahamsson, ‘On the Unhappiness of Software Developers’, 2017, doi: 10.48550/ARXIV.1703.04993. \[Online\]. Available: [https://arxiv.org/abs/1703.04993](https://arxiv.org/abs/1703.04993). \[Accessed: Jan. 10, 2023\]
