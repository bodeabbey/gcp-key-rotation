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
    gcloud projects describe $serviceAccountProject &> /dev/null
    if [[ "$?" == "1" ]] ; then
        echo "You do not have access to the project $serviceAccountProject or it does not exist"
        exit 1
    fi
fi

if [[ -z $serviceAccountFile ]] || [[ ! -f $serviceAccountFile ]]; then
    echo "No service account file exists"
    exit 1
fi

serviceAccountSuffix=".iam.gserviceaccount.com"

# Function to delete one or more old keys in one or more service account in more than one project
rotate_keys(){
    for sa in `cat $2`; do
        echo "working on $sa"
        recent_key_id=$(gcloud iam service-accounts keys list --iam-account=${sa}"@"$1${serviceAccountSuffix} --sort-by ~CREATED_AT --filter "EXPIRES_AT>=9000-12-31T23:59:59Z"  --format "value(KEY_ID,CREATED_AT)" | tail -n 1 | awk '{ print $1 }')
        for key_id in $(gcloud iam service-accounts keys list --format="value(KEY_ID)" --iam-account=${sa}"@"$1${serviceAccountSuffix} --filter "EXPIRES_AT>=9000-12-31T23:59:59Z"); do
            if [[ "$recent_key_id" != "$key_id" ]] ; then
                gcloud iam service-accounts keys delete $key_id --iam-account=${sa}"@"$1${serviceAccountSuffix} --quiet --project $1
            fi
        done
    done
}
