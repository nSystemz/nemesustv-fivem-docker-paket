FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    curl wget git xz-utils ca-certificates \
    libstdc++6 libgcc-s1 tini \
    python3 python3-bcrypt \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/fivem

COPY startup.sh /opt/fivem/startup.sh
RUN chmod +x /opt/fivem/startup.sh

EXPOSE 30120/tcp
EXPOSE 30120/udp
EXPOSE 40120/tcp

ENTRYPOINT ["/usr/bin/tini", "--", "/opt/fivem/startup.sh"]