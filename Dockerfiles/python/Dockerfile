##################################################################################
#  Taken from https://github.com/Toblerity/Fiona/issues/1063
#
# testing image installation in interactive way : 
#  - docker run -i -t alpine /bin/sh
##################################################################################

FROM debian:buster-slim

# Basic libs and install python3.7
RUN apt-get update && apt-get upgrade -y \
&& apt-get install -y procps wget python3.7 python3-pip gdal-bin libgdal-dev apt-utils \
&& apt-get clean \
apt-get -y install proj proj-dev && \
# https://stackoverflow.com/questions/70508775/error-could-not-build-wheels-for-pycairo-which-is-required-to-install-pyprojec
# apt-get install -y sox ffmpeg libcairo2 libcairo2-dev texlive-full && \
apt-get install -y libcairo2 libcairo2-dev && \
rm -rf /var/lib/apt/lists/*

# Setting some ENV variables
ENV CPLUS_INCLUDE_PATH="/usr/include/gdal"
ENV C_INCLUDE_PATH="/usr/include/gdal"
ENV PROJ_LIB="/usr/local/lib/python3.7/dist-packages/pyproj/proj_dir/share/proj"
ENV GDAL_DATA="/usr/local/lib/python3.7/dist-packages/fiona/gdal_data/"

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
COPY ./env.$NAMESPACE_ENV ./
# Launch calculation
CMD [ "python3", "./scripts/hello-world.py" ]

# 3. ####################################################
# FROM alpine:latest

# ENV LC_ALL=C.UTF-8
# ENV LANG=C.UTF-8
# ENV PROJ_DIR=/usr

# # Python installation stuff
# RUN apk add --update --no-cache python3 && \
# apk add --no-cache python3-dev py3-pip alpine-sdk && \
# apk add proj proj-dev && \
# apk add proj-util

# COPY ./scripts/requirements.txt requirements.txt
# RUN pip3 install --upgrade pip && \
# pip3 install --upgrade setuptools && \
# pip3 install --no-cache-dir -r requirements.txt

# # Add a non root user (OpenShift Requirements)
# RUN addgroup -S calquluser && \ 
# adduser -S calquluser -G calquluser -h /app && \
# chown calquluser:calquluser /app

# WORKDIR /app
# COPY --chown=calquluser:calquluser / /app

# USER calquluser

# COPY ./scripts ./
# COPY ./sql ./
# # COPY ./env.$NAMESPACE_ENV ./
# # Launch calculation
# CMD [ "python3", "./scripts/hello-world.py" ]

# 2. ####################################################
# FROM python:3-alpine

# WORKDIR /app

# RUN mkdir -p /usr/bin/proj && chmod 755 /usr/bin/proj
# ENV PROJ_DIR=/usr

# RUN apk add --no-cache build-base proj proj-dev
# RUN pip install --upgrade pip
# RUN pip install --user pyproj

# COPY ./scripts/requirements.txt requirements.txt
# RUN pip install --no-cache-dir -r requirements.txt

# COPY ./scripts ./
# COPY ./sql ./
# # COPY ./env.$NAMESPACE_ENV ./

# CMD [ "python3", "./scripts/hello-world.py" ]


# 1. ###################################################

# # FROM python:latest

# # WORKDIR /usr/src/app 
# WORKDIR /app 

# # https://github.com/phusion/baseimage-docker/issues/58
# RUN echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

# # clean and update sources
# RUN apt clean &&  apt update && apt install debconf-utils -qy

# RUN  apt install libgirepository1.0-dev -qy
# RUN  apt install proj-bin -qy
# RUN  pip install --upgrade pip

# # for pyproj dependency
# # RUN export PROJ_DIR=/usr/local
# # RUN export PROJ_WHEEL=true
# # RUN pip install pyproj

# COPY ./scripts/requirements.txt requirements.txt

# RUN pip install --no-cache-dir -r requirements.txt

# COPY ./scripts ./
# COPY ./sql ./
# # COPY ./env.$NAMESPACE_ENV ./

# RUN ls -l .

# CMD [ "python3", "./scripts/hello-world.py" ]





