#!/usr/bin/env python3
# -*- coding: utf-8 -*-

# Header
__author__ = "Romain MATIAS"
__copyright__ = "Copyright 2022, EXO-DEV x ERASME, Métropole de Lyon"
__description__ = "Script de création d'un calque de plantabilité pour la Métropole de Lyon"
__credits__ = ["Romain MATIAS", "Natacha SALMERON", "Anthony ANGELOT"]
__date__ = "06/07/2022"
__license__ = "MIT"
__version__ = "1.0.0"
__maintainer__ = "Romain MATIAS"
__email__ = "contact@exo-dev.fr ou info@erasme.org"
__status__ = "Expérimentation"

# Import
import os
import sys
from subprocess import call
from time import sleep
from dotenv import load_dotenv
import logging

import geopandas as gp
import pandas as pd
import numpy as np
from shapely.ops import unary_union
from owslib.wfs import WebFeatureService
import multiprocessing as mp
from pathos.multiprocessing import ProcessingPool as Pool

from utils import *

# Global variables
DB_params = None
DB_schema = None
PythonLaunch = None
SourceDataPath = None
ENV_targetProj = None
RemoveTempFile = None
SkipExistingData = None
EnableTruncate = None
HttpProxy = None
Proxies = None

# ------------------------
#           DOC
# ------------------------
# Target projection used : EPSG:2154
# Métropole default projection : EPSG:4326 or EPSG:4171
# Villeurbanne inseeCode : 69266

def showDoc():
    script_doc = """
    Welcome to The master script of plantability !

    Args:
        initCommunes                                        Insert Communes in database from a geoJSON file path (with geometry and insee column)
        initGrid <gridSize: int, inseeCode: int>            Generate with the size defined and insert Grid in database merged from a bounding box
                                                            Can be launch on certain "communes" with one <inseeCode> or in all territory by default (no parameter)
        initDatas                                           Make treatments on the datas from informations in metadatas table
        computeFactors <inseeCode: int>                     Compute the factors area on each tile with database informations. 
                                                            Can be launch on certain "communes" with one <inseeCode> or in all territory by default (no parameter)
        computeIndices                                      Compute the plantability indices on each tile with database informations. 
        computeAll <gridSize: int, listInseeCode: int>      Generate all the plantability layer (launch all previous steps). 
                                                            List of inseeCode must be separated with comma (,) and without space (e.g. python main.py 5 69266,69388,69256) 
                                                            but you can launch treatments for only one commune (e.g. python main.py 5 69266)
        testDB                                              Test the connexion with DB parameters in .env file
        help                                                Show this documentation
    """
    
    print('# ' + '=' * 78)
    print('Author: ' + __author__)
    print('Copyright: ' + __copyright__)
    print('Description: ' + __description__)
    print('Credits: ' + ', '.join(__credits__))
    print('Date: ' + __date__)
    print('License: ' + __license__)
    print('Version: ' + __version__)
    print('Maintainer: ' + __maintainer__)
    print('Email: ' + __email__)
    print('Status: ' + __status__)
    print('# ' + '=' * 78)
    
    print(script_doc)

# ------------------------
#           TEST
# ------------------------

def test(communesArrayInput=None):
    # Init
    retcode = None

    print('communesArrayInput')
    print(communesArrayInput)
    print(type(communesArrayInput))

    # communesArrayCasted = communesArrayInput.split(',')
    # print('\n communesArrayCasted')
    # print(communesArrayCasted)
    # print(type(communesArrayCasted))

    multiProcessFactors(communesArrayInput)

    return retcode

def testDBConnexion():
    # Init
    retcode = None

    print(style.BLUE + "Try to connect to database : {} - {} \n".format(DB_params['host'], DB_params['database']), style.RESET)

    # Connect DB
    conn, cur = connectDB(DB_params)
    # Close DB
    closeDB(conn, cur)

    return_error_and_exit_job(-1)

# ------------------------
#         COMMUNES
# ------------------------

def initCommunes():
    # Log & timer
    debugLog(style.YELLOW, "Launch initialisation script of \'Communes\'", logging.INFO)
    communesTimer = startTimerLog('Init communes')

    # Column list for GDF & DB
    columnsListToDB = ('libelle', 'insee', 'geom_poly')
    columnsArrFromGeoJSON = ['nom', 'insee', 'geometry']

    # Check if Communes already exist in db
    communesCount = getCountfromDB(DB_params, DB_schema, 'communes')

    if communesCount > 0 :
        debugLog(style.YELLOW, "/!\ Some Communes already exist in database", logging.INFO)

        if SkipExistingData == 'True':
                # Log
                debugLog(style.MAGENTA, "Init communes was skipped", logging.INFO)
                endTimerLog(communesTimer)
                return

        # Ask user to clean table ?
        if EnableTruncate:
            while True:
                removeCommunesResponse = input("Do you want to clean the Communes table ? (y/n) : ")
                if removeCommunesResponse.lower() not in ('y', 'n'):
                    print(style.RED + "Sorry, wrong response... \n", style.RESET)
                else:
                    # Good response
                    break

            if removeCommunesResponse.lower() == 'y':
                # Connect DB
                conn, cur = connectDB(DB_params)

                # Truncate COMMUNES
                resetCommunesQuery = "TRUNCATE TABLE "+ DB_schema + ".communes RESTART IDENTITY; COMMIT;"
                cur.execute(resetCommunesQuery)
                debugLog(style.GREEN, "Successfully remove all communes", logging.INFO)

                # Close DB
                closeDB(conn, cur)
            else:
                debugLog(style.YELLOW, "Init communes was skipped", logging.INFO)
                endTimerLog(communesTimer)
                return

    # Log
    debugLog(style.YELLOW, "Table " + DB_schema + ".communes is ready", logging.INFO)

    # Get communes file path in .env and check if file exist
    if not os.path.isfile(SourceDataPath + "/communes_gl.geojson"):
        debugLog(style.RED, "File not found in " + SourceDataPath + "/communes_gl.geojson : Please verify your path and relaunch this script.", logging.ERROR)
        return_error_and_exit_job(-2)

    # Load geojson file in Dataframe
    communesGDF = createGDFfromGeoJSON(SourceDataPath + "/communes_gl.geojson")

    if communesGDF is not None:
        # Clean useless attribute
        communesGDF = communesGDF[columnsArrFromGeoJSON]
            
        # Check input projection and reproj in 2154
        communesGDF = checkAndReproj(communesGDF, ENV_targetProj)
        
        # Convert to WKT
        communesGDF = convertGeomToWKT(communesGDF)

        #  PGL - Debug
        with open('/app/tmp/dump_communes_gl.wkt', 'w') as f:
            f.write(str(communesGDF))
            f.close()
        # /PGL - Debug

        # Insert in DB
        insertGDFintoDB(DB_params, DB_schema, communesGDF, 'communes', columnsListToDB)

    # Log end script
    debugLog(style.YELLOW, "End initialisation of \'Communes\'", logging.INFO)
    endTimerLog(communesTimer)

# ------------------------
#           GRID
# ------------------------

def initGrid(gridSize=30, inseeCode=None):
    # Log & Timer
    logInseeSuffix = ''
    if inseeCode:
        logInseeSuffix = "and with inseeCode {}".format(inseeCode)
    debugLog(style.YELLOW, "Launch initialisation script of \'Grid\' with size {}x{} {}".format(gridSize, gridSize, logInseeSuffix), logging.INFO)
    gridTimer = startTimerLog('Generate Grid')

    # Check tiles length (with insee filter)
    tilesInseeFilter = None
    if inseeCode:
        tilesInseeFilter = "insee = '" + str(inseeCode) + "'"
    tilesCount = getCountfromDB(DB_params, DB_schema, 'tiles', tilesInseeFilter)

    # Check for drop Tiles
    if tilesCount > 0:
        logInseeSuffix = ''
        if inseeCode:
            logInseeSuffix = "for inseeCode {}".format(inseeCode)
        debugLog(style.YELLOW, "/!\ Some Tiles already exist in database {}".format(logInseeSuffix), logging.INFO)

        if SkipExistingData == 'True':
            # Log
            debugLog(style.MAGENTA, "Init tiles was skipped {}".format(logInseeSuffix), logging.INFO)
            endTimerLog(gridTimer)
            return

        # Ask user to clean table ?
        if EnableTruncate:
            # while True:
            #     removeTilesResponse = input("Do you want to clean the Tiles table ? (y/n) : ")
            #     if removeTilesResponse.lower() not in ('y', 'n'):
            #         print(style.RED + "Sorry, wrong response... \n", style.RESET)
            #     else:
            #         # Good response
            #         break

            # if removeTilesResponse.lower() == 'y':
            # Connect DB
            conn, cur = connectDB(DB_params)

            # Clean tiles
            resetTilesQuery = "TRUNCATE TABLE " + DB_schema + ".tiles RESTART IDENTITY; COMMIT;"
            cur.execute(resetTilesQuery)
            debugLog(style.GREEN, "Successfully remove all tiles", logging.INFO)

            # Close DB
            closeDB(conn, cur)

    # Log
    debugLog(style.YELLOW, "Table " + DB_schema + ".tiles is ready", logging.INFO)

    # Check communes length
    communeFilter = None
    if inseeCode:
        communeFilter = "insee = '" + str(inseeCode) + "'"
    communesCount = getCountfromDB(DB_params, DB_schema, 'communes', communeFilter)

    if communesCount > 0:
        debugLog(style.YELLOW, "Table " + DB_schema + ".communes is ready", logging.INFO)
    else:
        debugLog(style.RED, "There is no communes to merge with the Grid. Please launch initCommunes first", logging.INFO)
        return_error_and_exit_job(-3)

    # Get Communes data
    query = "SELECT insee, geom_poly as geom FROM " + DB_schema + ".communes"
    if inseeCode:
        query = query + " WHERE " + communeFilter
    
    communesGDF = getGDFfromDB(DB_params, query, ENV_targetProj)

    # Create Grid
    gridGDF = createGridFromDF(communesGDF, gridSize)

    # Convert Grid into WKT
    wktGrid = convertGeomToWKT(gridGDF)
    
    # Grid column list
    columnsListToDB = ('geom_poly', 'insee')

    # Insert grid init
    insertGDFintoDB(DB_params, DB_schema, wktGrid, 'tiles', columnsListToDB)

    # End timer
    endTimerLog(gridTimer)
    
    # End Communes script
    debugLog(style.YELLOW, "End initialisation of \'Grid\'", logging.INFO)

# ------------------------
#      PROCESS DATA
# ------------------------

def initDatas():
    # Log & timer
    debugLog(style.YELLOW, "Launch initialisation script of \'Datas\'", logging.INFO)
    currInitDatasTimer = startTimerLog('InitDatas process')

    # Check length of metadatas
    metaDataCount = getCountfromDB(DB_params, DB_schema, 'metadatas')
    if metaDataCount < 1:
        debugLog(style.RED, "Not metadatas was found in database. Please relaunch this script after inserting one", logging.ERROR)
        return_error_and_exit_job(-3)
    
    # Get all MetaData
    metaQuery = "SELECT * FROM " + DB_schema + ".metadatas ORDER BY id"
    metaDatas = getDatafromDB(DB_params, metaQuery)

    # Convert dict results to JSON
    jsonMD = json.loads(metaDatas)

    # Loop in result
    for currMData in jsonMD:
        # Init var
        currMDataID = currMData['id']
        currMDataName = currMData['name']
        currMDataListScript = currMData['script_path']
        currMDataListFactors = currMData['factors_list']

        # Log & timer
        debugLog(style.YELLOW, 'Begin process for current metadata \'' + currMDataName + '\'', logging.INFO)
        currMDTimer = startTimerLog(currMDataName + ' process')

        # Check existing data for this metadata
        qFilter = 'id_metadata = ' + str(currMDataID)
        currMDDataCount = getCountfromDB(DB_params, DB_schema, 'datas', qFilter)
        
        # Check count for drop Data
        if currMDDataCount > 0:
            debugLog(style.YELLOW, "/!\ Some datas already exist for this metadata in database. Analyze each factor datas...", logging.INFO)

            factorCountMissing = False
            for currMDFactor in currMDataListFactors:
                # Get count data for factor in this MD
                factorFilter = 'id_factor = ' + str(currMDFactor)
                currFactorDataCount = getCountfromDB(DB_params, DB_schema, 'datas', factorFilter)

                if currFactorDataCount == 0:
                    factorCountMissing = True

            # Skip if env variable is enable and all factors have datas
            if not factorCountMissing and SkipExistingData == 'True':
                # Log
                debugLog(style.MAGENTA, "Current metadata \'" + currMDataName + "\' was skipped", logging.INFO)
                # End timer
                endTimerLog(currMDTimer)
                # Skip this item in loop
                continue

            # Ask user to clean table ?
            if EnableTruncate:
                # while True:
                #     removeDataResponse = input("Do you want to clean those data ? (y/n) : ")
                #     if removeDataResponse.lower() not in ('y', 'n'):
                #         print(style.RED + "Sorry, wrong response... \n", style.RESET)
                #     else:
                #         # Good response
                #         break

                # if removeDataResponse.lower() == 'y':
                # Delete DATAS for current metadata
                deleteQFilter = "id_metadata = " + str(currMDataID)
                deleteDataInDB(DB_params, DB_schema, 'datas', deleteQFilter)
                # Log
                debugLog(style.GREEN, "Successfully remove all datas for \'" + currMDataName + "\'", logging.INFO)
            else:
                # # Ask user to skip this metadata ? (if not deleted)
                # while True:
                #     skipResponse = input("Do you want to skip this metadata \'" + currMDataName + "\' ? (y/n) : ")
                #     if skipResponse.lower() not in ('y', 'n'):
                #         print(style.RED + "Sorry, wrong response... \n", style.RESET)
                #     else:
                #         # Good response
                #         break

                # if skipResponse.lower() == 'y':
                if SkipExistingData == 'True':
                    # Log
                    debugLog(style.MAGENTA, "Current metadata \'" + currMDataName + "\' was skipped", logging.INFO)
                    # End timer
                    endTimerLog(currMDTimer)
                    # Skip this item in loop
                    continue

        # Init GDF
        currentGDF = None
        if currMData['temp_file_path']:
            # Load source data from file
            debugLog(style.BLUE, 'Load method for \'' + currMDataName + '\' : local geoJSON or SHP file', logging.INFO)
            currentGDF = createGDFfromGeoJSON( SourceDataPath + "/" + currMData['temp_file_path'])
            
            # Check input projection and reproj in 2154
            currentGDF = checkAndReproj(currentGDF, ENV_targetProj)

        elif currMData['source_url'] and currMData['source_name']:
            #TODO: check API format is geoJSON (API geometry) ??
            # OR Load source data from API
            debugLog(style.BLUE, 'Load method for \'' + currMDataName + '\' : external API', logging.INFO)
            currentGDF = wfs2gp_df(currMData['source_name'], currMData['source_url'], reprojMetro=True, targetProj=ENV_targetProj, proxies=Proxies)
        else:
            debugLog(style.RED, "Incorrect or no load method was found for this metadata \'" + currMDataName + "\'. Skipped... ", logging.ERROR)
            continue

        ### IS_EMPTY ? ###
        currentGDF = checkAndDeleteEmptyGeomFromGDF(currentGDF)

        ### IS_VALID ? ###
        currentGDF = checkAndRepairGeomFromGDF(currentGDF)

        # Get now date and format
        dt = getMinNowDate()

        # Define temp data file name
        tempFileName1 = './tmp/temp_' + text_to_id(currMDataName) + "_" + dt + ".shp"
        tempFileName2 = './tmp/temp_' + text_to_id(currMDataName) + "_" + dt + ".dbf"
        tempFileName3 = './tmp/temp_' + text_to_id(currMDataName) + "_" + dt + ".shx"
        tempFileName4 = './tmp/temp_' + text_to_id(currMDataName) + "_" + dt + ".cpg"
        tempFileName5 = './tmp/temp_' + text_to_id(currMDataName) + "_" + dt + ".prj"

        # Export timer
        exportTimer = startTimerLog('Export data')

        # Write data in geoJSON temp file
        if currMDataListScript and len(currMDataListScript) > 0:
            currentGDF.to_file(tempFileName1)

        # End export timer
        endTimerLog(exportTimer)
        
        # Init retcode
        retcode = None

        # Init factor
        currFactorId = None

        # Launch specifics scripts for this metadata
        if currMDataListScript:
            for currScript in currMDataListScript:
                # Check script if existing
                if os.path.exists(currScript):
                    try:
                        # Init var
                        currScriptShort = currScript.split('.')[0]

                        # Get currScript index
                        currScriptIndex = currMDataListScript.index(currScript)
                        
                        # Define id_factor
                        currFactorId = currMDataListFactors[currScriptIndex]

                        # Log
                        debugLog(style.YELLOW, 'Trying to launch subscript \'' + currScript + '\' for current metadata \'' + currMDataName + '\' ', logging.INFO)

                        # Define script result file name
                        tempResultFileName1 = './tmp/temp_result_' + text_to_id(currMDataName) + "_" + currScriptShort + "_" + dt + ".shp"
                        tempResultFileName2 = './tmp/temp_result_' + text_to_id(currMDataName) + "_" + currScriptShort + "_" + dt + ".dbf"
                        tempResultFileName3 = './tmp/temp_result_' + text_to_id(currMDataName) + "_" + currScriptShort + "_" + dt + ".shx"
                        tempResultFileName4 = './tmp/temp_result_' + text_to_id(currMDataName) + "_" + currScriptShort + "_" + dt + ".cpg"
                        tempResultFileName5 = './tmp/temp_result_' + text_to_id(currMDataName) + "_" + currScriptShort + "_" + dt + ".prj"

                        # Call subscript with filename in argv
                        retcode = call(PythonLaunch + " " + currScript + " " + tempFileName1 + " " + tempResultFileName1, timeout=99999999, shell=True)

                        if -retcode < 0:
                            debugLog(style.RED, "Child process was terminated by signal {}".format(-retcode), logging.ERROR)
                            debugLog(style.RED, "Temporary files was keeped", logging.ERROR)
                            debugLog(style.RED, 'Try to fix the error above and relauch this script for this metadata', logging.ERROR)
                            
                            # Skip current Metadata
                            debugLog(style.MAGENTA, "Current metadata \'" + currMDataName + "\' was skipped", logging.INFO)
                            continue
                        else:
                            debugLog(style.GREEN, "Child process returned {}".format(retcode), logging.INFO)

                            # Log success
                            debugLog(style.YELLOW, 'End of subscript \'' + currScript + '\' for \'' + currMDataName + '\' ', logging.INFO)

                            # Reload GDF from tempResultFileName1
                            resultGDF = createGDFfromGeoJSON(tempResultFileName1)

                            # Insert datas after script treatments
                            insertMDDatas(resultGDF, currMDataID, currFactorId)

                            #TODO: Refacto with array of files to delete (push)
                            # Remove temp files
                            if RemoveTempFile == 'True':
                                # Source
                                if os.path.exists(tempFileName1):
                                    os.remove(tempFileName1)
                                if os.path.exists(tempFileName2):
                                    os.remove(tempFileName2)
                                if os.path.exists(tempFileName3):
                                    os.remove(tempFileName3)
                                if os.path.exists(tempFileName4):
                                    os.remove(tempFileName4)
                                if os.path.exists(tempFileName5):
                                    os.remove(tempFileName5)
                                # Result
                                if os.path.exists(tempResultFileName1):
                                    os.remove(tempResultFileName1)
                                if os.path.exists(tempResultFileName2):
                                    os.remove(tempResultFileName2)
                                if os.path.exists(tempResultFileName3):
                                    os.remove(tempResultFileName3)
                                if os.path.exists(tempResultFileName4):
                                    os.remove(tempResultFileName4)
                                if os.path.exists(tempResultFileName5):
                                    os.remove(tempResultFileName5)
                                debugLog(style.GREEN, "Temporary files was successfully removed", logging.INFO)

                    except OSError as e:
                        debugLog(style.RED, "Execution failed : {} {}".format(e, sys.stderr), logging.ERROR)
                        debugLog(style.RED, "Temporary files was keeped", logging.ERROR)
                else:
                    debugLog(style.RED, "The sub script \'" + currScript + "\' was not found in this path", logging.ERROR)

        # End loop in Metadatas

        # Insert data if no subscript was launched
        if not currMDataListScript:
            # Define id_factor
            currFactorId = currMDataListFactors[0]

            insertMDDatas(currentGDF, currMDataID, currFactorId)

        # End timer
        endTimerLog(currMDTimer)

    # Log end script
    debugLog(style.YELLOW, "End initialisation of \'Datas\'", logging.INFO)
    endTimerLog(currInitDatasTimer)

def insertMDDatas(df, id_metadata, id_factor):
    # Init var
    multiExist = False
    
    # Check if one of geom is MULTI
    allGeomType = df.geom_type
    for geomT in allGeomType:
        if geomT == 'MultiPolygon' or geomT == 'MultiLineString':
            multiExist = True

    # Explode if multi geom
    if multiExist:
        # Clean attributes (keep only geometry)
        currentGeoSerie = df.loc[:,'geometry']
        allGeoSerie = currentGeoSerie.explode(index_parts=False)
        currGDF = gp.GeoDataFrame(allGeoSerie)
    else:
        # Clean attributes (keep only geometry)
        currentGeoSerie = df.loc[:,'geometry']
        currGDF = gp.GeoDataFrame(currentGeoSerie)

    # Add id_metadata to currentGDF
    currGDF = currGDF.assign(id_metadata=id_metadata)

    # Assign id_factor
    currGDF = currGDF.assign(id_factor=id_factor)

    # Transform to WKT
    currGDF = convertGeomToWKT(currGDF)

    # Column list for GDF & DB
    columnsListToDB = ('geom_poly', 'id_metadata', 'id_factor')

    #TODO: Check if geometry is Polygon before insert ?

    # Insert with foreign_key metadata_id
    insertGDFintoDB(DB_params, DB_schema, currGDF, 'datas', columnsListToDB)

def computeFactors(inseeCode=None):
    # Log
    logInseeSuffix = ''
    if inseeCode:
        logInseeSuffix = "for commune '{}'".format(inseeCode)
    debugLog(style.YELLOW, "Launch compute process for factors {}".format(logInseeSuffix), logging.INFO)
    computeTimer = startTimerLog('Compute factors {}'.format(logInseeSuffix))
    
    # Check if inseeCode is numeric
    if inseeCode and not inseeCode.isdigit():
        debugLog(style.RED, "The inseeCode argument is not a number. Please correct your input", logging.INFO)
        return_error_and_exit_job(-4)

    # Get all tiles (filtered by insee if input)
    tilesQuery = 'SELECT id, geom_poly as geom, insee, indice FROM ' + DB_schema + '.tiles'
    if inseeCode:
        tilesQuery = tilesQuery + ' WHERE insee = ' + inseeCode
    # Get Tiles from DB
    tilesGDF = getGDFfromDB(DB_params, tilesQuery, ENV_targetProj)

    # Check empty data for all table
    if len(tilesGDF) == 0:
        # Check length depend on inseeCode
        if inseeCode:
            debugLog(style.YELLOW, "There is no tiles data for this inseeCode : {}. Please verify your input".format(inseeCode), logging.INFO)
            return_error_and_exit_job(-3)
        else:
            debugLog(style.YELLOW, "There is no data in tiles table. Make sure you have launch this script with initGrid argument before", logging.INFO)
            return_error_and_exit_job(-3)

    # Get all factors
    factorsQuery = "SELECT * FROM " + DB_schema + ".factors ORDER BY id"
    allFactors = getDatafromDB(DB_params, factorsQuery)
    # Convert dict results to JSON
    jsonFactors = json.loads(allFactors)

    # Get each Factor data in GDF
    for currFactor in jsonFactors:
        # Current Factor var
        currFactorID = currFactor['id']
        currFactorName = currFactor['name']

        # Check count
        currTFDataCount = 0
        if inseeCode:
            # Check TILES_FACTORS existing data (with insee)
            queryFactorAndInsee = "SELECT count(*) FROM base.tiles_factors tf INNER JOIN base.tiles t ON tf.id_tile = t.id AND t.insee = '{}' WHERE id_factor = {};".format(inseeCode, currFactorID)
            currTFDataFAI = getDatafromDB(DB_params, queryFactorAndInsee)
            currTFDataCount = json.loads(currTFDataFAI)[0]['count']
        else:
            # Check TILES_FACTORS existing data
            qFilter = 'id_factor = ' + str(currFactorID)
            currTFDataCount = getCountfromDB(DB_params, DB_schema, 'tiles_factors', qFilter)

        # Check count for tiles_factors Data
        if currTFDataCount > 0:
            debugLog(style.YELLOW, "/!\ Some datas (tiles_factors & area) already exist for the factor \'" + currFactorName + "\' in database", logging.INFO)

            # Skip factors with existing data in TILES_FACTORS
            if SkipExistingData == 'True':
                # Log
                debugLog(style.MAGENTA, "Current factor \'" + currFactorName + "\' was skipped", logging.INFO)
                continue

            # Ask user to clean table ?
            if EnableTruncate:
                while True:
                    removeDataResponse = input("Do you want to clean those datas ? (y/n) : ")
                    if removeDataResponse.lower() not in ('y', 'n'):
                        print(style.RED + "Sorry, wrong response... \n", style.RESET)
                    else:
                        # Good response
                        break

                if removeDataResponse.lower() == 'y':
                    if inseeCode:
                        # DELETE TILES_FACTORS data for current tiles linked to inseeCode AND id_factor
                        deleteTFQuery = "DELETE FROM base.tiles_factors WHERE id_tile IN ( SELECT id FROM base.tiles t WHERE t.insee = {} ) AND id_factor = {};".format(str(inseeCode), currFactorID)
                        deleteCustomDataInDB(DB_params, deleteTFQuery)
                    else:
                        # DELETE TILES_FACTORS datas with id_factor
                        deleteQFilter = "id_factor = " + str(currFactorID)
                        deleteDataInDB(DB_params, DB_schema, 'tiles_factors', deleteQFilter)
                    

                    # Log
                    debugLog(style.GREEN, "Successfully remove all TILES_FACTORS datas for \'" + currFactorName + "\' ", logging.INFO)

        # Log & timer per factor
        currFactorTimer = startTimerLog("Compute factor " + currFactorName)

        # Get data from DB
        dataFQuery = "SELECT geom_poly as geom, id_metadata, id_factor FROM " + DB_schema + ".datas WHERE id_factor = " + str(currFactorID)
        currFDataGDF = getGDFfromDB(DB_params, dataFQuery, ENV_targetProj)

        # Get commmune geom to filter data
        communesGDF = None
        if inseeCode:
            query = "SELECT insee, geom_poly as geom FROM " + DB_schema + ".communes WHERE insee = '" + inseeCode + "'"
            communesGDF = getGDFfromDB(DB_params, query, ENV_targetProj)

            # Filter data with commune geom (if insee)
            currFDataGDF = gp.overlay(communesGDF, currFDataGDF, how='intersection', keep_geom_type=False)

            # Log
            debugLog(style.MAGENTA, 'Intersect overlap end successfully with \'{}\' entities keeped'.format(len(currFDataGDF)), logging.INFO)

        if len(currFDataGDF) > 1:
            # Union timer
            unionTimer = startTimerLog('Union datas')
            
            # Regroup
            unionGeom = unary_union(currFDataGDF.geometry)
            dataUnion = [{'geometry': unionGeom}]
            unionFactorGDF = gp.GeoDataFrame(dataUnion, crs=ENV_targetProj)
            #TODO: + Clean and repair geom ??

            # End union timer
            endTimerLog(unionTimer)
        else:
            unionFactorGDF = currFDataGDF

        # Clip timer
        clipTimer = startTimerLog('Clip datas with tiles')

        # Intersect & cut data with tiles geom (clip)
        interFData = tilesGDF.clip(unionFactorGDF)
        
        # End clip timer
        endTimerLog(clipTimer)

        # Make result GDF
        interFGDF = gp.GeoDataFrame(interFData, crs=ENV_targetProj)

        # Log success
        debugLog(style.YELLOW, 'Successfully match factor \'{}\' datas with tiles. Found {} entites / {} tiles '.format(currFactorName, len(interFGDF), len(tilesGDF)), logging.INFO)

        debugLog(style.YELLOW, 'Calculating area for current factor tiles and insert in database', logging.INFO)

        # Connect to DB
        conn, cur = connectDB(DB_params, jsonEnable=True)

        # Loop in all RESULT cutFactor Geom (with tiles info)
        for index, row in interFGDF.iterrows():
            # Craft row item in dict format
            rowDict = row.to_dict()

            # Convert into GDF
            rowGDF = gp.GeoDataFrame([rowDict], geometry="geom", crs=ENV_targetProj)

            # Get current Tile id
            currTileID = rowGDF.iloc[0]['id']

            # Calculate area
            currFactorCutGeom = rowGDF.iloc[0]['geom']
            cutFactorArea = currFactorCutGeom.area
            
            # Round result
            roundCutFactorArea = round(cutFactorArea)

            # DEBUG Log
            debugLog(style.YELLOW, "Tiles n°{} as : {} m² of \'{}\' ".format(currTileID, roundCutFactorArea, currFactorName), logging.INFO)

            # Insert area into TILES_FACTOR (with id_tile & id_factor)
            insertTileFactorQuery = "INSERT INTO " + DB_schema + ".tiles_factors (id_tile, id_factor, area) VALUES (" + str(currTileID) + "," + str(currFactorID) + "," + str(roundCutFactorArea) + ");"
            
            try:
                insertDataInDB(cur, insertTileFactorQuery)
            except psycopg2.Error:
                return_error_and_exit_job(-5)

            try:
                conn.commit()
            except psycopg2.Error as e:
                print(e)
                return_error_and_exit_job(-5)

            ##End of current cutFactor (tile) loop

        # Close cursor & DB connexion
        closeDB(conn, cur)

        # Log
        debugLog(style.GREEN, 'Successfully insert all informations and area in database', logging.INFO)
        
        # Ending log
        endTimerLog(currFactorTimer)

        ##End of current factor loop

    # Log & timer end script
    endTimerLog(computeTimer)
    debugLog(style.YELLOW, "End of computing factors process", logging.INFO)

def multiComputeFactors(communesSplitedArray):
    # Re-init env var (cause to multiprocessing)
    initEnv()

    # For each commune (in splited array)
    for currCommune in communesSplitedArray:
        # Compute current commune Factors
        computeFactors(currCommune)

    return

def multiProcessFactors(communesArrayInput=None):
    # Init var
    communesArray = []

    # Check input for Communes array
    if communesArrayInput:
        # Set real array
        communesArray = communesArrayInput
    else:
        # Get Communes data
        comQuery = "SELECT insee FROM " + DB_schema + ".communes"
        communesData = getDatafromDB(DB_params, comQuery)
        # Convert dict results to JSON
        jsonCommunes = json.loads(communesData)

        # Convert jsonArray to array
        for currCommune in jsonCommunes:
            # Init var
            currComInsee = currCommune['insee']
            # Append
            communesArray.append(currComInsee)

    # Get cores number
    cores=mp.cpu_count()

    # Split array by core
    communesSplit = splitList(communesArray, cores)
    # communesSplit = np.array_split(communesArray, cores, axis=0)

    # Create the multiprocessing pool
    pool = Pool(cores)

    # Multiprocess splited array
    df_out = np.vstack(pool.map(multiComputeFactors, communesSplit))

    # Close down the pool and join
    pool.close()
    pool.join()
    pool.clear()

    return

def computeIndices():
    # Log
    debugLog(style.YELLOW, "Start computing indice", logging.INFO)
    computeIndiceTimer = startTimerLog("Compute indice")

    # Global connect to DB & json cursor
    conn, cur = connectDB(DB_params)

    # Get TILES_FACTORS count
    tfCount = getCountfromDB(DB_params, DB_schema, 'tiles_factors', None, conn, cur)

    # Check empty data for TILES_FACTORS table
    if tfCount == 0:
        debugLog(style.RED, "There is no data in tiles_factors table. Make sure you have launch this script with computeFactors argument before", logging.ERROR)
        return_error_and_exit_job(-3)

    # Get TILES count
    tCount = getCountfromDB(DB_params, DB_schema, 'tiles', None, conn, cur)

    # Check empty data for TILES table
    if tCount == 0:
        debugLog(style.RED, "There is no data in tiles table. Make sure you have launch this script with initGrid argument before", logging.ERROR)
        return_error_and_exit_job(-3)

    # Launch SQL Query
    updateIndiceQuery = "UPDATE base.tiles t SET indice = sub.sum_indice FROM (SELECT id_tile, ROUND(SUM(area * f.ponderation)/100::numeric,1) AS sum_indice FROM base.tiles_factors tf JOIN base.factors f ON tf.id_factor = f.id GROUP BY id_tile) as sub WHERE t.id = sub.id_tile; COMMIT;"
    cur.execute(updateIndiceQuery)
    debugLog(style.GREEN, "Successfully update indice in all tiles", logging.INFO)

    # Global close connexion to DB
    closeDB(conn, cur)
    
    # Log
    endTimerLog(computeIndiceTimer)
    debugLog(style.YELLOW, "End computing indice", logging.INFO)

# ------------------------
#   GENERATE ALL CALQUE
# ------------------------

def computeAll(gridSize=30, communesArrayInput=None):
    # Log and timer
    debugLog(style.YELLOW, "Start computing all plantability layer", logging.INFO)
    computeLayerTimer = startTimerLog("Compute all layer")

    # Check and launch initCommunes
    initCommunes()

    jsonCommunes = None
    if communesArrayInput and len(communesArrayInput):
        # Convert communes Array to string list for SQL query
        strCommunesArray = "','".join(communesArrayInput)
        # Get communes filtered by insee
        comQuery = "SELECT insee FROM " + DB_schema + ".communes WHERE insee IN ('" + strCommunesArray + "')"
        communesData = getDatafromDB(DB_params, comQuery)
        # Convert dict results to JSON
        jsonCommunes = json.loads(communesData)
    else:
        # Get Communes data
        comQuery = "SELECT insee FROM " + DB_schema + ".communes"
        communesData = getDatafromDB(DB_params, comQuery)
        # Convert dict results to JSON
        jsonCommunes = json.loads(communesData)

    # Loop in communes
    indexCommune = 1
    lenCommunes = len(jsonCommunes)
    for currCommune in jsonCommunes:
        # Init var
        currComInsee = currCommune['insee']

        # Log
        debugLog(style.YELLOW, "Process grid for commune {} ({}/{})".format(currComInsee, indexCommune, lenCommunes), logging.INFO)

        # Check and launch initGrid
        initGrid(gridSize, currComInsee)

        # Increment index
        indexCommune = indexCommune + 1

    # Check and launch initDatas
    initDatas()

    # Launch multiprocessing to compute Factors
    if communesArrayInput and len(communesArrayInput):
        multiProcessFactors(communesArrayInput)
    else:
        multiProcessFactors()

    # Check and launch computeIndices
    computeIndices()
    
    # End timer
    endTimerLog(computeLayerTimer)
    debugLog(style.YELLOW, "End computing all plantability layer", logging.INFO)

    return

# ------------------------
#           ENV
# ------------------------

def initEnv():
    # Get db .env params & init global var
    global DB_params
    global DB_schema
    global PythonLaunch
    global SourceDataPath
    global ENV_targetProj
    global RemoveTempFile
    global SkipExistingData
    global EnableTruncate
    global HttpProxy
    global Proxies

    # Assign values
    DB_params = {
        "host"      : os.getenv('DB_HOST'),
        "user"      : os.getenv('DB_USER'),
        "password"  : os.getenv('DB_PWD'),
        "database"  : os.getenv('DB_NAME'),
    }
    DB_schema = os.getenv('DB_SCHEMA').strip()
    PythonLaunch = os.getenv('PYTHON_LAUNCH').strip()
    ENV_targetProj = os.getenv('TARGET_PROJ').strip()
    SourceDataPath = os.getenv('SOURCE_DATA_PATH').strip()
    RemoveTempFile = os.getenv('REMOVE_TEMP_FILE').strip()
    SkipExistingData = os.getenv('SKIP_EXISTING_DATA').strip()
    EnableTruncate = os.getenv('ENABLE_TRUNCATE').strip()
    HttpProxy = os.getenv('HTTP_PROXY').strip()

    Proxies = { 
                "http"  : HttpProxy, 
                "https" : HttpProxy
                }
    
def displayEnv():
    # display param value for debug
    debugLog(style.WHITE, "DB_schema="+DB_schema, logging.INFO)
    debugLog(style.WHITE, "PythonLaunch="+PythonLaunch, logging.INFO)
    debugLog(style.WHITE, "ENV_targetProj="+ENV_targetProj, logging.INFO)
    debugLog(style.WHITE, "SourceDataPath="+SourceDataPath, logging.INFO)
    debugLog(style.WHITE, "RemoveTempFile="+RemoveTempFile, logging.INFO)
    debugLog(style.WHITE, "SkipExistingData="+SkipExistingData, logging.INFO)
    debugLog(style.WHITE, "EnableTruncate="+EnableTruncate, logging.INFO)
    debugLog(style.WHITE, "HttpProxy="+HttpProxy, logging.INFO)

# ------------------------
#          MAIN
# ------------------------

# @memory(percentage=0.8)
def main():
    # Launch function depend on argv
    argv = sys.argv[1:]
    firstArgv = None

    # Argv exist ?
    if argv:
        firstArgv = sys.argv[1:][0]

        # Sfs2itch case...
        if firstArgv == 'initCommunes':
            initCommunes()
        elif firstArgv == 'initGrid':
            secArgv = None
            thirdArgv = None
            # Test argv2 exist
            try:
                # Get gridSize (argv 2)
                secArgv = sys.argv[1:][1]
            except(Exception) as error:
                debugLog(style.RED, "Please input the grid size wanted as last argument", logging.ERROR)
            
            if secArgv:
                # Test argv3 exist
                try:
                    # Get inseeCode (argv 3)
                    thirdArgv = sys.argv[1:][2]
                except(Exception) as error:
                    debugLog(style.YELLOW, "/!\ This script will generate grid in all territory")

                if secArgv.isdigit():
                    # Launch function
                    initGrid(int(secArgv), thirdArgv)
                else:
                    debugLog(style.RED, "The grid size value is not a number. Please correct your input", logging.ERROR)
        elif firstArgv == 'initDatas':
            initDatas()
        elif firstArgv == 'computeFactors':
            secArgv = None
            if len(sys.argv[1:]) > 1:
                secArgv = sys.argv[1:][1]
                # Cast to list
                communesArrayCasted = secArgv.split(',')
                # One or more communes ?
                if len(communesArrayCasted) > 1:
                    multiProcessFactors(communesArrayCasted)
                else:
                    computeFactors(secArgv)
            else:
                # All communes
                debugLog(style.YELLOW, "/!\ This script will compute factors in all territory")
                multiProcessFactors()
        elif firstArgv == 'computeIndices':
            computeIndices()
        elif firstArgv == 'computeAll':
            secArgv = None
            thirdArgv = None
            # Test argv2 exist
            try:
                # Get gridSize (argv 2)
                secArgv = sys.argv[1:][1]
            except(Exception) as error:
                debugLog(style.RED, "Please input the grid size wanted as last argument")
            
            if secArgv:
                if secArgv.isdigit():
                    # Test argv3 exist
                    try:
                        # Get inseeCode (argv 3)
                        thirdArgv = sys.argv[1:][2]
                        # Cast to list
                        thirdArgv = thirdArgv.split(',')
                    except(Exception) as error:
                        debugLog(style.YELLOW, "/!\ This script will computeAll plantability in all territory")

                    # Launch function
                    computeAll(int(secArgv), thirdArgv)
                else:
                    debugLog(style.RED, "The grid size value is not a number. Please correct your input")
        elif firstArgv == 'test':
            secArgv = sys.argv[1:][1]
            test(secArgv)
        elif firstArgv == 'testDB':
            testDBConnexion()
        elif firstArgv == 'help':
            showDoc()
        elif firstArgv == 'env':
            displayEnv()
        else:
            showDoc()
            debugLog(style.RED, "Unrecognized arguments for this script", logging.ERROR)
    else:
        showDoc()

if __name__ == "__main__":
    # Enable windows native color
    os.system("")

    # Init logs directory
    logsPath = './logs/'
    checkAndCreateDirectory(logsPath)

    # Init logging
    initLogging(logsPath)

    # Load .env values
    try:
        load_dotenv()
    except (e):
        return_error_and_exit_job(-1)

    # Check .env file initialization
    checkEnvFile()

    # Init env variable
    initEnv()

    # Only print in console
    print(style.YELLOW + "Current database settings : {} - {} \n".format(DB_params['host'], DB_params['database']), style.RESET)

    # Check if ./tmp/ folder exist then create if not
    tmpPath = './tmp/'
    checkAndCreateDirectory(tmpPath)

    # Launch main function
    main()
