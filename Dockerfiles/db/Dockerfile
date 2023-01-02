#
# ARB::Base de données postgis pour le calcul du calque de plantabilité
#
FROM postgis/postgis:11-3.3-alpine

# Arguments
ARG NAMESPACE_ENV

USER root

# Install pgAdmin
RUN apk add --no-cache \
  py3-psycopg2 \
  py3-Flask \
  py3-flask-babel \
  py3-flask-login \
  py3-flask-openid \
  py3-flask-sqlalchemy \
  py3-flask-wtf \
  py3-itsdangerous \
  py3-markdown \
  py3-passlib \
  py3-pyrsistent \
  py3-sqlparse \
  py3-werkzeug \
  && apk add --no-cache --virtual .build-deps \
  py3-pip \
  && pip3 install --upgrade pip \
  && pip3 install pgadmin4==4.27 \
  && apk del .build-deps

ENV PGDATA=/arb-data/pgdata
RUN mkdir -p $PGDATA && \
chown -R postgres:0 /$PGDATA && \
chmod 777 /$PGDATA

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

USER postgres