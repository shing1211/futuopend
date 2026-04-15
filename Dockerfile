# syntax=docker/dockerfile:1
#
# Copyright 2026 shing1211
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

ARG FUTU_OPEND_VER=10.2.6208

FROM ubuntu:24.04 AS base-ubuntu
FROM rockylinux:9 AS base-centos

FROM base-ubuntu AS build-ubuntu-amd64
ARG FUTU_OPEND_VER

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -fsSL "https://softwaredownload.futunn.com/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04.tar.gz" \
         -o Futu_OpenD.tar.gz \
    && tar -xzf Futu_OpenD.tar.gz \
    && rm Futu_OpenD.tar.gz

FROM base-ubuntu AS build-ubuntu-arm64
ARG FUTU_OPEND_VER

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -fsSL "https://softwaredownload.futunn.com/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04.tar.gz" \
         -o Futu_OpenD.tar.gz \
    && tar -xzf Futu_OpenD.tar.gz \
    && rm Futu_OpenD.tar.gz

FROM base-centos AS build-rocky-amd64
ARG FUTU_OPEND_VER

WORKDIR /tmp
RUN curl -fsSL "https://softwaredownload.futunn.com/Futu_OpenD_${FUTU_OPEND_VER}_Centos7.tar.gz" \
         -o Futu_OpenD.tar.gz \
    && tar -xzf Futu_OpenD.tar.gz \
    && rm Futu_OpenD.tar.gz

FROM base-centos AS build-rocky-arm64
ARG FUTU_OPEND_VER

WORKDIR /tmp
RUN curl -fsSL "https://softwaredownload.futunn.com/Futu_OpenD_${FUTU_OPEND_VER}_Centos7.tar.gz" \
         -o Futu_OpenD.tar.gz \
    && tar -xzf Futu_OpenD.tar.gz \
    && rm Futu_OpenD.tar.gz

FROM ubuntu:24.04 AS final-ubuntu-amd64
ARG FUTU_OPEND_VER

ENV TZ=Asia/Hong_Kong \
    FUTU_OPEND_VER=${FUTU_OPEND_VER}

RUN useradd -m futuopend \
    && mkdir -p /run/secrets \
    && chown futuopend:futuopend /run/secrets \
    && mkdir -p /home/futuopend/.com.futunn.FutuOpenD \
    && chown futuopend:futuopend /home/futuopend/.com.futunn.FutuOpenD

COPY --from=build-ubuntu-amd64 --chown=futuopend:futuopend \
     /tmp/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04/ \
     /usr/local/bin/
COPY scripts/wrapper.sh /usr/local/bin/wrapper.sh

RUN chmod +x /usr/local/bin/FutuOpenD \
    && chmod +x /usr/local/bin/wrapper.sh

USER futuopend
WORKDIR /home/futuopend
EXPOSE 11111 11112
VOLUME /home/futuopend/.com.futunn.FutuOpenD
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -x FutuOpenD || exit 1
CMD ["/usr/local/bin/wrapper.sh"]

FROM ubuntu:24.04 AS final-ubuntu-arm64
ARG FUTU_OPEND_VER

ENV TZ=Asia/Hong_Kong \
    FUTU_OPEND_VER=${FUTU_OPEND_VER}

RUN useradd -m futuopend \
    && mkdir -p /run/secrets \
    && chown futuopend:futuopend /run/secrets \
    && mkdir -p /home/futuopend/.com.futunn.FutuOpenD \
    && chown futuopend:futuopend /home/futuopend/.com.futunn.FutuOpenD

COPY --from=build-ubuntu-arm64 --chown=futuopend:futuopend \
     /tmp/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04/ \
     /usr/local/bin/

COPY --chown=futuopend:futuopend entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/FutuOpenD

USER futuopend
WORKDIR /home/futuopend
EXPOSE 11111 11112
VOLUME /home/futuopend/.com.futunn.FutuOpenD
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -x FutuOpenD || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM rockylinux:9 AS final-rocky-amd64
ARG FUTU_OPEND_VER

ENV TZ=Asia/Hong_Kong \
    FUTU_OPEND_VER=${FUTU_OPEND_VER}

RUN useradd -m futuopend \
    && mkdir -p /run/secrets \
    && chown futuopend:futuopend /run/secrets \
    && mkdir -p /home/futuopend/.com.futunn.FutuOpenD \
    && chown futuopend:futuopend /home/futuopend/.com.futunn.FutuOpenD

COPY --from=build-rocky-amd64 --chown=futuopend:futuopend \
     /tmp/Futu_OpenD_${FUTU_OPEND_VER}_Centos7/Futu_OpenD_${FUTU_OPEND_VER}_Centos7/ \
     /usr/local/bin/

COPY --chown=futuopend:futuopend entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN chmod +x /usr/local/bin/FutuOpenD

USER futuopend
WORKDIR /home/futuopend
EXPOSE 11111 11112
VOLUME /home/futuopend/.com.futunn.FutuOpenD
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -x FutuOpenD || exit 1
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

FROM rockylinux:9 AS final-rocky-arm64
ARG FUTU_OPEND_VER

ENV TZ=Asia/Hong_Kong \
    FUTU_OPEND_VER=${FUTU_OPEND_VER}

RUN useradd -m futuopend \
    && mkdir -p /run/secrets \
    && chown futuopend:futuopend /run/secrets \
    && mkdir -p /home/futuopend/.com.futunn.FutuOpenD \
    && chown futuopend:futuopend /home/futuopend/.com.futunn.FutuOpenD

COPY --from=build-rocky-arm64 --chown=futuopend:futuopend \
     /tmp/Futu_OpenD_${FUTU_OPEND_VER}_Centos7/Futu_OpenD_${FUTU_OPEND_VER}_Centos7/ \
     /usr/local/bin/
COPY scripts/wrapper.sh /usr/local/bin/wrapper.sh

RUN chmod +x /usr/local/bin/FutuOpenD \
    && chmod +x /usr/local/bin/wrapper.sh

USER futuopend
WORKDIR /home/futuopend
EXPOSE 11111 11112
VOLUME /home/futuopend/.com.futunn.FutuOpenD
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD pgrep -x FutuOpenD || exit 1
CMD ["/usr/local/bin/wrapper.sh"]

