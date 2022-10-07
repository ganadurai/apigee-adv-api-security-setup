#!/bin/bash

# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

source ./scripts/setup.sh
source ./scripts/cleanup.sh
source ./scripts/job-initiate.sh

usage() {
    echo -e "$*\n usage: $(basename "$0")" \
        "-a <action>\n" \
        "example: $(basename "$0") -a install\n" \
        "example: $(basename "$0") -a cleanup\n" \
        "Parameters:\n" \
        "-a --action : Install or Cleanup action, valid values 'install', 'cleanup'"
    exit 1
}

if [[ $# -ne 2 ]]
then
    echo "missing needed params"
    usage;
    exit 1;
fi 

while [[ $# -gt 0 ]]
do
    param="$1"
    case $param in
        -a|--action)
        export ACTION="$2"
        shift
        shift
        ;;
        *)
        PARAMETERS+=("$1")
        shift
        ;;
    esac
done

if [[ -z $ACTION ]]; then
    usage "action is a mandatory field"
fi

export MGMT_HOST="https://apigee.googleapis.com"
export APIGEE_ORG=$APIGEE_PROJECT_ID

if [ "$ACTION" == 'cleanup' ]; then
    validate;
    cleanup;
elif [ "$ACTION" == 'install' ]; then
    validate;
    setup;
    #fetchEnvHostnames;
    echo "Waiting 30 secs, for the deployments to be complete"
    sleep 30;
    echo "Initiating the simulation job"
    submitJob;
else
    usage;
fi

