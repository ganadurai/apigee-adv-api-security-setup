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

function validate() {
    printf "\nChecking org validity for the given seurity token/authz...\n";
    OUTPUT=$(curl -s -i -H "Authorization: Bearer ${TOKEN}" \
                "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG" | grep HTTP)
    if [[ "$OUTPUT" == *"200"* ]]; then
        printf "\nThe Organization provided is valid!\n"
    else
        printf "\nThe Organization provided is not valid for the auth TOKEN provided!\n"
        exit 1;
    fi
}

function fetchEnv4Envgroup() {
    envgroup_name=$1
    host_names=$2
    envgroupAttachments=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
                "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/envgroups/$envgroup_name/attachments" | \
                jq '.environmentGroupAttachments');
    #echo "attachments - ${envgroupAttachments}"
    for envgroupAttachment in $(echo "${envgroupAttachments}" | jq -c '.[]'); 
    do
        envname=$(echo "${envgroupAttachment}" | jq '.environment' | cut -d '"' -f 2)
        if [[ "$envname" == "$APIGEE_ENV" ]];
        then
            printf "\n"
            echo "Hostnames for env $APIGEE_ENV:"
            for hostname in $(echo "$host_names" | jq -c '.[]'); 
            do
                echo "$hostname"
            done
            printf "\n"
        fi
    done
}

function fetchEnvHostnames() {
    #echo "Fetching envgroups";
    envgroups=$(curl -s -H "Authorization: Bearer ${TOKEN}" \
                "https://apigee.googleapis.com/v1/organizations/$APIGEE_ORG/envgroups" | \
                jq '.environmentGroups')
    #echo "${envgroups}"
    for envgroup in $(echo "${envgroups}" | jq -c '.[]'); 
    do
        envgroupName=$(echo "${envgroup}" | jq '.name' | cut -d '"' -f 2)
        hostnames=$(echo "${envgroup}" | jq '.hostnames')
        fetchEnv4Envgroup "$envgroupName" "$hostnames";
    done
}

function setup() {

    echo "Setup Apigee proxies"
    curl -s -X POST "$MGMT_HOST/v1/organizations/$APIGEE_ORG/apis?action=import&name=advapisec-oauth" \
         -H "Authorization: Bearer $TOKEN" --form file=@"./apigee-bundles/advapisec-oauth.zip" > /dev/null
    curl -s -X POST "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis?action=import&name=advapisec-httpbin" \
         -H "Authorization: Bearer $TOKEN" --form file=@"./apigee-bundles/advapisec-httpbin.zip" > /dev/null
    curl -s -X POST "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis?action=import&name=advapisec-hello-world-oauth" \
         -H "Authorization: Bearer $TOKEN" --form file=@"./apigee-bundles/advapisec-hello-world-oauth.zip" > /dev/null
    curl -s -X POST "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis?action=import&name=advapisec-hello-world" \
         -H "Authorization: Bearer $TOKEN" --form file=@"./apigee-bundles/advapisec-hello-world.zip" > /dev/null

    echo "Deploy Apigee proxies"
    curl -s -X POST "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-oauth/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    curl -s -X POST "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-httpbin/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    curl -s -X POST "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-hello-world-oauth/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    curl -s -X POST "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-hello-world/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    
    echo "Setup Apigee Product"
    curl -s -H "Authorization: Bearer ${TOKEN}"   -H "Content-Type:application/json"   "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apiproducts" -d \
        '{
            "name": "advapisec-demo-product",
            "displayName": "advapisec-demo-product",
            "approvalType": "auto",
            "attributes": [
                {
                "name": "access",
                "value": "private"
                }
            ],
            "description": "API Product for demoing adv api security",
            "environments": [
                "'"${APIGEE_ENV}"'"
            ],
            "operationGroup": {
                "operationConfigs": [
                {
                    "apiSource": "advapisec-hello-world-oauth",
                    "operations": [
                    {
                        "resource": "/"
                    }
                    ],
                    "quota": {}
                }
                ]
            }
        }' > /dev/null

    echo "Setup Apigee Developer"

    curl -s -H "Authorization: Bearer ${TOKEN}"   -H "Content-Type:application/json"   "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/developers" -d \
        '{
        "email": "advapisec-developer@google.com",
        "firstName": "Test",
        "lastName": "AdvApiSec",
        "userName": "advapisec"
        }' > /dev/null

    echo 'Setup developer app for the Product'

    curl -s -H "Authorization: Bearer ${TOKEN}"   -H "Content-Type:application/json"   "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/developers/advapisec-developer@google.com/apps" -d \
        '{
        "name":"advapisec-demo-app",
        "apiProducts": [
            "advapisec-demo-product"
            ]
        }' > /dev/null

    printf "\nExtracting the consumer key\n"
    CONSUMER_KEY=$(curl -s -H "Authorization: Bearer ${TOKEN}"  \
        -H "Content-Type:application/json" \
        "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/developers/advapisec-developer@google.com/apps/advapisec-demo-app" | \
        jq '.credentials[0].consumerKey'); \
        CONSUMER_KEY=$(echo "$CONSUMER_KEY"|cut -d '"' -f 2); export CONSUMER_KEY;
    echo "CONSUMER_KEY - $CONSUMER_KEY"
    
    printf "\nExtracting the consumer secret\n"
    CONSUMER_SECRET=$(curl -s -H "Authorization: Bearer ${TOKEN}"  \
        -H "Content-Type:application/json" \
        "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/developers/advapisec-developer@google.com/apps/advapisec-demo-app" | \
        jq '.credentials[0].consumerSecret'); \
        CONSUMER_SECRET=$(echo "$CONSUMER_SECRET"|cut -d '"' -f 2); export CONSUMER_SECRET;
    echo "CONSUMER_SECRET - $CONSUMER_SECRET"
    printf "\n"
}

