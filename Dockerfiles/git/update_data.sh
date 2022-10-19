#/bin/sh

mkdir -p /arb-data/source-files/data-recalcul-calque
cd /arb-data/source-files/data-recalcul-calque

# Init command does not do a 'git clone' beacause this is only working at the first init time.
# It does a 'git init + git remote add + git fetch + git checkout' instead.
# This works in every case.
[[ ! -d ".git" ]] && { 
    git init
    git remote add origin https://${GIT_USERNAME}:${GIT_PASSWORD}@forge.grandlyon.com/erasme/sources-recalcul-calque.git
}
git checkout .
git pull origin main
