FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu22.04 as base
CMD nvidia-smi

# Set the base image to Ubuntu 18.04 and NVIDIA GPU
# FROM nvidia/cuda:11.1-base-ubuntu18.04

# File Author / Maintainer
LABEL Laurent Jourdren <jourdren@biologie.ens.fr>

ARG PACKAGE_VERSION=6.0.1
ARG BUILD_PACKAGES="wget apt-transport-https"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt update && \
    apt install --yes $BUILD_PACKAGES libnvidia-compute-460-server && \ 
    cd /tmp && \
    wget -q https://mirror.oxfordnanoportal.com/software/analysis/ont_guppy_${PACKAGE_VERSION}-1~bionic_amd64.deb && \
    apt install --yes /tmp/ont_guppy_${PACKAGE_VERSION}-1~bionic_amd64.deb && \
    rm *.deb && \
    apt-get autoremove --purge --yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
