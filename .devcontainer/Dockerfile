# Default to linux/amd64 — Android NDK host binaries are published for Linux x86_64.
# Override at build time with: --build-arg DEVCONTAINER_PLATFORM=linux/arm64
ARG DEVCONTAINER_PLATFORM=linux/amd64
FROM --platform=${DEVCONTAINER_PLATFORM} ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

# Base utilities and build tooling.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    make \
    cmake \
    ninja-build \
    pkg-config \
    python3 \
    zip \
    unzip \
    xz-utils \
    tar \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    clang \
    lld \
    llvm 

RUN git clone https://github.com/odin-lang/Odin.git /opt/odin \
    && cd /opt/odin \
    && git checkout dev-2026-06 \
    && make -j$(nproc) release-native

# Emscripten SDK for wasm toolchains.
ARG EMSDK_VERSION=latest
RUN git clone https://github.com/emscripten-core/emsdk.git /opt/emsdk \
    && /opt/emsdk/emsdk install ${EMSDK_VERSION} \
    && /opt/emsdk/emsdk activate ${EMSDK_VERSION} \
    && nodeBin="$(find /opt/emsdk/node -type f -path '*/bin/node' | head -n 1)" \
    && test -n "${nodeBin}" \
    && ln -sf "${nodeBin}" /usr/local/bin/node

ENV EMSDK=/opt/emsdk
ENV EMSCRIPTEN_ROOT=/opt/emsdk/upstream/emscripten
ENV PATH=${EMSDK}:${EMSCRIPTEN_ROOT}:${PATH}
ENV PATH=/opt/odin:${PATH}

# Runtime dependencies for raylib/GLFW apps (X11 + OpenGL + audio).
RUN apt-get update && apt-get install -y --no-install-recommends \
    libx11-6 \
    libxrandr2 \
    libxinerama1 \
    libxcursor1 \
    libxi6 \
    libgl1 \
    libasound2t64 \
    libxext6 \
    libxrender1 \
    libxfixes3 \
    && rm -rf /var/lib/apt/lists/*