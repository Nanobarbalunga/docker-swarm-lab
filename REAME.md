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
git clone https://github.com/Nanobarbalunga/swarm-lab-simulator.git
cd swarm-lab-simulator

```

---

## 📜 Licenza

Questo progetto è distribuito sotto la licenza [GPL-2.0](LICENSE).
© 2026 Enrico Fontana
