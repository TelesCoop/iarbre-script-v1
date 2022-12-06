##################################################################################
#  Taken from https://github.com/Toblerity/Fiona/issues/1063
##################################################################################
FROM debian:buster-slim

# Arguments
ARG NAMESPACE_ENV
ARG DB_HOST_ENV
ARG DB_PORT_ENV
ARG DB_NAME_ENV
ARG DB_USER_ENV

# Getting some Args and Setting some ENV variables
ENV CPLUS_INCLUDE_PATH="/usr/include/gdal"
ENV C_INCLUDE_PATH="/usr/include/gdal"
ENV PROJ_LIB="/usr/local/lib/python3.7/dist-packages/pyproj/proj_dir/share/proj"
ENV GDAL_DATA="/usr/local/lib/python3.7/dist-packages/fiona/gdal_data/"

ENV NS_ENV=$NAMESPACE_ENV
ENV DB_HOST="$DB_HOST_ENV-$NAMESPACE_ENV"
ENV DB_PORT=$DB_PORT_ENV
ENV DB_NAME=$DB_NAME_ENV
ENV DB_USER=$DB_USER_ENV

# Basic libs and install python3.7
RUN apt-get update && apt-get upgrade -y \
&& apt-get install -y procps wget python3.7 python3-pip gdal-bin libgdal-dev apt-utils git \
&& apt-get clean \
apt-get -y install proj proj-dev && \
# https://stackoverflow.com/questions/70508775/error-could-not-build-wheels-for-pycairo-which-is-required-to-install-pyprojec
apt-get install -y libcairo2 libcairo2-dev && \
################################# Debug and diagnose tools #################################
apt-get install -qy apt-utils vim iputils-ping net-tools telnet curl && \
apt-get install -qy postgresql-client && \
############################################################################################
rm -rf /var/lib/apt/lists/*

COPY ./scripts/requirements.txt requirements.txt

# Pip
RUN python3 -m pip install --no-cache-dir --upgrade pip \
&& pip install --no-cache-dir --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==`gdal-config --version` \
&& pip install --no-cache-dir --ignore-installed PyYAML \
# https://stackoverflow.com/questions/70508775/error-could-not-build-wheels-for-pycairo-which-is-required-to-install-pyprojec
&& pip install --no-cache-dir manimlib \
&& pip install --no-cache-dir manimce \
&& pip install rtree pygeos \
&& pip install --no-cache-dir --upgrade -r requirements.txt

# Add a non root user (OpenShift Requirements)
RUN addgroup calquluser && \ 
useradd calquluser -g calquluser --home /app && \
mkdir -p /app && \ 
mkdir -p /app/logs && \
mkdir -p /app/tmp && \
chown -R calquluser:calquluser /app && \
chmod 777 /app/logs /app/tmp /app

WORKDIR /app
USER calquluser

# Add app 
COPY --chown=calquluser:calquluser ./scripts/*.py ./
COPY --chown=calquluser:calquluser ./scripts/*.sh ./
COPY --chown=calquluser:calquluser ./sql ./
COPY --chown=calquluser:calquluser .env ./

RUN chmod 755 ./*.sh

# Launch calculation
# Documentation : https://stackoverflow.com/questions/40454470/how-can-i-use-a-variable-inside-a-dockerfile-cmd
CMD [ "/bin/sh", "-c", "/app/launch.sh $NS_ENV $DB_HOST $DB_PORT $DB_NAME $DB_USER" ]