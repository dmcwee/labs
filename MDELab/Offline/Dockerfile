# syntax=docker/dockerfile:1

################################################################################
# Pick a base image to serve as the foundation for the other build stages in
# this file.
FROM ubuntu AS base
WORKDIR /usr/share/microsoft

RUN apt update
RUN apt -y install git jq curl
RUN git clone https://github.com/microsoft/mdatp-xplat.git

COPY settings.json ./mdatp-xplat/linux/definition_downloader/.
RUN ./mdatp-xplat/linux/definition_downloader/xplat_offline_updates_download.sh

################################################################################
# Load necessary packages in the container to support offline update scripts
FROM nginx AS final
WORKDIR /usr/share/nginx/html

COPY index.html .
COPY styles.css .
COPY --from=base /usr/share/microsoft/wdav-update .
