#!/usr/bin/env bash
set -euo pipefail

START_DELAY="${START_DELAY:-0}"                 # secondi
RELIABILITY="${RELIABILITY:-1.0}"               # 0.0..1.0
CHECK_INTERVAL="${CHECK_INTERVAL:-10}"          # secondi
CRASH_MODE="${CRASH_MODE:-exit}"                # exit | reboot (exit comunque nel container)
DOCKERD_ARGS="${DOCKERD_ARGS:-}"                # extra args
DOCKERD_HOSTS="${DOCKERD_HOSTS:---host=unix:///var/run/docker.sock}"

# NETEM (opzionale)
NETEM_IFACE="${NETEM_IFACE:-eth0}"
NETEM_DELAY_MS="${NETEM_DELAY_MS:-}"            # es: 80
NETEM_JITTER_MS="${NETEM_JITTER_MS:-}"          # es: 20
NETEM_LOSS_PCT="${NETEM_LOSS_PCT:-}"            # es: 2
NETEM_RATE="${NETEM_RATE:-}"                    # es: 5mbit

# Swarm (opzionale)
SWARM_INIT="${SWARM_INIT:-0}"                   # 1 per init in questo nodo
SWARM_ADVERTISE_ADDR="${SWARM_ADVERTISE_ADDR:-}"# es: 10.10.0.10
SWARM_JOIN_TOKEN="${SWARM_JOIN_TOKEN:-}"        # token join
SWARM_MANAGER_ADDR="${SWARM_MANAGER_ADDR:-}"    # es: 10.10.0.1:2377

echo "[node] START_DELAY=${START_DELAY}s"
sleep "${START_DELAY}"

apply_netem() {
  # reset prima
  tc qdisc del dev "${NETEM_IFACE}" root 2>/dev/null || true

  local args=()
  if [[ -n "${NETEM_DELAY_MS}" ]]; then
    if [[ -n "${NETEM_JITTER_MS}" ]]; then
      args+=(delay "${NETEM_DELAY_MS}ms" "${NETEM_JITTER_MS}ms")
    else
      args+=(delay "${NETEM_DELAY_MS}ms")
    fi
  fi
  if [[ -n "${NETEM_LOSS_PCT}" ]]; then
    args+=(loss "${NETEM_LOSS_PCT}%")
  fi
  if [[ -n "${NETEM_RATE}" ]]; then
    args+=(rate "${NETEM_RATE}")
  fi

  if [[ "${#args[@]}" -gt 0 ]]; then
    echo "[node] Applying netem on ${NETEM_IFACE}: ${args[*]}"
    tc qdisc add dev "${NETEM_IFACE}" root netem "${args[@]}"
  else
    echo "[node] NETEM not configured"
  fi
}

if [[ -n "${NETEM_DELAY_MS}${NETEM_LOSS_PCT}${NETEM_RATE}" ]]; then
  apply_netem
fi

# Avvio dockerd (senza systemd)
echo "[node] starting dockerd..."
dockerd ${DOCKERD_HOSTS} ${DOCKERD_ARGS} >/var/log/dockerd.log 2>&1 &
DOCKERD_PID=$!

# Attendo che Docker risponda
echo -n "[node] waiting for docker to be ready"
for i in $(seq 1 60); do
  if docker info >/dev/null 2>&1; then
    echo " -> ready"
    break
  fi
  echo -n "."
  sleep 1
done

if ! docker info >/dev/null 2>&1; then
  echo
  echo "[node] ERROR: docker did not start. Showing last dockerd.log lines:"
  tail -n 200 /var/log/dockerd.log || true
  exit 1
fi

# Swarm init / join (opzionale)
if [[ "${SWARM_INIT}" == "1" ]]; then
  if [[ -z "${SWARM_ADVERTISE_ADDR}" ]]; then
    # prova best-effort: IP dell'interfaccia netem
    SWARM_ADVERTISE_ADDR="$(ip -4 addr show "${NETEM_IFACE}" | awk '/inet /{print $2}' | cut -d/ -f1 | head -n1 || true)"
  fi
  echo "[node] swarm init advertise-addr=${SWARM_ADVERTISE_ADDR}"
  docker swarm init --advertise-addr "${SWARM_ADVERTISE_ADDR}" >/dev/null 2>&1 || true
elif [[ -n "${SWARM_JOIN_TOKEN}" && -n "${SWARM_MANAGER_ADDR}" ]]; then
  echo "[node] swarm join manager=${SWARM_MANAGER_ADDR}"
  docker swarm join --token "${SWARM_JOIN_TOKEN}" "${SWARM_MANAGER_ADDR}" >/dev/null 2>&1 || true
else
  echo "[node] swarm: not configured (manual join or set env)"
fi

# Crash monitor basato su RELIABILITY
# ad ogni CHECK_INTERVAL: se random > RELIABILITY => crash
crash_monitor() {
  # soglia intera 0..65535
  local thr
  thr="$(awk -v r="${RELIABILITY}" 'BEGIN{ if (r<0) r=0; if (r>1) r=1; printf "%d", r*65535 }')"
  echo "[node] reliability=${RELIABILITY} => threshold=${thr}/65535, check every ${CHECK_INTERVAL}s"

  while true; do
    sleep "${CHECK_INTERVAL}"
    # random 0..65535
    local rnd
    rnd="$(od -An -N2 -tu2 /dev/urandom | tr -d ' ')"
    if [[ "${rnd}" -gt "${thr}" ]]; then
      echo "[node] *** SIMULATED CRASH *** (rnd=${rnd} > thr=${thr})"
      kill -TERM "${DOCKERD_PID}" 2>/dev/null || true
      sleep 2
      kill -KILL "${DOCKERD_PID}" 2>/dev/null || true
      if [[ "${CRASH_MODE}" == "reboot" ]]; then
        exit 1
      else
        exit 1
      fi
    fi
  done
}

# se reliability < 1.0 attivo monitor; se =1.0 non serve
if awk -v r="${RELIABILITY}" 'BEGIN{exit !(r<1.0)}'; then
  crash_monitor &
fi

# Keep container alive finché dockerd è vivo
wait "${DOCKERD_PID}"