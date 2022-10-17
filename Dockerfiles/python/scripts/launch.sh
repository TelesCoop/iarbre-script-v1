#!/bin/bash
################################################################################
# ARB : Lancement du recalcul des indices du calque de plantabilité.
################################################################################
DATA_REPO="https://forge.grandlyon.com/erasme/data-recalcul-calque.git"

scripts_dir="/app"
data_dir="/arb-data/source-files/data-recalcul-calque"
stage=1
line="\e[39m-----------------------------------------------"
need_update=1

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

################################################################################
mkdir -p $data_dir

stage "Check source files in $data_dir"
cd $data_dir

current_commit=$(git rev-parse --short HEAD)
if [ $? -eq 128 ]; then
  comment "Data repository is empty. Is this your first time, young Padawan ?"
  comment "Cloning repo, it can take a while..."
  cd ..
  git clone $DATA_REPO 
  need_update=0
else
  comment "Current commit is $current_commit"
  cd $data_dir
fi;

# Checking for update...
[ $(git rev-parse HEAD) = $(git ls-remote $(git rev-parse --abbrev-ref @{u} | sed 's/\// /g') | cut -f1) ] &&  need_update=0 ||  need_update=1

if [ $need_update -eq 0 ]; then
  # We are up to date
  comment "\e[32mData are up to date."
else
  comment "\e[93mNew version of source data is available !\e[39m"
  git pull origin main
  new_commit=$(git rev-parse --short HEAD)
  comment "New commit is : \e[93m'$new_commit'\e[39m"
  git diff --compact-summary $current_commit $new_commit
fi;

stage "Launch computations..."
cd $scripts_dir
comment "Init communes"
python3 main.py initCommunes

python3 main.py initGrid
python3 main.py initDatas

# Multiprocessing task
# python3 main.py computeFactors

# python3 main.py computeIndices

# Launching everything, it is possible to give a list of township
# python3 main.py computeAll

stage "Sleeping a while for debug purpose..."
sleep 300