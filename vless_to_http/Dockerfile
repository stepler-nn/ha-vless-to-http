ARG BUILD_FROM=ghcr.io/thejohnd0e/vless-to-http:latest
FROM ${BUILD_FROM}

# Home Assistant add-ons run as root; the upstream image drops to an unprivileged
# user, so switch back so /data/options.json can be read and jq installed.
USER root
RUN apk add --no-cache jq

# 8181 replaces the upstream default HTTP proxy port 8080.
# These ENV values also make the inherited HEALTHCHECK probe the right port.
ENV LISTEN_ADDR=0.0.0.0 \
    HTTP_LISTEN_PORT=8181 \
    SOCKS_LISTEN_PORT=1080

COPY run.sh /run.sh
COPY xray-wrapper.sh /app/xray-wrapper.sh
RUN chmod 755 /run.sh /app/xray-wrapper.sh

EXPOSE 8181 1080
CMD [ "/run.sh" ]
