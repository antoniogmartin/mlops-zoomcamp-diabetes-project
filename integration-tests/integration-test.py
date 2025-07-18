import requests

payload = {
    "Pregnancies": 2,
    "Glucose": 150,
    "BloodPressure": 70,
    "SkinThickness": 30,
    "Insulin": 169,
    "BMI": 30,
    "DiabetesPedigreeFunction": 3,
    "Age": 35,
}
url = 'http://localhost'

actual_response = requests.post(url, json=payload, timeout=5).json()

# print('actual response:')
# print(json.dumps(actual_response, indent=2))

expected_response = {'Outcome': True}

assert expected_response == actual_response
