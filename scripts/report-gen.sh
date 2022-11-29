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

function fetchReportStatus() {
  printf "\nFetching report status : %s" "$REPORT_SELF_LINK"
  RESULT=1
  REPORT_STATUS=$(curl -s "https://apigee.googleapis.com/v1$REPORT_SELF_LINK" \
       -X GET  -H 'Content-type: application/json' \
       -H "Authorization: Bearer $TOKEN" | \
      jq '.state' | cut -d '"' -f 2);
  if [[ "$REPORT_STATUS" == "completed" ]]; then
      RESULT=0
  fi
  printf "\n%s" "REPORT_STATUS: $REPORT_STATUS"
  export RESULT
}

function reportGen() {
  REPORT_SELF_LINK=$(curl -s "https://apigee.googleapis.com/v1/organizations/$APIGEE_PROJECT_ID/environments/$APIGEE_ENV/securityReports" \
      -X POST -d '{"dimensions":["bot_reason"],"metrics":[{"aggregation_function":"sum","name":"bot_traffic"}],"groupByTimeUnit":"minute","timeRange":"last24hours"}' \
      -H 'Content-type: application/json' \
      -H "Authorization: Bearer $TOKEN" | \
      jq '.self' | cut -d '"' -f 2); export REPORT_SELF_LINK;
  
  fetchReportStatus;
  
  counter=0;
  while [ $RESULT -ne 0 ] && [ $counter -lt 30 ]; do
    printf "\nSleeping 20s and re-trying..."
    sleep 20
    fetchReportStatus;
    counter=$((counter+1))
  done

  if [ $RESULT -eq 0 ]; then
    printf "\nReport generated successfully\n"
    REPORT_ID=$(echo "$REPORT_SELF_LINK" | cut -d '/' -f 7);
    echo "View the report on the console: https://apigee.google.com/organizations/$APIGEE_PROJECT_ID/report-jobs/report-view/$REPORT_ID?environment=$APIGEE_ENV" 
  else
    printf "\nReport *NOT* generated\n" 
  fi
}

reportGen;
#REPORT_SELF_LINK="/organizations/integ-project-2/environments/eval/securityReports/b23de9f4-fedb-4db5-b741-8500266932bf"
#fetchReportStatus;
#echo $RESULT