# ARB::Base de données postgis pour le calcul du calque de plantabilité

FROM postgis/postgis

# Create another dir for pgdata than /var/postgresql/data/
# see http://heidloff.net/article/deploying-postgres-on-openshift/

ENV PGDATA=/var/lib/postgresql/data/pgdata
# RUN mkdir arb-data
RUN groupadd non-root-postgres-group && \
useradd non-root-postgres-user --group non-root-postgres-group && \
mkdir -p $PGDATA && \
chown -R non-root-postgres-user:non-root-postgres-group /$PGDATA && \
chmod 777 /$PGDATA
USER non-root-postgres

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

# USER non-root-postgres
