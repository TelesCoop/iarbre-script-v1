##################################################################################
#  Taken from https://github.com/Toblerity/Fiona/issues/1063
##################################################################################
FROM debian:buster-slim

# Getting some Args and Setting some ENV variables
ARG NAMESPACE_ENV
ENV CPLUS_INCLUDE_PATH="/usr/include/gdal"
ENV C_INCLUDE_PATH="/usr/include/gdal"
ENV PROJ_LIB="/usr/local/lib/python3.7/dist-packages/pyproj/proj_dir/share/proj"
ENV GDAL_DATA="/usr/local/lib/python3.7/dist-packages/fiona/gdal_data/"

# Basic libs and install python3.7
RUN apt-get update && apt-get upgrade -y \
&& apt-get install -y procps wget python3.7 python3-pip gdal-bin libgdal-dev apt-utils \
&& apt-get clean \
apt-get -y install proj proj-dev && \
# https://stackoverflow.com/questions/70508775/error-could-not-build-wheels-for-pycairo-which-is-required-to-install-pyprojec
apt-get install -y libcairo2 libcairo2-dev && \
rm -rf /var/lib/apt/lists/*

COPY ./scripts/requirements.txt requirements.txt

# Pip
RUN python3 -m pip install --no-cache-dir --upgrade pip \
&& pip install --no-cache-dir --global-option=build_ext --global-option="-I/usr/include/gdal" GDAL==`gdal-config --version` \
&& pip install --no-cache-dir --ignore-installed PyYAML \
# https://stackoverflow.com/questions/70508775/error-could-not-build-wheels-for-pycairo-which-is-required-to-install-pyprojec
&& pip install --no-cache-dir manimlib \
&& pip install --no-cache-dir manimce \
# 
&& pip install --no-cache-dir --upgrade -r requirements.txt

# Add a non root user (OpenShift Requirements)
RUN addgroup calquluser && \ 
useradd calquluser -g calquluser --home /app && \
mkdir -p /app && \ 
chown calquluser:calquluser /app

WORKDIR /app
COPY --chown=calquluser:calquluser / /app

USER calquluser

COPY ./scripts ./
COPY ./sql ./

# Launch calculation
# CMD [ "python3", "./scripts/hello-world.py" ]
# CMD [ "/bin/bash", "./scripts/launch.sh" ]
# CMD [ "python3", "./scripts/main.py 5 69266" ]

CMD [ "/bin/bash" ]
