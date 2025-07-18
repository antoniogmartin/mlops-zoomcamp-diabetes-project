import pandas as pd
from sklearn.metrics import accuracy_score, classification_report
from sklearn.linear_model import LogisticRegression
from sklearn.model_selection import GridSearchCV, train_test_split

import mlflow
from prefect import flow, task


@task(retries=3)
def load_data():
    df = pd.read_csv('./data/diabetes.csv')
    return df


def prepare_data(data):
    X = data.drop('Outcome', axis=1)  # 'Outcome' is the target column
    y = data['Outcome']

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42
    )

    return X_train, X_test, y_train, y_test


@task
def train_model(X_train, y_train):
    model = LogisticRegression()
    model.fit(X_train, y_train)
    return model


@task
def evalutate_model(model, X_test, y_test):
    y_pred = model.predict(X_test)

    # Check accuracy and other metrics
    print("Accuracy:", accuracy_score(y_test, y_pred))
    print("Classification Report:\n", classification_report(y_test, y_pred))


@task
def hpo(X_train, X_test, y_train, y_test):
    # Define hyperparameters and their values/ranges
    with mlflow.start_run():
        param_grid = {
            'C': [0.001, 0.01, 0.1, 1, 10, 100],
            'penalty': ['l1', 'l2'],
            'solver': ['liblinear', 'saga'],
        }

        # Create a base model with increased max_iter
        logistic = LogisticRegression(max_iter=1000)

        # Instantiate the grid search model
        grid_search = GridSearchCV(
            estimator=logistic,
            param_grid=param_grid,
            cv=5,
            verbose=1,
            scoring='accuracy',
        )

        # Fit the grid search to the data
        grid_search.fit(X_train, y_train)

        # Get the best parameters from the grid search
        best_params = grid_search.best_params_
        print(f"Best Parameters: {best_params}")

        # You can also get the best estimator directly and use it for predictions
        best_model = grid_search.best_estimator_

        # best_model = LogisticRegression(C=1, penalty='l1', solver='liblinear', max_iter=1000)

        # Fit the model to the training data
        best_model.fit(X_train, y_train)

        # Predictions on the test data
        y_pred = best_model.predict(X_test)

        # Evaluate the model using the test data
        print("Accuracy:", accuracy_score(y_test, y_pred))
        print("Classification Report:\n", classification_report(y_test, y_pred))

        for k in grid_search.best_params_.keys():
            mlflow.log_param(k, grid_search.best_params_[k])

        mlflow.log_metric("accuracy", accuracy_score(y_test, y_pred))

        mlflow.sklearn.log_model(grid_search.best_estimator_, "model")

@flow
def main_flow():
    mlflow.set_tracking_uri("https://diabetes-mlflow.azurewebsites.net")
    mlflow.set_experiment("diabetes-training")

    data = load_data()
    X_train, X_test, y_train, y_test = prepare_data(data)
    model = train_model(X_train, y_train)
    evalutate_model(model, X_test, y_test)

    hpo(X_train, X_test, y_train, y_test)


if __name__ == "__main__":
    main_flow()
