#
# ARB::Base de données postgis pour le calcul du calque de plantabilité
#
FROM postgis/postgis:11-3.3-alpine

# Arguments
ARG NAMESPACE_ENV
ARG PGDATA="/arb-data/pgdata"
ARG HTTP_PROXY=""

ENV HTTP_PROXY=$HTTP_PROXY
ENV HTTPS_PROXY=$HTTP_PROXY
###---------------  LOCAL BUILD ONLY --------------------
# ENV POSTGRES_HOST_AUTH_METHOD=trust
###--------------- /LOCAL BUILD ONLY --------------------

USER root

ENV PGDATA=/arb-data/pgdata
RUN mkdir -p $PGDATA && \
chown -R postgres:0 /$PGDATA && \
chmod 777 /$PGDATA
# chmod -R g+rwx /$PGDATA ?? a tester ??

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

USER postgres