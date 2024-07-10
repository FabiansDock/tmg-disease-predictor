import os
from architecture import TinyVGG
from pathlib import Path
from typing import List
from flask import Flask, request, jsonify
import torch
from torch import nn
import torchvision.transforms as transforms
from torchvision import io
import sqlite3

app = Flask(__name__)


def custom_image_predictor(model: nn.Module,
                           image_path: str,
                           class_names: List[str] = None,
                           transform=None,
                           ):

    image_transform = transforms.Compose([
        transforms.Resize(size=(224, 224))
    ])

    input_image_tensor_uint8 = io.read_image(image_path) / 255
    input_image_tensor = input_image_tensor_uint8.type(torch.float32)
    input_image_tensor_transformed = image_transform(
        input_image_tensor)

    with torch.no_grad():
        input_image_pred = model(input_image_tensor_transformed.unsqueeze(0))

    prediction_probabilities = torch.softmax(input_image_pred, dim=1)
    prediction_label = torch.argmax(
        prediction_probabilities, dim=1)

    return {'Prediction': f'{class_names[prediction_label]}', 'Probability': f'{prediction_probabilities.max()}'}


def predictor(model_name: str, filename: str, class_names: List[str]):
    MODELS_PATH = Path("models/")

    MODELS_NAME = f"{model_name}.pth"
    MODELS_SAVE_PATH = MODELS_PATH / MODELS_NAME

    instance_model = torch.load(
        f=MODELS_SAVE_PATH, map_location=torch.device("cpu"))

    input_image_path = Path(filename)

    instance_model.eval()

    return custom_image_predictor(instance_model, str(input_image_path), class_names)


@app.route('/predict', methods=['POST'])
def predict():
    class_names = ['grape', 'mango', 'tomato']
    if 'image' not in request.files:
        return jsonify({'error': 'No image provided'})

    input_dir = "input"
    if not os.path.exists(input_dir):
        os.makedirs(input_dir)

    image_file = request.files['image']
    image_path = os.path.join(input_dir, image_file.filename)
    image_file.save(image_path)

    match request.form["category"]:
        case '0':
            class_names = ['Esca', 'Healthy', 'Leaf Blight']
            result = predictor('grape_disease_category',
                               image_path, class_names)
            prediction_id = class_names.index(result.get("Prediction"))
            if result.get("Prediction") == 'Healthy':
                prediction_id = -1
            if result.get("Prediction") == 'Leaf Blight':
                prediction_id = 1
        case '1':
            class_names = ['Anthracnose',
                           'Healthy', 'Mango Powdery Mildew']
            result = predictor('mango_disease_category',
                               image_path, class_names)
            prediction_id = class_names.index(result.get("Prediction"))
            if result.get("Prediction") == 'Anthracnose':
                prediction_id = 2
            if result.get("Prediction") == 'Healthy':
                prediction_id = -1
            if result.get("Prediction") == 'Mango Powdery Mildew':
                prediction_id = 3
        case '2':
            class_names = ['Bacterial Spot',
                           'Healthy', 'Tomato Yellow Leaf Curl Virus']
            result = predictor('tomato_disease_category',
                               image_path, class_names)
            prediction_id = class_names.index(result.get("Prediction"))
            if result.get("Prediction") == 'Bacterial Spot':
                prediction_id = 4
            if result.get("Prediction") == 'Healthy':
                prediction_id = -1
            if result.get("Prediction") == 'Tomato Yellow Leaf Curl Virus':
                prediction_id = 5

    conn = sqlite3.connect('database.db')
    cursor = conn.cursor()

    query = f"SELECT * FROM Disease WHERE id=={prediction_id+1}"
    cursor.execute(query)

    details = cursor.fetchall()

    cursor.close()
    conn.close()
    os.remove(image_path)
    if details:
        return jsonify({**result, "Disease Name": details[0][1], "causitive_agent": details[0][2], "symptoms": details[0][3], "treatment": details[0][4]})
    return jsonify({"message": "Healthy"})


if __name__ == '__main__':
    app.run(debug=True)
