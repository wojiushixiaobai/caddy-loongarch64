FROM golang:1.21-buster as builder

ARG GORELEASER_VERSION=latest
ARG SYTF_VERSION=v0.98.0

WORKDIR /opt

RUN set -ex; \
    go install github.com/goreleaser/goreleaser@${GORELEASER_VERSION}

RUN set -ex; \
    git clone -b ${SYTF_VERSION} --depth 1 https://github.com/anchore/syft; \
    cd /opt/syft; \
    sed -i "s@modernc.org/sqlite@gorm.io/driver/sqlite@g" cmd/syft/main.go; \
    sed -i "s@modernc.org/sqlite .*@gorm.io/driver/sqlite v1.5.4@g" go.mod; \
    go mod tidy; \
    go install -v ./cmd/syft; \
    cd /opt; \
    rm -rf /opt/syft

ARG CADDY_VERSION=v2.7.6
ARG WORKDIR=/opt/caddy

ADD .goreleaser.yml /opt/.goreleaser.yml

RUN set -ex; \
    git clone -b ${CADDY_VERSION} https://github.com/caddyserver/caddy ${WORKDIR}

ARG TAG=${CADDY_VERSION}
WORKDIR ${WORKDIR}

RUN set -ex; \
    goreleaser release --config ../.goreleaser.yml --skip-publish --clean

FROM debian:buster-slim

WORKDIR /opt/caddy

COPY --from=builder /opt/caddy/dist /opt/caddy/dist

VOLUME /dist

CMD cp -rf dist/* /dist/