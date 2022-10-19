#/bin/sh

mkdir -p /arb-data/source-files/data-recalcul-calque
cd /arb-data/source-files/data-recalcul-calque
[[ ! -d ".git" ]] && { 
    git init
    git remote add origin https://${GIT_USERNAME}:${GIT_PASSWORD}@forge.grandlyon.com/erasme/sources-recalcul-calque.git
}
git checkout .
git pull origin main
