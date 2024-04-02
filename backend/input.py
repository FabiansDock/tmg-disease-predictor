from architecture import TinyVGG
from typing import List
from pathlib import Path
import torch
from torchvision import transforms, io
from torch import nn
import matplotlib.pyplot as plt

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

        # Plotting our prediction
        plt.imshow(input_image_tensor_transformed.permute(1, 2, 0))
        if class_names:
            plt.title(
                f'Prediction: {class_names[prediction_label]} | Probability: {prediction_probabilities.max()}')
        plt.axis(False)
        plt.show()

def predictor(filename: str, class_names: List[str]):

    MODELS_PATH = Path("models/")

    MODELS_NAME = "plant_category.pth"
    MODELS_SAVE_PATH = MODELS_PATH / MODELS_NAME

    instance_model = torch.load(f=MODELS_SAVE_PATH, map_location=torch.device("cpu"))

    input_image_path = Path("th.jpg")

    instance_model.eval()

    custom_image_predictor(instance_model, str(input_image_path), class_names)


predictor("", ['grape', 'mango', 'tomato'])