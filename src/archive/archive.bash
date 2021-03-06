#!/bin/bash

BASE_DIR=`pwd`
SEARCH_DIR=`pwd`
TARGET_DIR=`pwd`
NUMBER_OF_YEARS=1
LOG_DIR=/var/log/archive/projects
SET_LOG_LEVEL=3


function HELP() {
  echo "***************************************************************************"
  echo "* Usage                                                                   *"
  echo "***************************************************************************"
  echo "* RUN AS ROOT USER                                                        *"
  echo "* Please specify a timeframe in years                                     *"
  echo "* You can do this with:                                                   *"
  echo "* + -y = [number of years]                                                *"
  echo "* Enter the root-directory you want to run this script from               *"
  echo "* + -d = [directory]                                                      *"
  echo "* Enter the target-directory you want to copy the files in                *"
  echo "* + -t = [directory]                                                      *"
  echo "* Enter the desired log level                                             *"
  echo "* + -l = [log level (ERROR=1, WARNING=2, INFO=3, DEBUG=4, TRACE=5)]       *"
  echo "* For example: ./archive.bash -y 2 -d /'                                  *"
  echo "* When all files are older in 1 subdirectory the subdirectory is archived *"
  echo "***************************************************************************"
}

function LOG() {
  LOG_LEVEL=${1}
  LOG_MESSAGE=${2}
  LOG_PREFIX="[INFO]"
  DATE=$(date +"%d-%m-%Y")
  TIME=$(date +"%T")
  if [[ -z ${LOG_LEVEL} ]]; then
    LOG_LEVEL=3
  elif [[ ${LOG_LEVEL} == 1 ]]; then
    LOG_PREFIX="[ERROR]"
  elif [[ ${LOG_LEVEL} == 2 ]]; then
    LOG_PREFIX="[WARN]"
  elif [[ ${LOG_LEVEL} == 4 ]]; then
    LOG_PREFIX="[DEBUG]"
  elif [[ ${LOG_LEVEL} == 5 ]]; then
    LOG_PREFIX="[TRACE]"
  fi
  if [[ ${LOG_LEVEL} -le 3 ]]; then
    echo "${LOG_PREFIX} | ${DATE} ${TIME} | ${LOG_MESSAGE}" >> ${LOG_DIR}/${DATE}_archived_projects.log
  fi
  if [[ ${SET_LOG_LEVEL} -ge ${LOG_LEVEL} ]]; then
    echo "${LOG_PREFIX} | ${DATE} ${TIME} | ${LOG_MESSAGE}"
  fi
}

if [ $# -eq 0 ]; then
    HELP
    exit 1
fi

while getopts :hy:d:l:t: opt; do
    case ${opt} in
        h) HELP; exit
        ;;
        y) NUMBER_OF_YEARS=${OPTARG}
        ;;
        d) SEARCH_DIR=${OPTARG}
        ;;
        t) TARGET_DIR=${OPTARG}
        ;;
        l) SET_LOG_LEVEL=${OPTARG}
        ;;
        :) LOG 5 "Missing argument for option -${OPTARG}"; exit 1
        ;;
       \?) LOG 5 "Unknown option -${OPTARG}"; exit 1
        ;;
    esac
done

LOG 3 "################################################################################"
LOG 3 "Start archiving projects"
LOG 3 "--------------------------------------------------------------------------------"
LOG 3 "Setup environment"
LOG 3 "--------------------------------------------------------------------------------"
LOG 3 "Search files older then (years):    [ ${NUMBER_OF_YEARS} ]"
LOG 3 "Running in ROOT-directory:          [ ${SEARCH_DIR} ]"
LOG 3 "Logs go to directory:               [ ${LOG_DIR} ]"
LOG 3 "Log level is set to:                [ ${SET_LOG_LEVEL} ]"
LOG 3 "--------------------------------------------------------------------------------"

mkdir -p ${LOG_DIR}

PERIOD=$((${NUMBER_OF_YEARS}*365))
cd ${SEARCH_DIR}
DIR_LIST=(`find . -iname "*" -mtime +${PERIOD} | cut -d/ -f -2 | sort -u`)
CLEARED_SPACE=0
CHECKED_SPACE=0
for ((index = 0; index < ${#DIR_LIST[@]}; ++index)); do
  if [[ ${index} != 0 ]]; then
    FOUND_DIR=${DIR_LIST[index]}
    if [[ -d ${FOUND_DIR} ]]; then
      NUMBER_OF_OLD_FILES_FOUND=`find ${FOUND_DIR} -iname "*" -mtime +${PERIOD} | wc -l`
      NUMBER_OF_FILES_FOUND=`find ${FOUND_DIR} -iname "*" | wc -l`
      SPACE=`du -sm ${FOUND_DIR} | cut -f1`
      CHECKED_SPACE=$((${CHECKED_SPACE}+${SPACE}))
      LOG 5 "Project-directory: [ ${FOUND_DIR} ] old: [ ${NUMBER_OF_OLD_FILES_FOUND} ] total: [ ${NUMBER_OF_FILES_FOUND} ] space: [ ${SPACE} mb ]"
      if [ ${NUMBER_OF_OLD_FILES_FOUND} -eq ${NUMBER_OF_FILES_FOUND} ]; then
        CLEARED_SPACE=$((${CLEARED_SPACE}+${SPACE}))
        LOG 3 "Archived project-directory: ${FOUND_DIR} | space cleared: [ ${SPACE} mb ]"
        cp -r ${FOUND_DIR} ${TARGET_DIR}
      fi
    else
      LOG 2 "This file: [ ${FOUND_DIR} ] is not a directory"
    fi
  fi
done
LOG 3 "--------------------------------------------------------------------------------"
LOG 3 "Total space checked: [ ${CHECKED_SPACE} mb ]"
LOG 3 "Total space cleared: [ ${CLEARED_SPACE} mb ]"
cd ${BASE_DIR}
LOG 3 "--------------------------------------------------------------------------------"
LOG 3 "End of archiving projects"
LOG 3 "################################################################################"
