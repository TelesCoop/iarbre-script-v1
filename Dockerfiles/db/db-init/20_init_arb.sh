#!/bin/bash
# Boostraping de la base de données ARB
# 

# Working Directory
cd /docker-entrypoint-initdb.d
# id => uid=1001230000(1001230000) gid=0(root) groups=1001230000
userid=$(id | cut -d'(' -f1 | cut -d'=' -f2)

echo "--------------------------------------------------------------------------"
echo " --> Boostraping de la base de donnees '$POSTGRES_DB'"
echo "     le repertoire est '$(pwd)'"
echo "--------------------------------------------------------------------------"
# Mettre ici le le schéma d'initailisation, les reprises de données, reéation de roles et grants, etc...
# psql -U $POSTGRES_USER -d $POSTGRES_DB -c "CREATE ROLE $userid"

psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/sql/30-create_tables.sql
psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/sql/40-insert_data.sql
psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/sql/50-insert_communes.sql
