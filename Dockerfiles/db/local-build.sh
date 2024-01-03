#!/bin/bash

export POSTGRES_USER=calqul
export POSTGRES_PASSWORD=calqul
export POSTGRES_DB=calque_planta_temp
export POSTGRES_SCHEMA=base

export POSTGRES_PASSWORD=calqul
export POSTGRES_HOST_AUTH_METHOD=trust

docker build -t postgis . \
--build-arg NAMESPACE_ENV=d01 \
--build-arg PGDATA=../arb-data/pgdata
