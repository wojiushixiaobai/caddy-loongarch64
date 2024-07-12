FROM golang:1.22-buster as builder

ARG GORELEASER_VERSION=latest

WORKDIR /opt

RUN set -ex; \
    go install github.com/goreleaser/goreleaser@${GORELEASER_VERSION}

RUN set -ex; \
    SYTF_VERSION=$(curl -s https://api.github.com/repos/anchore/syft/releases/latest | grep tag_name | cut -d '"' -f 4); \
    git clone -b ${SYTF_VERSION} --depth 1 https://github.com/anchore/syft; \
    cd /opt/syft; \
    go install -v ./cmd/syft; \
    cd /opt; \
    rm -rf /opt/syft

ARG CADDY_VERSION=v2.8.4
ARG WORKDIR=/opt/caddy

ADD .goreleaser.yml /opt/.goreleaser.yml

RUN set -ex; \
    git clone -b ${CADDY_VERSION} https://github.com/caddyserver/caddy ${WORKDIR}

ARG TAG=${CADDY_VERSION}
WORKDIR ${WORKDIR}

RUN set -ex; \
    goreleaser release --config ../.goreleaser.yml --skip=publish --clean

FROM debian:buster-slim

WORKDIR /opt/caddy

COPY --from=builder /opt/caddy/dist /opt/caddy/dist

VOLUME /dist

CMD cp -rf dist/* /dist/