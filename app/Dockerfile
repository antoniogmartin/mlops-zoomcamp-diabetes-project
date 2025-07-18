FROM python:3.8-slim-bullseye
 
WORKDIR /app
 
RUN pip install --no-cache flask==2.3.2 gunicorn==20.0.4 mlflow==2.5.0 azure-storage-blob==12.17.0 azure-identity==1.14.0
 
COPY . .
 
EXPOSE 80

CMD [ "gunicorn", "--bind=0.0.0.0:80", "predict-diabetes-app:app" ]