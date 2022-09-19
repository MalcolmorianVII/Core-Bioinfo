FROM ubuntu as base

# File Author / Maintainer
LABEL Belson Malcolm Kutambe
# Install & configure docker 
RUN apt-get update
RUN apt-get install \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
RUN echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update
RUN sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Install miniconda
RUN docker pull continuumio/miniconda

RUN mkdir -p /home/nextflow/scripts

COPY ../modules/process_seq_data.nf /home/nextflow/scripts
COPY ../modules/nextflow.config /home/nextflow/scripts

RUN docker pull nextflow/nextflow




