# Adapted from https://github.com/verilator/verilator/blob/cf9ac8270b9c67b103fa69443d80a45b7440196c/ci/docker/run/Dockerfile

# DESCRIPTION: Dockerfile for image to run Verilator inside
#
# Copyright 2020 by Stefan Wallentowitz. This program is free software; you
# can redistribute it and/or modify it under the terms of either the GNU
# Lesser General Public License Version 3 or the Perl Artistic License
# Version 2.0.
# SPDX-License-Identifier: LGPL-3.0-only OR Artistic-2.0

FROM ubuntu:20.04 AS builder

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get install --no-install-recommends -y \
                        autoconf \
                        bc \
                        bison \
                        build-essential \
                        bzip2 \
                        ca-certificates \
                        ccache \
                        flex \
                        git \
                        libfl-dev \
                        libgoogle-perftools-dev \
                        perl \
                        python3 \
                        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ARG REPO=https://github.com/verilator/verilator
ARG SOURCE_COMMIT=v4.110

WORKDIR /tmp

# Add an exception for the linter, we want to cd here in one layer
# to reduce the number of layers (and thereby size).
# hadolint ignore=DL3003
RUN git clone "${REPO}" verilator && \
    cd verilator && \
    git checkout "${SOURCE_COMMIT}" && \
    autoconf && \
    ./configure && \
    make -j "$(nproc)" && \
    mkdir /tmp/verilator_dist && \
    make DESTDIR=/tmp/verilator_dist install && \
    cd .. && \
    rm -r verilator


FROM ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive \
    && apt-get install --no-install-recommends -y \
                        bzip2 \
                        build-essential \
                        ca-certificates \
                        ccache \
                        git \
                        perl \
                        unzip \
                        wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Add ARM Cortex toolchain
WORKDIR /opt
RUN wget -qO- https://developer.arm.com/-/media/Files/downloads/gnu-rm/10-2020q4/gcc-arm-none-eabi-10-2020-q4-major-x86_64-linux.tar.bz2 | tar -xj
ENV PATH "/opt/gcc-arm-none-eabi-10-2020-q4-major/bin:$PATH"

# Add built Verilator (globally)
COPY --from=builder /tmp/verilator_dist /

RUN arm-none-eabi-gcc --version
RUN verilator --version

WORKDIR /work
