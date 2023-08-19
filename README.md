# MLOps Zoomcap Project - Diabetes Prediction

This is my final project for [MLOps Zoomcamp](https://github.com/DataTalksClub/mlops-zoomcamp) [2023 cohort](https://github.com/DataTalksClub/mlops-zoomcamp/tree/main/cohorts/2023).

## Problem Overview 

The idea of the project is to have a model which could be used to predict if a patient has a likelihood to have diabetes. Based on the result their healthcare provider could just the care, lifestyle changes could be done or ordered more tests to determine if they actually have diabetes.

This project uses a well-known Pima Indians Diabetes dataset to predict if an individual has diabetes. The dataset can be downloaded from [here](https://www.kaggle.com/datasets/uciml/pima-indians-diabetes-database). The dataset contains the following columns:

* Number of times pregnant: The number of times the individual has been pregnant.
* Plasma glucose concentration a 2 hours in an oral glucose tolerance test: This is a measure of the individual's blood sugar level after undergoing a 2-hour oral glucose tolerance test.
* Diastolic blood pressure (mm Hg): This represents the blood pressure measurement.
* Triceps skin fold thickness (mm): It's a measure of the skinfold thickness at the triceps, which can be an indirect measure of the body's fat percentage.
* 2-Hour serum insulin (mu U/ml): Measure of insulin levels in the blood after 2 hours.
* Body mass index (BMI): It's a measure used to determine whether an individual has a healthy body weight for a person of their height. Calculated as weight in kilograms divided by the square of the height in meters (kg/m^2).
* Diabetes pedigree function: It's a function that represents the likelihood of diabetes based on family history. The higher the value, the higher the genetic tendency towards diabetes.
* Age (years): The age of the individual.
* Class variable (0 or 1): Outcome variable. A value of 1 represents the presence of diabetes, and a value of 0 represents the absence.

## Technology Stack

* [Azure](https://azure.microsoft.com/) - Cloud environment
* [Terraform](https://www.terraform.io/) - Infrastucture as Code
* [GitHub Actions](https://github.com/features/actions) - CI/CD to deploy infrastucture and services to Azure
* [MLFlow](https://mlflow.org/) - Experiment tracking, model versioning
* [Prefect](https://www.prefect.io/) - Workflow orchestration
* [Flask](https://flask.palletsprojects.com/) - Model App 
* [Docker](https://www.docker.io) - to containerize all deployed components (MLFlow, Prefect, Model app)
* [Azurite](https://github.com/Azure/Azurite) - emulate Azure Object Storage in integration tests

The whole project is deployed to the cloud and there are GitHub Actions for CI/CD.

## How to deploy the project from scratch to the cloud

This is how you deploy the project and its components to Azure

### Create Azure subscription

You need a Azure subscipion. You can create this at [Azure Portal](http://portal.azure.com).

### Install Azure CLI and login

1. Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/).
2. Login on your machine to Azure by calling `az login`

### Create Azure service pricipal

You will need service principal for exampleon GitHub Actions. Replace `<subscription_id>` with your Azure Subsciprion ID.

        az ad sp create-for-rbac --role Contributor --scopes /subscriptions/<subscription_id>

You will need the values from the output JSON later:

        {
          "appId": "...",
          "displayName": "...",
          "password": "...",
          "tenant": "...",
        }

### Configure Azure secrets to GitHub

In the GitHub project, go to `Settings` -> `Actions` under `Secrets and Variables`. Add the following `Secrets`:

* `AZURE_CLIENT_ID`: `appId` from service principal output JSON
* `AZURE_CLIENT_SECRET`: `password` from service principal output JSON
* `AZURE_SUBSCRIPTION_ID`: Your Azure Subscription ID
* `AZURE_TENANT_ID`: `tenant` from service principal output JSON

### Infrastructure

Terraform needs a place to store its state file and the infra for that cannot be managed by Terraform. We need to create it. To create a resource group, storage account and container for terraforms state file, run on the project root:
   
        make create_terraform_state_storage

Now that we have storage for Terraform state, we can run GitHub Action `terraform.yml` `Terraform` to create Azure infrastructure for the project.

### More Secrets

After the infrastructure has been created, we need to add a few more secrets to GitHun to be able to to deploy the rest of the components to Azure.

Add 3 more secrets to GitHub Actions secrets:

* `REGISTRY_LOGIN_SERVER`: `containerrmlops.azurecr.io`
* `REGISTRY_USERNAME`: `containerrmlops`
* `REGISTRY_PASSWORD`: Copy the password from the Access Key section in the Container registry's Azure Portal page.

### Deploy Docker images

1. Deploy MlFlow Docker image to the container registry by running GitHub Action `deploy-mlflow.yml`
2. Deploy Prefect Docker image to the container registry by running GitHub Action `deploy-prefect.yml`
3. Deploy Model application image to the container registry by running GitHub Action `deploy-app.yml`

After Docker images are pushed to the container registry, they are automatically deployed to app instances.

### Done with cloud deployment

Now all the components of the project are running on the cloud!!

## Running local python environment

If you want to run any python code locally, you can activate an Anaconda environment which has all needed dependencies:

1. Install Anaconda
2. Create Anaconda environment by running:
        
        conda env create -f conda-environment.yml

3. Activate the new environment:

        conda activate diabetes-prediction

4. After done, deactivate it by calling:

        conda deactivate

## Components

### Experiment tracking and model registry

The project uses MLFlow for experiment tracking and model registry. The MLFlow server uses Azure Object storage to store model registry.

The project has an MLFLow instance deployed at [https://diabetes-mlflow.azurewebsites.net/](https://diabetes-mlflow.azurewebsites.net/). It has been deployed to Azure by using a Docker image in the [mlfow](mlfow) directory and our GitHub Actions CI/CD.

For experiment tracking, do the following

1. Make sure Anaconda environment `diabetes-prediction` is enabled. You can run `conda activate diabetes-prediction` to enable it.
2. For MLFLow to access Azure Storage to store models, you need to have `AZURE_STORAGE_ACCESS_KEY` environment variable set:

        export AZURE_STORAGE_ACCESS_KEY=$(az storage account keys list -g rg-mlops -n storageaccmflow --query '[0].value' --output tsv) 

3. Run `jupyter notebook --notebook-dir=./experiment-tracking`

If you want to run MLFLow locally, you can run a Docker container as follows:

        docker build -t diabetes-mlfow ./mlflow
        docker container run -it --rm -e AZURE_STORAGE_ACCESS_KEY -p5000:5000 diabetes-mlfow
        

### Workflow orchestration

Workflow Orchestraction uses a Prefect instance at [https://diabetes-prefect.azurewebsites.net/](https://diabetes-prefect.azurewebsites.net/) which is deployed to Azure by using a Docker image in [prefect](prefect) and our GitHub Actions CI/CD.

To deploy and run a workflow once, you can run the following on project root:

        make prefect_run_workflow

The command deploys our workflow to the above Prefect instance, schedules it for execution, and starts a process agent which will execute the workflow.

if you want to run a Prefect server locally, you can run a Docker container as follows:

        docker build -t diabetes-prefect ./mlflow
        export PREFECT_API_URL="http://localhost:4200"
        docker container run -it --rm -e PREFECT_API_URL -p4200:4200 diabetes-prefect

### Model (Prediction app)

The prediction app is using the trained model to predict if a person has diabetes or not. It's a REST API that has been developed by using Python and Flask. It's running at [https://diabetes-app.azurewebsites.net/](https://diabetes-app.azurewebsites.net/).

#### Running locally

If you just want to run the app locally and you have Docker you can run it by building and running a Docker image. Before running the image, make sure you have the environment variable `AZURE_STORAGE_ACCESS_KEY` set.

        docker build -t diabetes-prediction ./app
        docker container run -it --rm -e AZURE_STORAGE_ACCESS_KEY -p80:80 diabetes-app
        

To run the app in your local Python environment develop it, you can do the following:

1. Activate Python environment
2. Ensure the environment variable named `AZURE_STORAGE_ACCESS_KEY` is set
3. Run API by calling:

        python app/predict-diabetes-app.py

4. Do a POST call to [http://localhost:80](http://localhost:80) (or [https://diabetes-app.azurewebsites.net/](https://diabetes-app.azurewebsites.net/)) with the following kind of body:

        {
                "Pregnancies": 2,
                "Glucose": 150,
                "BloodPressure": 70,
                "SkinThickness": 30,
                "Insulin": 169,
                "BMI": 30,
                "DiabetesPedigreeFunction": 3,
                "Age": 35
        }
   
The endpoint will return `true` or `false` whether it predicts the person has diabetes or not. 

## Best Practises

### Integration test 

There is an integrations test, which tests the model application so that Azure Object storage is emulated by using [Azurite](https://github.com/Azure/Azurite).

In order to run the tests, you need to have Azurite and Azure CLI installed. After that you can run those by saying:

        make integration_tests

### Linting and formatting

The following tools are used for linting and auto formatting:

* [isort](https://pycqa.github.io/isort)
* [black](https://github.com/psf/black)
* [pylint](https://www.pylint.org/)

Run the following to execute auto formatters and linters

    make quality_checks

### Makefile

[Makefile](Makefile) is located in the project root.

### Pre-commit hooks

Project has pre-commit hooks: [.pre-commit-config.yaml](.pre-commit-config.yaml).

### CI/CD pipeline

GitHub Actions are used to deploy services to Azure. There are 3 actions:

* To deploy MlFlow Docker image by running GitHub Action [`deploy-mlflow.yml`](.github/workflows/deploy-mlflow.yml)
* To Deploy the Prefect Docker image by running GitHub Action [`deploy-prefect.yml`](.github/workflows/deploy-prefect.yml)
* To Deploy Model Application Docker image by running GitHub Action [`deploy-app.yml`](.github/workflows/deploy-app.yml)
* To apply infrastructure Terraform changes to Azure by running GitHub Action [`deploy-app.yml`](.github/workflows/terraform.yml)

Terraform action is the only which is not automatically deployed on a git push.





