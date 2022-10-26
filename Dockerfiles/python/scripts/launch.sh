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

stage "Launch Initializations..."
cd $scripts_dir
comment "Init communes"
python3 main.py initCommunes
comment "Init Grid"
python3 main.py initGrid 5
comment "InitDatas"
python3 main.py initDatas


stage "Launch Computations..."

comment "Computing factors"
python3 main.py computeFactors # Possibly Multiprocessing task, Should have a list of townships

comment "Computing Indices"
python3 main.py computeIndices

# Launching everything, it is possible to give a list of townships
# python3 main.py computeAll

stage "Sleeping a while for debug purpose..."
sleep 3600