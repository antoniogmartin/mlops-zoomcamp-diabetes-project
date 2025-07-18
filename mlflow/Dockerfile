FROM python:3.8-slim-bullseye

RUN pip install --no-cache mlflow==2.5.0 azure-storage-blob==12.14.1

CMD mlflow server \ 
    --host 0.0.0.0 \
    --backend-store-uri sqlite:///mlflow.db \
    --default-artifact-root wasbs://storagecontmflow@storageaccmflow.blob.core.windows.net