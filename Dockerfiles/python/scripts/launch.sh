#!/bin/bash
################################################################################
# ARB : Lancement du recalcul des indices du calque de plantabilité.
################################################################################
alias python=python3
source .env

namespace_env=$1
DB_HOST=$2
DB_PORT=$3
DB_NAME=$4
DB_USER=$5

# GRID_SIZE=50
GRID_SIZE=5

declare -A LISTE_COMMUNES
LISTE_COMMUNES=( ["LYON-7EME"]="69387" ["LYON-8EME"]="69388" ["LYON-6EME"]="69386" ["LYON-4EME"]="69384" ["LYON-9EME"]="69389" ["LYON-1ER"]="69381" ["LYON-3EME"]="69383" ["LYON-5EME"]="69385" ["LYON-2EME"]="69382" ["FONTAINES-SAINT-MARTIN"]="69087" ["JONAGE"]="69279" ["CAILLOUX-SUR-FONTAINES"]="69033" ["VERNAISON"]="69260" ["SAINT-GERMAIN-AU-MONT-D'OR"]="69207" ["DECINES-CHARPIEU"]="69275" ["GENAY"]="69278" ["VILLEURBANNE"]="69266" ["VENISSIEUX"]="69259" ["FONTAINES-SUR-SAONE"]="69088" ["IRIGNY"]="69100" ["SAINT-GENIS-LAVAL"]="69204" ["SATHONAY-VILLAGE"]="69293" ["GIVORS"]="69091" ["GRIGNY"]="69096" ["LISSIEU"]="69117" ["CHASSIEU"]="69271" ["CHARLY"]="69046" ["VAULX-EN-VELIN"]="69256" ["SAINT-PRIEST"]="69290" ["SOLAIZE"]="69296" ["SAINT-FONS"]="69199" ["MIONS"]="69283" ["SATHONAY-CAMP"]="69292" ["FEYZIN"]="69276" ["OULLINS"]="69149" ["MEYZIEU"]="69282" ["CHAMPAGNE-AU-MONT-D'OR"]="69040" ["ECULLY"]="69081" ["SAINT-ROMAIN-AU-MONT-D'OR"]="69233" ["SAINT-CYR-AU-MONT-D'OR"]="69191" ["COLLONGES-AU-MONT-D'OR"]="69063" ["CRAPONNE"]="69069" ["POLEYMIEUX-AU-MONT-D'OR"]="69153" ["LIMONEST"]="69116" ["SAINT-GENIS-LES-OLLIERES"]="69205" ["SAINT-DIDIER-AU-MONT-D'OR"]="69194" ["DARDILLY"]="69072" ["FRANCHEVILLE"]="69089" ["SAINTE-FOY-LESLYON"]="69202" ["MARCY-L'ETOILE"]="69127" ["BRON"]="69029" ["QUINCIEUX"]="69163" ["RILLIEUX-LA-PAPE"]="69286" ["CORBAS"]="69273" ["PIERRE-BENITE"]="69152" ["COUZON-AU-MONT-D'OR"]="69068" ["ALBIGNY-SUR-SAONE"]="69003" ["LA-TOUR-DE-SALVAGNY"]="69250" ["TASSIN-LA-DEMI-LUNE"]="69244" ["CHARBONNIERES-LES-BAINS"]="69044" ["FLEURIEU-SUR-SAONE"]="69085" ["LA-MULATIERE"]="69142" ["NEUVILLE-SUR-SAONE"]="69143" ["CURIS-AU-MONT-D'OR"]="69071" ["ROCHETAILLEE-SUR-SAONE"]="69168" ["MONTANAY"]="69284" ["CALUIRE-ET-CUIRE"]="69034" )
# LISTE_COMMUNES=( ["ROCHETAILLEE-SUR-SAONE"]="69168" )

DATA_REPO="https://forge.grandlyon.com/erasme/data-recalcul-calque.git"

scripts_dir="/app/scripts"
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

comment "Python parameters : "
python3 main.py displayEnv
 
stage "InitDatas"
python3 main.py initDatas
check

stage "Compute Factors & Indices"
for NOM_COMMUNE in $( echo "${!LISTE_COMMUNES[@]}" | tr ' ' '\n' | sort ); do
    CODE_INSEE=${LISTE_COMMUNES[$NOM_COMMUNE]}
    stage "Compute Factors : $NOM_COMMUNE"
    python3 main.py computeFactors $CODE_INSEE
    check

done

stage "Compute Indices"
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
