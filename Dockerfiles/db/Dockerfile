# ARB::Base de données postgis pour le calcul du calque de plantabilité

FROM postgis/postgis

# Openshift Stuff
# Set labels used in OpenShift to describe the builder images.
LABEL io.k8s.description="base de données relationnelle PostgreSQL \
avec support des données géographiques (PostGIS). Base temporaire  \
utilisée pour le calcul du calque de plantabilité, \
puis ses résultats sont ensuite exportés, et enfin elle est détruite." \
      io.k8s.display-name="PostgreSQL 10 avec extension PostGIS" \
      io.openshift.tags="sql,postgresql,postgis,arb"

# Create another dir for pgdata than /var/postgresql/data/
# see http://heidloff.net/article/deploying-postgres-on-openshift/

ENV PGDATA=/var/lib/postgresql/data/pgdata
RUN groupadd non-root-postgres-group && \
useradd non-root-postgres-user --group non-root-postgres-group && \
mkdir -p "$PGDATA" && \
chown -R non-root-postgres-user:non-root-postgres-user "$PGDATA" && \
chmod 777 "$PGDATA" && \
chown -R non-root-postgres-user:non-root-postgres-group /docker-entrypoint-initdb.d/ && \
mkdir -p /var/run/postgresql && chown -R non-root-postgres-user:non-root-postgres-user /var/run/postgresql && \ 
chmod 2777 /var/run/postgresql

# Entry point. 
# At startup, the Postgis Docker Image automatically runs .sh script and .sal scripts which are in this directory.
# See Dockerfiles/db/db-init/20_init_arb.sh script for more information.
COPY ./db-init/ /docker-entrypoint-initdb.d/

USER non-root-postgres
