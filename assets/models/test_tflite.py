import tensorflow as tf
import numpy as np
from PIL import Image # Pillow for image manipulation

# 1. Load the TFLite model
interpreter = tf.lite.Interpreter(model_path=r"C:\Users\hp\Desktop\flavorgen\assets\models\best_float16.tflite")
interpreter.allocate_tensors()

# 2. Get input and output details
input_details = interpreter.get_input_details()
output_details = interpreter.get_output_details()
print("Input Details:", input_details)
print("Output Details:", output_details)

# 3. Load and preprocess an image (use an image you expect to have detections)
img_path = r"C:\Users\hp\Desktop\Datasets\Nouveau dossier (3)\apple.orange.jpg" # Make sure this image has objects your model should detect
img = Image.open(img_path).convert('RGB')
img_resized = img.resize((640, 640)) # Assuming your input_details[0]['shape'] is [1, 640, 640, 3]

input_data = np.array(img_resized, dtype=np.float32) / 255.0 # Normalize to 0-1
input_data = np.expand_dims(input_data, axis=0) # Add batch dimension

# Check if your model is float16 input
if input_details[0]['dtype'] == np.float16:
    input_data = input_data.astype(np.float16)

# 4. Set the tensor
interpreter.set_tensor(input_details[0]['index'], input_data)

# 5. Run inference
interpreter.invoke()

# 6. Get the output tensor
output_data = interpreter.get_tensor(output_details[0]['index']) # Shape (1, 35, 8400)

print("Output Shape:", output_data.shape)

# Assuming class scores start at index 4 of the 35 attributes
# The first 4 attributes are typically [x_center, y_center, width, height]
# The remaining 31 attributes are class probabilities

num_proposals = output_data.shape[2] # Should be 8400
num_attributes = output_data.shape[1] # Should be 35
num_classes = num_attributes - 4 # Assuming 4 for bbox coords

max_overall_confidence = 0.0
best_proposal_index = -1
best_class_index = -1
best_class_score_in_best_proposal = 0.0
best_proposal_bbox = []

for i in range(num_proposals):
    proposal = output_data[0, :, i]
    bbox_coords = proposal[:4] # x, y, w, h (or similar, depending on model)
    class_scores = proposal[4:] # Scores for each class

    current_max_class_score = np.max(class_scores)
    current_class_index = np.argmax(class_scores)

    if current_max_class_score > max_overall_confidence:
        max_overall_confidence = current_max_class_score
        best_proposal_index = i
        best_class_index = current_class_index
        best_class_score_in_best_proposal = current_max_class_score
        best_proposal_bbox = bbox_coords

print(f"\n--- Overall Best Detection ---")
print(f"Highest confidence score found: {max_overall_confidence:.6f}")
if best_proposal_index != -1:
    print(f"Found in proposal index: {best_proposal_index}")
    print(f"Class index with highest score: {best_class_index}")
    # If you have a list of class names, you can map best_class_index to a name here
    # print(f"Class name: {class_names[best_class_index]}") 
    print(f"Bounding box of this proposal (raw): {best_proposal_bbox}")
else:
    print("No proposal had a confidence score > 0.")

# For detailed inspection if needed:
# print("\nRaw Output Data (first few values of the proposal with highest confidence):")
# if best_proposal_index != -1:
# print(output_data[0, :, best_proposal_index])
# else:
# print("No best proposal to show.")

# You might still want to see the original lines for comparison or specific checks:
# print("\n--- Original Debug Prints (for reference) ---")
# print("Raw Output Data (first 10 values for first 5 proposals):")
# print(output_data[0, :, :5].T) # Transpose to see proposals as columns

# print("\nClass scores for first proposal (raw):", output_data[0, 4:, 0])
# print("Max class score for first proposal:", np.max(output_data[0, 4:, 0]))
