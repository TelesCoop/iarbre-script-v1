# ARB::Base de données postgis pour le calcul du calque de plantabilité

FROM postgis/postgis

ENV PGDATA=/arb-data/database
# Create another dir for pgdata than /var/postgresql/data/
# see http://heidloff.net/article/deploying-postgres-on-openshift/

# RUN mkdir arb-data
# RUN groupadd non-root-postgres-group
# RUN useradd non-root-postgres-user --group non-root-postgres-group
# RUN chown -R non-root-postgres-user:non-root-postgres-group /arb-data
# RUN chmod 777 /arb-data
# USER non-root-postgres

# Entry point. 
COPY ./db-init/ /docker-entrypoint-initdb.d/

# USER non-root-postgres
