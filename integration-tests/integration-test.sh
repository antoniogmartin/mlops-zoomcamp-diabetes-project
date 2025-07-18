#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export AZURE_STORAGE_CONNECTION_STRING="DefaultEndpointsProtocol=http;ACCOUNTNAME=devstoreaccount1;AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;BlobEndpoint=http://127.0.0.1:10000/devstoreaccount1;"

azurite -l ./integration-test-data &
azuritepid=$!
azurite_cleanup() {
    echo "Terminating azurite background process"
    kill -s 15 $azuritepid
}
trap azurite_cleanup EXIT

az storage container create --name storagecontainermflow
az storage blob upload -c storagecontainermflow --overwrite -f $DIR/integration-test-data/MLmodel -n "1/f636a697a38d4440b294dc854fbafd40/artifacts/model/MLmodel"
az storage blob upload -c storagecontainermflow --overwrite -f $DIR/integration-test-data/conda.yaml -n "1/f636a697a38d4440b294dc854fbafd40/artifacts/model/conda.yaml"
az storage blob upload -c storagecontainermflow --overwrite -f $DIR/integration-test-data/model.pkl -n "1/f636a697a38d4440b294dc854fbafd40/artifacts/model/model.pkl"
az storage blob upload -c storagecontainermflow --overwrite -f $DIR/integration-test-data/python_env.yaml -n "1/f636a697a38d4440b294dc854fbafd40/artifacts/model/python_env.yaml"
az storage blob upload -c storagecontainermflow --overwrite -f $DIR/integration-test-data/requirements.txt -n "1/f636a697a38d4440b294dc854fbafd40/artifacts/model/requirements.txt"

python $DIR/../app/predict-diabetes-app.py &

apppid=$!
app_cleanup() {
    echo "Terminating app background process"
    kill -s 15 $apppid
}
trap app_cleanup EXIT

# Sleep a bit so that the app is ready to receive requests
sleep 5

python $DIR/integration-test.py