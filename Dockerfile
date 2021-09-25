# Compiler Image
# --------------------------------------------------------------------------
FROM blockblu/ubuntu:20.04-ghc AS compiler

WORKDIR /

ARG NODE_REPO
ARG NODE_BRANCH
ARG NODE_VERSION

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf \
        automake \
        build-essential \
        ca-certificates \
        git \
        libtool \
        make \
        pkg-config && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/input-output-hk/libsodium.git && \
    cd libsodium && \
    git checkout 66f017f1 --quiet

RUN cd libsodium && \
    ./autogen.sh && ./configure && \
    make && make check && make install && \
    rm -rf ../libsodium

RUN git clone $NODE_REPO cardano-node -b $NODE_BRANCH --recurse-submodules && \
    cd cardano-node && \
    git fetch --all --tags && \
    git checkout tags/$NODE_VERSION --quiet && \
    git submodule update --init
RUN cd cardano-node && \ 
    cabal update && \
    cabal build all && \
    mkdir -p /binaries/ && \
    cp $(find /cardano-node -name cardano-cli -type f -executable) /binaries/ && \
    cp $(find /cardano-node -name cardano-node -type f -executable) /binaries/

# Compiler for the health check program written in Go
# -------------------------------------------------------------------------
FROM golang:1.15 AS healthCheckCompiler

COPY healthcheck healthcheck
WORKDIR healthcheck
RUN mkdir -p /binaries/ && \
    go mod vendor && \
    go build && \
    mv healthcheck /binaries/

# Main Image
# -------------------------------------------------------------------------
FROM blockblu/ubuntu:20.04

ENV DFILE_VERSION "u"

RUN groupadd -r lovelace --gid 1402 && \
    useradd --no-log-init --uid 1402 -r -g lovelace lovelace

USER lovelace

STOPSIGNAL SIGINT

COPY --from=healthCheckCompiler /binaries/healthcheck /usr/local/bin/

LABEL maintainer="Kevin Haller <keivn.haller@blockblu.io>"
LABEL version="${DFILE_VERSION}${NODE_VERSION}"
LABEL description="Blockchain node for Cardano (implemented in Haskell)."

COPY --from=compiler /binaries/cardano-node /usr/local/bin/
COPY --from=compiler /binaries/cardano-cli /usr/local/bin/

ENTRYPOINT ["cardano-node"]
