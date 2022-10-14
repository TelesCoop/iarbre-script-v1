# ARB::Base de données postgis pour le calcul du calque de plantabilité

FROM postgis/postgis

# Create another dir for pgdata than /var/postgresql/data/
# see http://heidloff.net/article/deploying-postgres-on-openshift/

ENV PGDATA=/arb-data/database
# RUN mkdir arb-data
RUN groupadd non-root-postgres-group && \
useradd non-root-postgres-user --group non-root-postgres-group && \
mkdir -p arb-data/database && \
chown -R non-root-postgres-user:non-root-postgres-group /arb-data/database && \
chmod 777 /arb-data/database
USER non-root-postgres

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

# USER non-root-postgres
