# 📦 Docker Swarm Lab Simulator  
### Ambiente di simulazione di una rete Docker Swarm per Lab ed esercizi

---

## 🧪 Descrizione

Docker Swarm Lab Simulator è un ambiente containerizzato progettato per simulare una rete Docker Swarm composta da nodi con comportamento variabile e instabile.

L'obiettivo è fornire un laboratorio pratico per:

- Studio del comportamento di Docker Swarm
- Test di resilienza e ripristino automatico delle repliche
- Simulazione di crash dei nodi
- Simulazione di latenze, perdita di pacchetti e degrado di rete
- Esercitazioni su orchestrazione e fault tolerance
- Comprensione dei meccanismi di scheduling e failover

Il sistema consente di avviare più nodi Docker simulati all'interno di container, ciascuno con parametri personalizzabili tramite variabili d'ambiente.

⚠️ Questo progetto è destinato esclusivamente ad ambienti di laboratorio e studio.

---

## ⚙️ Architettura

Ogni nodo simulato:

- È basato su Debian
- Ha Docker Engine installato
- Avvia `dockerd` manualmente (Docker-in-Docker)
- Può:
  - Ritardare l'avvio
  - Simulare crash casuali
  - Simulare problemi di rete (delay, jitter, loss, rate limit)
  - Joinare automaticamente uno swarm esistente
  - Inizializzare uno swarm locale

La rete tra i nodi è condivisa tramite bridge Docker.

---

## 🛠️ Requisiti

- Docker Engine installato sull'host
- Docker Compose v2
- Sistema Linux
- Supporto modalità `privileged: true`

---

## 🚀 Avvio del laboratorio

### 1️⃣ Clonare il progetto

```bash
git clone https://github.com/Nanobarbalunga/docker-swarm-lab.git
cd docker-swarm-lab

```

---

### 2️⃣  Collegamento ad uno Swarm esistente

Recuperare il token dal manager:

```bash
docker swarm join-token worker -q
```

Connettere manualmente i nodi:
//TODO...

```bash
docker swarm join \
  --token <TOKEN> 
```

## 🔧 Opzioni dell'immagine

### 🔗 Collegamento ad uno Swarm esistente

```bash
environment:
  SWARM_JOIN_TOKEN: "<TOKEN>"
  SWARM_MANAGER_ADDR: "192.168.1.10:2377"
```

### 🔥 Simulazione Crash

Il parametro RELIABILITY determina la probabilità che il nodo rimanga attivo.

Esempio:

```bash
1.0 → Nodo stabile

0.95 → 5% probabilità crash ad ogni check

0.80 → Nodo altamente instabile

```

Questo consente di osservare il comportamento del manager swarm nel ripristino automatico dei servizi.

### 🌐 Simulazione Problemi di Rete

Esempio configurazione:

```bash
environment:
  NETEM_DELAY_MS: "120"
  NETEM_JITTER_MS: "40"
  NETEM_LOSS_PCT: "1"
  NETEM_RATE: "10mbit"
```

Simula:

- Alta latenza

- Variazione di latenza

- Perdita pacchetti

- Banda limitata

### Variabili d'ambiente

É possibile modificare le opzioni dell'immagine utilizzando le variabili d'ambiente.

#### Avvio

| Variabile        | Descrizione                                   | Default |
| ---------------- | --------------------------------------------- | ------- |
| `START_DELAY`    | Ritardo in secondi prima dell'avvio di Docker | 0       |
| `RELIABILITY`    | Affidabilità del nodo (0.0 – 1.0)             | 1.0     |
| `CHECK_INTERVAL` | Intervallo di controllo crash                 | 10      |
| `CRASH_MODE`     | Modalità crash (exit/reboot)                  | exit    |

#### Simulazione di rete (tc netem)

| Variabile         | Descrizione                   |
| ----------------- | ----------------------------- |
| `NETEM_DELAY_MS`  | Latenza in millisecondi       |
| `NETEM_JITTER_MS` | Variazione latenza            |
| `NETEM_LOSS_PCT`  | Percentuale perdita pacchetti |
| `NETEM_RATE`      | Limitazione banda (es: 5mbit) |

#### Swarm

| Variabile              | Descrizione                   |
| ---------------------- | ----------------------------- |
| `SWARM_INIT`           | Se 1 inizializza swarm locale |
| `SWARM_ADVERTISE_ADDR` | IP advertise                  |
| `SWARM_JOIN_TOKEN`     | Token join                    |
| `SWARM_MANAGER_ADDR`   | Indirizzo manager (IP:2377)   |

---

## 📜 Licenza

Questo progetto è distribuito sotto la licenza [GPL-2.0](LICENSE).
© 2026 Enrico Fontana
