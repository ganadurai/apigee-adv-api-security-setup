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

function submitJob() {
  echo "Initiating job"

  JOB_ID=$(curl -s -X POST -H "Content-Type:application/json" \
        "${JOB_CONTROLLER_ENDPOINT}/v1/jobs" -d \
        '{
          "ipaddress": "'"${BOT_SRC_IPADDRESS}"'",
          "hostname": "'"${APIGEE_ENV_HOSTNAME}"'",
          "percentage_bots": "'"${BOT_PERCENT}"'",
          "clientkey": "'"${CONSUMER_KEY}"'",
          "clientsecret": "'"${CONSUMER_SECRET}"'",
          "projectid": "'"${APIGEE_PROJECT_ID}"'"
        }' | jq '.jobid')
    JOB_ID=$(echo "$JOB_ID"|cut -d '"' -f 2); export JOB_ID;
    printf "\n"
    echo "Job status check:"
    echo "curl ${JOB_CONTROLLER_ENDPOINT}/v1/jobs/$JOB_ID"
    printf "\n"
}
