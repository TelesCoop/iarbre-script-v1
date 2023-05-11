#!/bin/bash
################################################################################
# ARB : Lancement du recalcul des indices du calque de plantabilité.
################################################################################
alias python=python3
source .env

action=$1
namespace_env=$2
DB_HOST=$3
DB_PORT=$4
DB_NAME=$5
DB_USER=$6

GRID_SIZE=5

declare -A LISTE_COMMUNES
LISTE_COMMUNES=( ["ALBIGNY-SUR-SAONE"]="69003" ["BRON"]="69029" ["CAILLOUX-SUR-FONTAINES"]="69033" ["CALUIRE-ET-CUIRE"]="69034" ["CHAMPAGNE-AU-MONT-D'OR"]="69040" ["CHARBONNIERES-LES-BAINS"]="69044" ["CHARLY"]="69046" ["CHASSIEU"]="69271" ["COLLONGES-AU-MONT-D'OR"]="69063" ["CORBAS"]="69273" ["COUZON-AU-MONT-D'OR"]="69068" ["CRAPONNE"]="69069" ["CURIS-AU-MONT-D'OR"]="69071" ["DARDILLY"]="69072" ["DECINES-CHARPIEU"]="69275" ["ECULLY"]="69081" ["FEYZIN"]="69276" ["FLEURIEU-SUR-SAONE"]="69085" ["FONTAINES-SAINT-MARTIN"]="69087" ["FONTAINES-SUR-SAONE"]="69088" ["FRANCHEVILLE"]="69089" ["GENAY"]="69278" ["GIVORS"]="69091" ["GRIGNY"]="69096" ["IRIGNY"]="69100" ["JONAGE"]="69279" ["LA-MULATIERE"]="69142" ["LA-TOUR-DE-SALVAGNY"]="69250" ["LIMONEST"]="69116" ["LISSIEU"]="69117" ["LYON-1ER"]="69381" ["LYON-2EME"]="69382" ["LYON-3EME"]="69383" ["LYON-4EME"]="69384" ["LYON-5EME"]="69385" ["LYON-6EME"]="69386" ["LYON-7EME"]="69387" ["LYON-8EME"]="69388" ["LYON-9EME"]="69389" ["MARCY-L'ETOILE"]="69127" ["MEYZIEU"]="69282" ["MIONS"]="69283" ["MONTANAY"]="69284" ["NEUVILLE-SUR-SAONE"]="69143" ["OULLINS"]="69149" ["PIERRE-BENITE"]="69152" ["POLEYMIEUX-AU-MONT-D'OR"]="69153" ["QUINCIEUX"]="69163" ["RILLIEUX-LA-PAPE"]="69286" ["ROCHETAILLEE-SUR-SAONE"]="69168" ["SAINT-CYR-AU-MONT-D'OR"]="69191" ["SAINT-DIDIER-AU-MONT-D'OR"]="69194" ["SAINTE-FOY-LESLYON"]="69202" ["SAINT-FONS"]="69199" ["SAINT-GENIS-LAVAL"]="69204" ["SAINT-GENIS-LES-OLLIERES"]="69205" ["SAINT-GERMAIN-AU-MONT-D'OR"]="69207" ["SAINT-PRIEST"]="69290" ["SAINT-ROMAIN-AU-MONT-D'OR"]="69233" ["SATHONAY-CAMP"]="69292" ["SATHONAY-VILLAGE"]="69293" ["SOLAIZE"]="69296" ["TASSIN-LA-DEMI-LUNE"]="69244" ["VAULX-EN-VELIN"]="69256" ["VENISSIEUX"]="69259" ["VERNAISON"]="69260" ["VILLEURBANNE"]="69266"  )
# LISTE_COMMUNES=( ["ROCHETAILLEE-SUR-SAONE"]="69168" )

scripts_dir="/app"
data_dir="/arb-data/source-files/data-recalcul-calque"
backup_dir="/arb-data/generated-files"
stage=1
line="\e[39m-----------------------------------------------"
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

# Usage
usage () {
  comment "$0 [cleanup|init-grid|init-datas|compute-factors|compute-indices|dump-datas|all] $namespace_env $DB_HOST $DB_PORT $DB_NAME $DB_USER"
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
comment "command line is '$0 $action $namespace_env $DB_HOST $DB_PORT $DB_NAME $DB_USER'"

comment "psql version..."
psql -V
check

comment "Postgres server says : "
pg_isready -d $DB_NAME -h $DB_HOST -p $DB_PORT -U $DB_USER
check 

comment "Python parameters : "
python3 main.py displayEnv
 
comment "Checking action to do : "
case "$action" in 
  "init-grid"|"init-datas"|"compute-factors"|"compute-indices"|"dump-datas"|"all" )
    comment "Action is '$action'."
    check
  ;;
  "cleanup")
    comment "Cleanup action : all the progress tables will be truncated..."  
    sed -i "s/ENABLE_TRUNCATE=False/ENABLE_TRUNCATE=True/g" .env
  ;;
  *)
    comment "Actiion parameter is not recognized."
    usage
    exit 2
  ;;
esac

if [ $action == "cleanup"  ] || [ $action == "all"  ]; then
  stage "cleanup"
  # this cleans up the progress tables
  python3 main.py cleanup
  check
  # clean sources files
  rm -rf $data_dir/*
fi

if [ $action == "init-grid"  ] || [ $action == "all"  ]; then
  # Do InitGrid, township by town ship to avoid memory overflow
  stage "init-grid"
  for NOM_COMMUNE in $( echo "${!LISTE_COMMUNES[@]}" | tr ' ' '\n' | sort ); do
      stage "Init Grid : $NOM_COMMUNE"
      CODE_INSEE=${LISTE_COMMUNES[$NOM_COMMUNE]}
      python3 main.py initGrid $GRID_SIZE $CODE_INSEE
    check
  done
fi

if [ $action == "init-datas"  ] || [ $action == "all"  ]; then
  stage "init-datas"
  python3 main.py initDatas
  check
fi

if [ $action == "compute-factors"  ] || [ $action == "all"  ]; then
  stage "Compute Factors"
  for NOM_COMMUNE in $( echo "${!LISTE_COMMUNES[@]}" | tr ' ' '\n' | sort ); do
      CODE_INSEE=${LISTE_COMMUNES[$NOM_COMMUNE]}
      stage "Compute Factors : $NOM_COMMUNE - $CODE_INSEE"
      python3 main.py computeFactors $CODE_INSEE
      check
  done
fi

if [ $action == "compute-indices"  ] || [ $action == "all"  ]; then
  stage "Compute Indices"
  python3 main.py computeIndices
  check
fi

# Launching everything, it is possible to give a list of townships
# python3 main.py computeAll

if [ $action == "dump-datas"  ] || [ $action == "all"  ]; then
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

  # stage "Uploading archive in repo with tag $archive_version"
  # comment "Upload to file server 'Geo'"

  stage "Cleanup backup dir '$backup_dir'"
  comment "old sql files"
  find $backup_dir -name "*.sql" -exec rm -f {} \;
  check

  comment "old tgz files"
  find $backup_dir -name "*.tgz" -mtime +5 -exec rm -f {} \;
  check
fi

stage "End of script."
exit 0
