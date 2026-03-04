---
title: "DeepSeek tra trasparenza e censura"
date: 2025-02-01
summary: "Un test sui diritti umani in Cina"
tags: ["ai", "ethics", "italian"]
draft: false
cover:
  image: "images/cover-deepseek-censura.png"
  alt: "DeepSeek tra trasparenza e censura"
  relative: false
---

## Introduzione

L’intelligenza artificiale (IA) sta cambiando il modo in cui accediamo all’informazione. In questo contesto, DeepSeek ha catturato l’attenzione del settore tecnologico per le sue capacità di ragionamento e per l’efficienza economica del suo sviluppo, con costi di training pari a circa 1/20 rispetto ai competitor.

Tuttavia, l’origine cinese di DeepSeek solleva interrogativi significativi sulla sua indipendenza. In un paese dove il governo e il Partito Comunista esercitano un controllo sistematico sul settore tecnologico, è fondamentale esaminare l’impatto di queste influenze sulla neutralità del modello, specialmente su temi sensibili come i diritti umani.

## Il progetto DeepSeek

DeepSeek, fondata nel 2023 da Liang Wenfeng, rappresenta un caso di studio interessante nel settore dell’IA. L’azienda si è distinta per:

* Lo sviluppo di modelli avanzati come DeepSeek-R1, che ha superato i benchmark AIME, MATH-500 e SWE-bench Verified
* L’adozione di un approccio open-source per promuovere trasparenza e collaborazione
* La capacità di sviluppare tecnologie competitive nonostante le sanzioni statunitensi

Queste caratteristiche, unite alle preoccupazioni sulla privacy dei dati e alla gestione di server in territorio cinese, rendono DeepSeek un soggetto ideale per analizzare l’equilibrio tra innovazione tecnologica e influenze governative.

## Metodologia dell’esperimento

Per valutare l’imparzialità di DeepSeek, ho sviluppato un framework di test utilizzando Gemini come valutatore indipendente. L’esperimento si è concentrato su cinque aree chiave:

1. **Evasività**: Analisi delle risposte su temi politicamente sensibili\
2. **Framing selettivo**: Confronto tra il trattamento di violazioni dei diritti in diversi paesi\
3. **Restrizioni nella citazione delle fonti**: Valutazione dell’uso di fonti indipendenti\
4. **Evasione diplomatica**: Analisi del linguaggio utilizzato\
5. **Coerenza**: Verifica della stabilità delle risposte su temi analoghi

Il processo è stato automatizzato attraverso uno script Python che ha gestito l’interazione tra i modelli e la raccolta dei dati.

## Risultati principali

L’analisi ha rivelato pattern significativi di bias nelle risposte di DeepSeek:

### Pattern di evasione

DeepSeek ha sistematicamente evitato critiche dirette al governo cinese, preferendo termini come “stabilità sociale” e “lotta al terrorismo”. Il contrasto è evidente nel trattamento più diretto di violazioni in altri paesi.

### Incoerenza nelle risposte

Il modello ha mostrato variazioni significative nelle risposte a domande simili sui diritti umani in Cina, mentre ha mantenuto maggiore coerenza nell’analisi di altri paesi.

### Limitazioni nelle fonti

Si è osservata una tendenza a evitare citazioni dirette da organizzazioni internazionali per i diritti umani quando si discuteva della Cina.

## Implicazioni e raccomandazioni

L’esperimento evidenzia problemi concreti per l’integrità dell’informazione nell’era dell’IA:

### Per gli sviluppatori

* Implementare trasparenza nei meccanismi di moderazione
* Stabilire standard uniformi di trattamento delle informazioni
* Garantire accesso a fonti indipendenti verificate

### Per gli utenti

* Sviluppare consapevolezza critica nell’uso dell’IA
* Riconoscere potenziali bias nelle risposte
* Verificare le informazioni attraverso fonti multiple

## Conclusione

Questo studio dimostra come l’IA possa diventare uno strumento di controllo informativo se non adeguatamente monitorata. La sfida non è limitata a DeepSeek o alla Cina, ma riguarda l’intero ecosistema dell’IA globale.

Per un’IA al servizio della verità e della trasparenza, servono standard condivisi di neutralità e accesso alle informazioni, con responsabilità distribuite tra sviluppatori, governi e utenti.

## Note metodologiche

_Questo articolo è stato originariamente generato utilizzando ChatGPT-4 e successivamente revisionato da Claude 3.5 Sonnet per ottimizzarne la struttura, la chiarezza e l’efficacia comunicativa._

_La metodologia completa, inclusi i prompt utilizzati e la discussione dettagliata tra i vari modelli di linguaggio (LLM), è disponibile&#xA0;_[_pubblicamente su GitHub_](https://github.com/maroffo/deepseek-bias-audit).

_Questo articolo si basa su un’analisi empirica condotta in un weekend di inizio 2025. Le conclusioni riflettono i risultati osservati durante il periodo di studio e potrebbero non rappresentare sviluppi successivi del modello DeepSeek._
