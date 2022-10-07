# Apigee Advanced API Security - Demo setup  toolkit

The Apigee Advanced API Security Demo toolkit sets up sample proxies and the needed Apigee artifacts to execute the Bot simulation toolkit.  

### Prerequisites

1. Set up the following variables
    ```bash
    export APIGEE_PROJECT_ID=<apigee-project-id where the demo will be executed>
    export APIGEE_ENV=<apigee-env>
    export APIGEE_ENV_HOSTNAME=<apigee-env-group-hostname>
    ```

1. Set up the gcloud authentication and fetch the tokens.
    ```bash
    gcloud config set project $APIGEE_PROJECT_ID
    gcloud auth application-default login --no-launch-browser

    export TOKEN=$(gcloud auth print-access-token)
    ```

1. Set up the following variables for the simulation controller
    ```bash
    export JOB_CONTROLLER_ENDPOINT="https://eval-group.35-186-236-163.nip.io"
    export BOT_PERCENT="50"
    export BOT_SRC_IPADDRESS="127.0.0.1"
    export JOB_CONTROLLER_EXECUTION_TIMER=80
    ```

### Installation & Execute the demo
    (Run the following to the get the usage information)
    ```bash
    ./advapisec-demo-setup.sh
    ```
    (Example run, this will install the needed artifacts in Apigee org)
    ```bash
    ./advapisec-demo-setup.sh -a install
    ```

    (Example run, this will clean the adv api security demo artifacts in Apigee org)
    ```bash
    ./advapisec-demo-setup.sh -a cleanup
    ```

### Post Installation
    Share the output of the script execution to trigger api security simulation



function report_gen() {
    echo "Setup Adv API Security report"

    curl -s -X POST "$MGMT_HOST/v1/organizations/$APIGEE_ORG/environments/$APIGEE_ENV/local/securityReports" \
       -X POST -d @./apigee-bundles/Query.json \
       -H 'Content-type: application/json' \
       -H "Authorization: Bearer $TOKEN"
}
