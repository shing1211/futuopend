# syntax=docker/dockerfile:1

ARG FUTU_OPEND_VER=10.2.6208

FROM ubuntu:24.04 AS base-ubuntu
FROM rockylinux:9 AS base-centos

FROM base-ubuntu AS build-ubuntu
ARG FUTU_OPEND_VER

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp
RUN curl -fsSL "https://softwaredownload.futunn.com/Futu_OpenD_${FUTU_OPEND_VER}_Ubuntu18.04.tar.gz" \
         -o Futu_OpenD.tar.gz \
    && tar -xzf Futu_OpenD.tar.gz \
    && rm Futu_OpenD.tar.gz

FROM base-centos AS build-rocky
ARG FUTU_OPEND_VER

WORKDIR /tmp
RUN curl -fsSL "https://softwaredownload.futunn.com/Futu_OpenD_${FUTU_OPEND_VER}_Centos7.tar.gz" \
         -o Futu_OpenD.tar.gz \
    && tar -xzf Futu_OpenD.tar.gz \
    && rm Futu_OpenD.tar.gz

FROM ubuntu:24.04 AS final-ubuntu
ARG FUTU_OPEND_VER

ENV TZ=Asia/Hong_Kong \
    FUTU_OPEND_VER=${FUTU_OPEND_VER}

RUN useradd -m futuopend \
    && mkdir -p /run/secrets \
    && chown futuopend:futuopend /run/secrets \
    && mkdir -p /home/futuopend/.com.futunn.FutuOpenD \
    && chown futuopend:futuopend /home/futuopend/.com.futunn.FutuOpenD

COPY --from=build-ubuntu --chown=futuopend:futuopend \
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

FROM rockylinux:9 AS final-rocky
ARG FUTU_OPEND_VER

ENV TZ=Asia/Hong_Kong \
    FUTU_OPEND_VER=${FUTU_OPEND_VER}

RUN useradd -m futuopend \
    && mkdir -p /run/secrets \
    && chown futuopend:futuopend /run/secrets \
    && mkdir -p /home/futuopend/.com.futunn.FutuOpenD \
    && chown futuopend:futuopend /home/futuopend/.com.futunn.FutuOpenD

COPY --from=build-rocky --chown=futuopend:futuopend \
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

