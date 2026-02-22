FROM debian:bookworm-slim

ARG DEBIAN_FRONTEND=noninteractive

# Tool utili: tc/netem (iproute2), iptables, procps, ca-certificates, curl, tini
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl gnupg iproute2 iptables procps jq tini \
 && rm -rf /var/lib/apt/lists/*

# Repo ufficiale Docker + install engine (dockerd) e containerd
RUN install -m 0755 -d /etc/apt/keyrings \
 && curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc \
 && chmod a+r /etc/apt/keyrings/docker.asc \
 && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
    https://download.docker.com/linux/debian bookworm stable" > /etc/apt/sources.list.d/docker.list \
 && apt-get update \
 && apt-get install -y --no-install-recommends docker-ce docker-ce-cli containerd.io \
 && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Tini come PID1 per gestire bene i segnali
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]