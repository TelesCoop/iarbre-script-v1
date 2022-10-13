#!/bin/bash
# ARB : Lancement du recalcul des indices du calque de plantabilité.
#
# screen -dmS calque_metro python3 main.py computeAll 5

python3 main.py initCommunes

sleep 300

# python3 main.py initGrid
# python3 main.py initDatas

# Multiprocessing task
# python3 main.py computeFactors

# python3 main.py computeIndices

# Launching everything, it is possible to give a list of township
# python3 main.py computeAll