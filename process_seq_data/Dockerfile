# FROM continuumio/miniconda
FROM ubuntu
LABEL Belson Kutambe <bkutambe@mlw.mw>

# Artic conda env
# COPY conda.yml . 

# RUN conda env create -n artic -f conda.yml && conda clean -a


RUN mkdir -p /home/nextflow/bin

COPY modules/* /home/nextflow/bin