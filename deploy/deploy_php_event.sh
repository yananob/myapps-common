#!/bin/bash
set -eu

if [ "$#" -lt 2 ]; then
  echo ""
  echo "  Insufficient arguments."
  echo "  Usage: $0 <dirname to be deployed> <name on Cloud Functions> <entry point: default=main_event>"
  echo ""
  exit 1
fi

WORK_DIR=_deploy
TARGET_DIR=$1
export FUNC_NAME=$2
# remove "/" on the right side
FUNC_NAME=`php -r '$result=getenv("FUNC_NAME"); echo substr($result, -1) === "/" ? rtrim($result, "/") : $result;'`

if [ "$#" -lt 3 ]; then
    ENTRY_POINT=main_event
else
    ENTRY_POINT=$3
fi

echo "Checking ${TARGET_DIR}"
# pushd ${FUNC_NAME}

# Check existance of .gcloudignore
if ! test -f ".gcloudignore"; then
    echo ".gcloudignore doesn't exist. Please create it."
    exit 1
fi

# # Check existance of specific deploy.sh
# if test -f "deploy.sh"; then
#     echo "Specific deploy.sh for this app exists. Please run it instead of this shell."
#     exit 1
# fi

# check existance of config.sample.json & config.json
if test -f "configs/config.json.sample"; then
    if test ! -f "configs/config.json"; then
        echo "Config.json.sample exists. Please make config.json for this app."
        exit 1
    fi
fi
# popd

echo "----------------------------------------------------------------"
echo "Starting to deploy ${FUNC_NAME}"

rm -rf ./${WORK_DIR}
mkdir -p ${WORK_DIR}

rsync -vaL --exclude-from=./_myapps-common/deploy/rsync_exclude.conf ./${TARGET_DIR} ./${WORK_DIR}/
pushd ${WORK_DIR}

echo -e "\e[33m deploying event function [${FUNC_NAME}] \e[m"
gcloud functions deploy ${FUNC_NAME} \
    --gen2 \
    --runtime=php82 \
    --region=us-west1 \
    --source=. \
    --entry-point=${ENTRY_POINT} \
    --trigger-topic=${FUNC_NAME}

popd
rm -rf ./${WORK_DIR}
