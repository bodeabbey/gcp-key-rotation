#!/bin/bash

####
#
# Inputs: <project_id> <file location of service accounts>
serviceAccountProject=$1
serviceAccountFile=$2

if [[ -z $serviceAccountProject ]]; then
    echo "No Project argument provided"
    exit 1
else
    gcloud projects describe `cat $1` &> /dev/null
    if [[ "$?" == "1" ]] ; then
        echo "You do not have access to the project $1 or it does not exist"
        exit 1
    fi
fi

if [[ -z $serviceAccountFile ]] || [[ ! -f $serviceAccountFile ]]; then
    echo "No service account file exists"
    exit 1
fi

# This is constant do not change
serviceAccountSuffix=".iam.gserviceaccount.com"

# Function to created one or more keys in one or more service account in more than one project
create_keys(){
    for sa in `cat $2`; do
        gcloud iam service-accounts \
        keys create $sa"-key"$(date +%Y%m%d%H%M%S).json \
        --iam-account=$sa"@"`cat $1`$serviceAccountSuffix \
        --project $1
    done
}

# execute the function
