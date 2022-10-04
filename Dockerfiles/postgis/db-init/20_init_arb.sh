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
echo "User : $POSTGRES_USER"
echo " Database : $POSTGRES_DB"
# psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'CREATE ROLE postgres'
# psql -U $POSTGRES_USER -d $POSTGRES_DB -f /docker-entrypoint-initdb.d/backups/BACKUP_SCHEMA.sql
# psql -U $POSTGRES_USER -d $POSTGRES_DB -c 'ALTER TABLE prod_immo.operation ADD etat_chargement varchar NULL;'
echo "--------------------------------------------------------------------------"
echo "     Base de donnees ARB prete."
echo "--------------------------------------------------------------------------"
