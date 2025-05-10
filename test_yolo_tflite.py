import tensorflow as tf
import numpy as np
from PIL import Image

# Charger le modèle
interpreter = tf.lite.Interpreter(model_path="assets/models/yolo11n_float16.tflite")
interpreter.allocate_tensors()

# Charger une image de test et la prétraiter
# Solution 1 : doubles antislashs
img = Image.open("C:\\Users\\hp\\Downloads\\ed-o-neil-AvvdZlhDowA-unsplash.jpg").resize((640, 640))

# Solution 2 : raw string
# img = Image.open(r"C:\Users\hp\Downloads\ed-o-neil-AvvdZlhDowA-unsplash.jpg").resize((640, 640))

# Solution 3 : slashs
# img = Image.open("C:/Users/hp/Downloads/ed-o-neil-AvvdZlhDowA-unsplash.jpg").resize((640, 640))

input_data = np.expand_dims(np.array(img, dtype=np.float32) / 255.0, axis=0)

# Mettre l'image dans le modèle
input_index = interpreter.get_input_details()[0]['index']
interpreter.set_tensor(input_index, input_data)
interpreter.invoke()

# Récupérer les résultats
output_details = interpreter.get_output_details()
output_data = interpreter.get_tensor(output_details[0]['index'])

# Charger les labels
with open("assets/models/labels.txt", "r") as f:
    labels = [line.strip() for line in f.readlines()]

# YOLOv8 TFLite output: [1, 8400, num_classes+5]
preds = np.squeeze(output_data)  # [8400, num_classes+5]

confidence_threshold = 0.1

detected = []
for pred in preds:
    obj_conf = pred[4]
    if obj_conf < confidence_threshold:
        continue
    class_scores = pred[5:]
    class_id = np.argmax(class_scores)
    class_score = class_scores[class_id]
    if class_score < confidence_threshold:
        continue
    label = labels[class_id] if class_id < len(labels) else f"class_{class_id}"
    detected.append((label, float(obj_conf), float(class_score)))
    print(f"class_id: {class_id}, labels length: {len(labels)}")

if detected:
    print("Ingrédients détectés :")
    for label, obj_conf, class_score in detected:
        print(f"- {label} (obj_conf={obj_conf:.2f}, class_score={class_score:.2f})")
else:
    print("Aucun ingrédient détecté.")