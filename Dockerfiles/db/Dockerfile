#
# ARB::Base de données postgis pour le calcul du calque de plantabilité
#
FROM postgis/postgis:11-3.3-alpine

# Arguments
ARG NAMESPACE_ENV

USER root

ENV PGDATA=/arb-data/pgdata
RUN mkdir -p $PGDATA && \
chown -R postgres:0 /$PGDATA && \
chmod 777 /$PGDATA

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

USER postgres