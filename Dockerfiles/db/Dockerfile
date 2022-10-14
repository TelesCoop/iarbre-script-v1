# ARB::Base de données postgis pour le calcul du calque de plantabilité

FROM postgis/postgis

# Create another dir for pgdata than /var/postgresql/data/
# see http://heidloff.net/article/deploying-postgres-on-openshift/
USER root

# ENV PGDATA=/var/lib/postgresql/data/pgdata
ENV PGDATA=/arb-data/pgdata
# RUN groupadd non-root-postgres-group && \
# useradd non-root-postgres-user --group non-root-postgres-group && \
RUN mkdir -p $PGDATA && \
chown -R postgres:0 /$PGDATA && \
chmod 777 /$PGDATA

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

# USER non-root-postgres

# FROM mdillon/postgis:10-alpine
# USER root
# RUN chown postgres:0 -R ${PGDATA}
# COPY ./db-init/ /docker-entrypoint-initdb.d/
USER postgres