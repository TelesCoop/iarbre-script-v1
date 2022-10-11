# !/bin/bash
#  Script de test de l'environnement
############################################################
python3 main.py help
sleep 5

python3 main.py test
sleep 5

python3 main.py testDB
# Let's keep time to read logs if necessary before the pod is tarminated
sleep 300
