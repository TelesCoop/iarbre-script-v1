#!/bin/bash
################################################################################
# ARB : Lancement du recalcul des indices du calque de plantabilité.
################################################################################

# Liste des commmunes : 
# ----+----------------------------+-------
#  id |          libelle           | insee 
# ----+----------------------------+-------
#   1 | LYON 7EME                  | 69387
#   2 | LYON 8EME                  | 69388
#   3 | LYON 6EME                  | 69386
#   4 | LYON 4EME                  | 69384
#   5 | LYON 9EME                  | 69389
#   6 | LYON 1ER                   | 69381
#   7 | LYON 3EME                  | 69383
#   8 | LYON 5EME                  | 69385
#   9 | LYON 2EME                  | 69382
#  10 | FONTAINES-SAINT-MARTIN     | 69087
#  11 | JONAGE                     | 69279
#  12 | CAILLOUX-SUR-FONTAINES     | 69033
#  13 | VERNAISON                  | 69260
#  14 | SAINT-GERMAIN-AU-MONT-D'OR | 69207
#  15 | DECINES-CHARPIEU           | 69275  <-
#  16 | GENAY                      | 69278
#  17 | VILLEURBANNE               | 69266
#  18 | VENISSIEUX                 | 69259
#  19 | FONTAINES-SUR-SAONE        | 69088
#  20 | IRIGNY                     | 69100
#  21 | SAINT-GENIS-LAVAL          | 69204
#  22 | SATHONAY-VILLAGE           | 69293
#  23 | GIVORS                     | 69091
#  24 | GRIGNY                     | 69096
#  25 | LISSIEU                    | 69117
#  26 | CHASSIEU                   | 69271
#  27 | CHARLY                     | 69046
#  28 | VAULX-EN-VELIN             | 69256
#  29 | SAINT-PRIEST               | 69290
#  30 | SOLAIZE                    | 69296
#  31 | SAINT-FONS                 | 69199
#  32 | MIONS                      | 69283
#  33 | SATHONAY-CAMP              | 69292
#  34 | FEYZIN                     | 69276
#  35 | OULLINS                    | 69149
#  36 | MEYZIEU                    | 69282
#  37 | CHAMPAGNE-AU-MONT-D'OR     | 69040
#  38 | ECULLY                     | 69081
#  39 | SAINT-ROMAIN-AU-MONT-D'OR  | 69233
#  40 | SAINT-CYR-AU-MONT-D'OR     | 69191
#  41 | COLLONGES-AU-MONT-D'OR     | 69063
#  42 | CRAPONNE                   | 69069
#  43 | POLEYMIEUX-AU-MONT-D'OR    | 69153
#  44 | LIMONEST                   | 69116
#  45 | SAINT-GENIS-LES-OLLIERES   | 69205
#  46 | SAINT-DIDIER-AU-MONT-D'OR  | 69194
#  47 | DARDILLY                   | 69072
#  48 | FRANCHEVILLE               | 69089
#  49 | SAINTE-FOY-LES-LYON        | 69202
#  50 | MARCY-L'ETOILE             | 69127
#  51 | BRON                       | 69029
#  52 | QUINCIEUX                  | 69163
#  53 | RILLIEUX-LA-PAPE           | 69286
#  54 | CORBAS                     | 69273
#  55 | PIERRE-BENITE              | 69152
#  56 | COUZON-AU-MONT-D'OR        | 69068
#  57 | ALBIGNY-SUR-SAONE          | 69003
#  58 | LA TOUR-DE-SALVAGNY        | 69250
#  59 | TASSIN-LA-DEMI-LUNE        | 69244
#  60 | CHARBONNIERES-LES-BAINS    | 69044
#  61 | FLEURIEU-SUR-SAONE         | 69085
#  62 | LA MULATIERE               | 69142
#  63 | NEUVILLE-SUR-SAONE         | 69143
#  64 | CURIS-AU-MONT-D'OR         | 69071
#  65 | ROCHETAILLEE-SUR-SAONE     | 69168
#  66 | MONTANAY                   | 69284
#  67 | CALUIRE-ET-CUIRE           | 69034

alias python=python3

namespace_env=$1
DB_HOST=$2
DB_PORT=$3
DB_NAME=$4
DB_USER=$5

GRID_SIZE=25
LIST_CODE_INSEE="69387 69388 69386 69384 69389 69381 69383 69385 69382 69087 69279 69033 69260 69207 69275 69278 69266 69259 69088 69100 69204 69293 69091 69096 69117 69271 69046 69256 69290 69296 69199 69283 69292 69276 69149 69282 69040 69081 69233 69191 69063 69069 69153 69116 69205 69194 69072 69089 69202 69127 69029 69163 69286 69273 69152 69068 69003 69250 69244 69044 69085 69142 69143 69071 69168 69284 69034"
CODE_INSEE= # Décine-Charpieu 69275


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

#comment "Init Grid $GRID_SIZE $CODE_INSEE"
#python3 main.py initGrid $GRID_SIZE $CODE_INSEE
#check
stage "INIT GRID"
for $CODE_INSEE in $LIST_CODE_INSEE
do
  stage "Commune $CODE_INSEE"
  python3 main.py initGrid $GRID_SIZE $CODE_INSEE
  #check
done
 
stage "InitDatas"
#python3 main.py initDatas $CODE_INSEE
#check
for $CODE_INSEE in $LIST_CODE_INSEE
do
  stage "Commune $CODE_INSEE"
  python3 main.py initDatas $CODE_INSEE
  #check
done

for $CODE_INSEE in $LIST_CODE_INSEE
do
  stage "Commune $CODE_INSEE"
  python3 main.py computeFactors $CODE_INSEE
  #check
done

#stage "Launch Computations..."
#comment "Computing factors $CODE_INSEE"
#python3 main.py computeFactors $CODE_INSEE # Possibly Multiprocessing task, Should have a list of townships
#check 

for $CODE_INSEE in $LIST_CODE_INSEE
do
  stage "Commune $CODE_INSEE"
  python3 main.py computeIndices $CODE_INSEE
  #check
done

#comment "Computing Indices $CODE_INSEE"
#python3 main.py computeIndices $CODE_INSEE 
#check

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
