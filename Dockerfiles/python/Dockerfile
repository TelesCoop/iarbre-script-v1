##################################################################################
#  Taken from https://github.com/Toblerity/Fiona/issues/1063
##################################################################################
FROM debian:10

# Set the working directory to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
COPY ./scripts/requirements.txt .

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


# Pip & Python
RUN python3 -m pip install --no-cache-dir --upgrade pip \
&& pip install --no-cache-dir --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==`gdal-config --version` \
&& pip install --no-cache-dir --ignore-installed PyYAML \
# https://stackoverflow.com/questions/70508775/error-could-not-build-wheels-for-pycairo-which-is-required-to-install-pyprojec
&& pip install --no-cache-dir manimlib \
&& pip install --no-cache-dir manimce 
RUN pip install rtree \
&& pip install --no-cache-dir --upgrade -r ./requirements.txt

# Add a non root user (OpenShift Requirements)
RUN addgroup calquluser && \ 
useradd calquluser -g calquluser --home /app && \
mkdir -p /app && \ 
mkdir -p /app/logs && \
mkdir -p /app/tmp && \
chown -R calquluser:calquluser /app && \
chmod 777 /app/logs /app/tmp /app 

# WORKDIR /app

USER calquluser
# Add app 
COPY --chown=calquluser:calquluser ./scripts/*.py ./
COPY --chown=calquluser:calquluser ./scripts/*.sh ./
COPY --chown=calquluser:calquluser ./sql ./
COPY --chown=calquluser:calquluser .env ./

RUN chmod 755 /app/*.sh

# Getting some Args and Setting some ENV variables
ENV CPLUS_INCLUDE_PATH="/usr/include/gdal"
ENV C_INCLUDE_PATH="/usr/include/gdal"
ENV PROJ_LIB="/usr/local/lib/python3.7/dist-packages/fiona/proj_data/"
ENV GDAL_DATA="/usr/local/lib/python3.7/dist-packages/fiona/gdal_data/"
# Debug verbosity
ENV PROJ_DEBUG=3

CMD [ "/bin/bash" ]
