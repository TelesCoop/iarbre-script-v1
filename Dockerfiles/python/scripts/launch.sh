#!/bin/bash
################################################################################
# ARB : Lancement du recalcul des indices du calque de plantabilité.
################################################################################
namespace_env=$1
DB_HOST=$2
DB_PORT=$3
DB_NAME=$4
DB_USER=$5

DATA_REPO="https://forge.grandlyon.com/erasme/data-recalcul-calque.git"

scripts_dir="/app"
data_dir="/arb-data/source-files/data-recalcul-calque"
backup_dir="/arb-data/generated-files"
stage=1
line="\e[39m-----------------------------------------------"
need_update=1
today=$(date +"%Y%m%d")
dump_name="calque-plantabilite-$namespace_env-$today"
tag="1.0" # @TODO : should be parametric from last commit on data repo.
archive_version="v$tag-$today"

################################################################################
# functions
################################################################################

#---------------------------------------------------------------
# Functions
#---------------------------------------------------------------
# Logging
stage () {
  echo -e $line
  echo -e "\e[96m$stage. $1\e[39m"
  echo -e $line
  stage=$((stage+1))
}

# Formatting log line
comment () {
  echo -e "\e[39m\t-> $1\e[39m"
}

# Check the last command return code (must be insterted just after the commend )
check () {
  if [ $? -eq 0 ]; then
   comment "\e[32mOk.\e[39m"
  else
   comment "\e[31mERROR !...\e[39m"
   exit 1
  fi;
}

# Overloading 'Exit' builtin function to get rid of 
# the running state every where in the code
exit () {
  error_code=$1
  echo "Exiting '$error_code'. (Sleeping for 1h for debug purpose)"
  sleep 3600
  builtin exit $error_code
}

#---------------------------------------------------------------
# M A I N
#---------------------------------------------------------------
stage "Launch ENV Initializations..."
cd $scripts_dir

# All the needed variables a given by parameter passing
comment "command line is '$0 $namespace_env $DB_HOST $DB_PORT $DB_NAME $DB_USER'"

comment "psql version..."
psql -V
check

comment "Postgres server says : "
pg_isready -d $DB_NAME -h $DB_HOST -p $DB_PORT -U $DB_USER
check

# stage "Launch Database Initializations..."
# comment "Init communes"
# python3 main.py initCommunes
# check

comment "Init Grid"
python3 main.py initGrid 5
check

comment "InitDatas"
python3 main.py initDatas
check

stage "Launch Computations..."
comment "Computing factors"
python3 main.py computeFactors # Possibly Multiprocessing task, Should have a list of townships
check 

comment "Computing Indices"
python3 main.py computeIndices
check

# Launching everything, it is possible to give a list of townships
# python3 main.py computeAll

stage "Dumping result database"
#
# Option "--no-password"  is set not to have to provide password by prompt.
# This requires the presnece of /root/.pgpass file (600 mode) with such a content : "hostname:port:database:username:password"
# https://stackoverflow.com/questions/50404041/pg-dumpall-without-prompting-password
#
comment "pg_dump -n base -h ${DB_HOST} -U ${DB_USER} --no-password --clean --if-exists --file=$backup_dir/$dump_name.sql ${DB_NAME}"
pg_dump -n base -h ${DB_HOST} -U ${DB_USER} --no-password --clean --if-exists --file=$backup_dir/$dump_name.sql ${DB_NAME}
check

comment "Commpressing dump as $dump_name.tgz"
tar cvzf $backup_dir/$dump_name.tgz $backup_dir/$dump_name.sql
check

stage "Uploading archive in repo with tag $archive_version"
comment "Upload to file server 'Geo'"

stage "Cleanup backup dir '$backup_dir'"
comment "old sql files"
find $backup_dir -name "*.sql" -exec rm -f {} \;
check

comment "old tgz files"
find $backup_dir -name "*.tgz" -mtime +5 -exec rm -f {} \;
check

stage "End of script."
exit 0
