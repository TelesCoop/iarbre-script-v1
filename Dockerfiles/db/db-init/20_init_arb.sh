#!/bin/bash
# Boostraping de la base de données ARB
#

# Working Directory
cd /docker-entrypoint-initdb.d

echo "--------------------------------------------------------------------------"
echo " --> Boostraping de la base de donnees ARB"
echo "     le repertoire est '$(pwd)'"
echo "--------------------------------------------------------------------------"
# Mettre ici le le schéma d'initailisation, les reprises de données, reéation de roles et grants, etc...
echo "POSTGRES_DB=$POSTGRES_DB"         
echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD"   
echo "POSTGRES_PORT=$POSTGRES_PORT"       
echo "POSTGRES_SERVER=$POSTGRES_SERVER"     
echo "POSTGRES_USER=$POSTGRES_USER"       
echo "POSTGRES_SCHEMA=$POSTGRES_SCHEMA"  
psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/10-copy_base.sql
psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/create_tables.sql
psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/insert_data.sql
echo "--------------------------------------------------------------------------"
echo "     Base de donnees ARB prete."
echo "--------------------------------------------------------------------------"
