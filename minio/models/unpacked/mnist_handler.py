# import io

# from PIL import Image
from torchvision import transforms

# from ts.torch_handler.image_classifier import ImageClassifier


# class MNISTDigitClassifier(ImageClassifier):
#     """
#     MNISTDigitClassifier handler class. This handler extends class ImageClassifier from image_classifier.py, a
#     default handler. This handler takes an image and returns the number in that image.

#     Here method postprocess() has been overridden while others are reused from parent class.
#     """

#     image_processing = transforms.Compose([
#         transforms.ToTensor(),
#         transforms.Normalize((0.1307,), (0.3081,))
#     ])

#     def postprocess(self, data):
#         return data.argmax(1).tolist()


from ts.torch_handler.base_handler import BaseHandler
import torch
import torch.nn.functional as F

class MNISTHandler(BaseHandler):

    # image_processing = transforms.Compose([
    #     transforms.ToTensor(),
    #     transforms.Normalize((0.1307,), (0.3081,))
    # ])

    def initialize(self, context):
        super().initialize(context)
        self.device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
        self.model.to(self.device)


    def preprocess(self, data):
        # Extract the input data from the JSON payload
        body = data[0].get("body")
        inputs = body.get("inputs")
        input_data = inputs[0].get("data")
        input_shape = inputs[0].get("shape")  # Extract the 'shape' field

        # Convert the input data to a tensor
        input_tensor = torch.tensor(input_data, dtype=torch.float32)

        # Reshape the tensor to match the shape specified in the payload
        input_tensor = input_tensor.view(input_shape)

        # Ensure the input tensor has the correct shape
        if input_tensor.ndim == 3:
            input_tensor = input_tensor.unsqueeze(0)  # Add batch dimension if missing

        input_tensor = input_tensor.to(self.device)  # Move tensor to the same device as the model

        return input_tensor
    

    def inference(self, data):
        # Perform inference
        with torch.no_grad():
            output = self.model(data)
        return output

    def postprocess(self, data):
        # Convert the output to a list
        # Apply softmax to convert logits to probabilities
        probabilities = F.softmax(data, dim=1)
        # Get the predicted class (digit) with the highest probability
        predicted_digit = torch.argmax(probabilities, dim=1).item()
        return [{"predicted_digit": predicted_digit, "probabilities": probabilities.tolist()}]