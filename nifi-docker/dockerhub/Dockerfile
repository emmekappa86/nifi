# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements. See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership. The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied. See the License for the
# specific language governing permissions and limitations
# under the License.
#

ARG IMAGE_NAME=debian
ARG IMAGE_TAG=11
FROM ${IMAGE_NAME}:${IMAGE_TAG}
ARG MAINTAINER="Apache NiFi <dev@nifi.apache.org>"
LABEL maintainer="${MAINTAINER}"
LABEL site="https://nifi.apache.org"

ARG SISMAP_USER=sismap
ARG UID=1000
ARG GID=1000
ARG NIFI_VERSION=1.21.0
ARG BASE_URL=https://archive.apache.org/dist
ARG MIRROR_BASE_URL=${MIRROR_BASE_URL:-${BASE_URL}}
ARG DISTRO_PATH=${DISTRO_PATH:-${NIFI_VERSION}}
ARG NIFI_BINARY_PATH=${NIFI_BINARY_PATH:-/nifi/${DISTRO_PATH}/nifi-${NIFI_VERSION}-bin.zip}
ARG NIFI_TOOLKIT_BINARY_PATH=${NIFI_TOOLKIT_BINARY_PATH:-/nifi/${DISTRO_PATH}/nifi-toolkit-${NIFI_VERSION}-bin.zip}

ENV NIFI_BASE_DIR=/opt/nifi
ENV NIFI_HOME ${NIFI_BASE_DIR}/nifi-current
ENV NIFI_TOOLKIT_HOME ${NIFI_BASE_DIR}/nifi-toolkit-current
ENV NIFI_PID_DIR=${NIFI_HOME}/run
ENV NIFI_LOG_DIR=${NIFI_HOME}/logs

### Sismap Specific Instructions ###

RUN apt update
RUN apt install -y curl default-jre

### End Sismap Specific Instructions ###

ADD sh/ ${NIFI_BASE_DIR}/scripts/
RUN chmod -R +x ${NIFI_BASE_DIR}/scripts/*.sh

# Setup NiFi user and create necessary directories
RUN groupadd -g ${GID} ${SISMAP_USER} || groupmod -n ${SISMAP_USER} `getent group ${GID} | cut -d: -f1` \
    && useradd --shell /bin/bash -u ${UID} -g ${GID} -m ${SISMAP_USER} \
    && mkdir -p ${NIFI_BASE_DIR} \
    && chown -R ${SISMAP_USER}:${SISMAP_USER} ${NIFI_BASE_DIR} \
    && apt-get update \
    && apt-get install -y jq xmlstarlet procps unzip \
    && apt-get -y autoremove \
    && apt-get clean autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

USER ${SISMAP_USER}

# Download, validate, and expand Apache NiFi Toolkit binary.
RUN curl -fSL ${MIRROR_BASE_URL}/${NIFI_TOOLKIT_BINARY_PATH} -o ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip \
    && echo "$(curl ${BASE_URL}/${NIFI_TOOLKIT_BINARY_PATH}.sha256) *${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip" | sha256sum -c - \
    && unzip ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip -d ${NIFI_BASE_DIR} \
    && rm ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}-bin.zip \
    && mv ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION} ${NIFI_TOOLKIT_HOME} \
    && ln -s ${NIFI_TOOLKIT_HOME} ${NIFI_BASE_DIR}/nifi-toolkit-${NIFI_VERSION}

# Download, validate, and expand Apache NiFi binary.
RUN curl -fSL ${MIRROR_BASE_URL}/${NIFI_BINARY_PATH} -o ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip \
    && echo "$(curl ${BASE_URL}/${NIFI_BINARY_PATH}.sha256) *${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip" | sha256sum -c - \
    && unzip ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip -d ${NIFI_BASE_DIR} \
    && rm ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}-bin.zip \
    && mv ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION} ${NIFI_HOME} \
    && mkdir -p ${NIFI_HOME}/conf \
    && mkdir -p ${NIFI_HOME}/database_repository \
    && mkdir -p ${NIFI_HOME}/flowfile_repository \
    && mkdir -p ${NIFI_HOME}/content_repository \
    && mkdir -p ${NIFI_HOME}/provenance_repository \
    && mkdir -p ${NIFI_HOME}/state \
    && mkdir -p ${NIFI_LOG_DIR} \
    && ln -s ${NIFI_HOME} ${NIFI_BASE_DIR}/nifi-${NIFI_VERSION}
    
### Sismap Specific Instructions ###

# Importing Nifi custom properties
COPY data/conf/nifi.custom.properties /opt/nifi/nifi-current/conf/

# Importing Siemens certificates
ARG TRUSTSTORE_PASSWORD
RUN mkdir /opt/nifi/nifi-current/conf/sismap_certs/
COPY ./data/certs/siemens_root_ca_v3.0_2016.pem /opt/nifi/nifi-current/conf/sismap_certs/
COPY ./data/certs/siemens_issuing_ca_intranet_server_2017.pem /opt/nifi/nifi-current/conf/sismap_certs/
RUN keytool -import -trustcacerts -alias siemens_root_ca_v3.0_2016 -file /opt/nifi/nifi-current/conf/sismap_certs/siemens_root_ca_v3.0_2016.pem -keystore /opt/nifi/nifi-current/conf/sismap_certs/sismap_truststore.p12 -storepass ${TRUSTSTORE_PASSWORD} -noprompt
RUN keytool -import -trustcacerts -alias siemens_issuing_ca_intranet_server_2017 -file /opt/nifi/nifi-current/conf/sismap_certs/siemens_issuing_ca_intranet_server_2017.pem -keystore /opt/nifi/nifi-current/conf/sismap_certs/sismap_truststore.p12 -storepass ${TRUSTSTORE_PASSWORD} -noprompt

# Creating Sismap's CA and root certificate
ARG ROOTCERT_PASSWORD
RUN mkdir /opt/nifi/nifi-current/conf/sismap_certs/CA && mkdir /opt/nifi/nifi-current/conf/sismap_certs/CA/new_certs
RUN cd /opt/nifi/nifi-current/conf/sismap_certs/CA && openssl genpkey -algorithm RSA -out sismap_ca_key.pem -aes256 -pass pass:${ROOTCERT_PASSWORD}
RUN cd /opt/nifi/nifi-current/conf/sismap_certs/CA && openssl req -new -x509 -days 365 -key sismap_ca_key.pem -out sismap_ca_cert.pem -passin pass:${ROOTCERT_PASSWORD} -subj "/CN=SiSMAP_CA"
RUN keytool -import -trustcacerts -alias SiSMAP_root -file /opt/nifi/nifi-current/conf/sismap_certs/CA/sismap_ca_cert.pem -keystore /opt/nifi/nifi-current/conf/sismap_certs/sismap_truststore.p12 -storepass ${TRUSTSTORE_PASSWORD} -noprompt

# Copying SiSMAP scripts
RUN mkdir /home/sismap/scripts
COPY data/scripts/certmanagement.sh /home/sismap/scripts

### End Sismap Specific Instructions ###

VOLUME ${NIFI_LOG_DIR} \
       ${NIFI_HOME}/conf \
       ${NIFI_HOME}/database_repository \
       ${NIFI_HOME}/flowfile_repository \
       ${NIFI_HOME}/content_repository \
       ${NIFI_HOME}/provenance_repository \
       ${NIFI_HOME}/state

# Clear nifi-env.sh in favour of configuring all environment variables in the Dockerfile
RUN echo "#!/bin/sh\n" > $NIFI_HOME/bin/nifi-env.sh

# Web HTTP(s) & Socket Site-to-Site Ports
EXPOSE 8080 8443 10000 8000

WORKDIR ${NIFI_HOME}

# Apply configuration and start NiFi
#
# We need to use the exec form to avoid running our command in a subshell and omitting signals,
# thus being unable to shut down gracefully:
# https://docs.docker.com/engine/reference/builder/#entrypoint
#
# Also we need to use relative path, because the exec form does not invoke a command shell,
# thus normal shell processing does not happen:
# https://docs.docker.com/engine/reference/builder/#exec-form-entrypoint-example
ENTRYPOINT ["../scripts/start.sh"]
