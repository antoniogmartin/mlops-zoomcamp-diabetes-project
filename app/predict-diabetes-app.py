import os

import pandas as pd
from flask import Flask, jsonify, request

import mlflow

MODEL_PATH = os.getenv('RUN_ID', '1/f636a697a38d4440b294dc854fbafd40/artifacts/model')

logged_model = (
    f'wasbs://storagecontmflow@storageaccmflow.blob.core.windows.net/{MODEL_PATH}'
)

model = mlflow.pyfunc.load_model(logged_model)

app = Flask(__name__)


@app.route('/', methods=['POST'])
def predict_price():
    input_data = request.json

    # List of required keys
    required_keys = [
        'Pregnancies',
        'Glucose',
        'BloodPressure',
        'SkinThickness',
        'Insulin',
        'BMI',
        'DiabetesPedigreeFunction',
        'Age',
    ]

    # Check if all required keys are present
    missing_keys = [key for key in required_keys if key not in input_data]

    if missing_keys:
        return jsonify({"error": f"Missing keys: {', '.join(missing_keys)}"}), 400

    input_df = pd.DataFrame(input_data, index=[0])
    result = {'Outcome': bool(model.predict(input_df)[0])}
    return jsonify(result)


if __name__ == "__main__":
    app.run(debug=True, host='0.0.0.0', port=80)
