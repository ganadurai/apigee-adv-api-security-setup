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
function cleanup() {
    echo "Deleting the developer app"
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/developers/advapisec-developer@google.com/apps/advapisec-demo-app" > /dev/null

    echo "Deleting the developer"
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/developers/advapisec-developer@google.com" > /dev/null

    echo "Deleting the product"
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apiproducts/advapisec-demo-product" > /dev/null

    echo "Undeploying the proxies"
    curl -s -X DELETE "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-oauth/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    curl -s -X DELETE "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-httpbin/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    curl -s -X DELETE "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-hello-world-oauth/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null
    curl -s -X DELETE "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/apis/advapisec-hello-world/revisions/1/deployments" \
         -H "Authorization: Bearer ${TOKEN}" > /dev/null

    echo "Deleting the proxies"
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis/advapisec-oauth" > /dev/null
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis/advapisec-httpbin" > /dev/null
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis/advapisec-hello-world-oauth" > /dev/null
    curl -s -H "Authorization: Bearer ${TOKEN}" -X DELETE "${MGMT_HOST}/v1/organizations/${APIGEE_ORG}/apis/advapisec-hello-world" > /dev/null

}