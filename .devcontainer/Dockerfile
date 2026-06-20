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
    && make -j$(nproc) release-native \
    && make -C /otp/odin/vendor/stb/src

ENV PATH=/opt/odin:${PATH}

# Runtime dependencies for karl2D apps (X11 + OpenGL + audio).
RUN apt-get update && apt-get install -y \
    libasound2-dev \
    libgl1-mesa-dev \
    libudev-dev \
    libwayland-dev \
    libegl1-mesa-dev