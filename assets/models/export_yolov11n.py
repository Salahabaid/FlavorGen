from ultralytics import YOLO

# Charger le modèle entraîné
model = YOLO("yolo11n.pt")  # Mets ici le chemin vers ton modèle entraîné

# (Optionnel) Tester le modèle sur quelques images pour vérifier la qualité
# results = model("chemin/vers/image.jpg", conf=0.25)
# results.show()

# Exporter au format TFLite avec quantification float16 (plus précis que int8)
model.export(format='tflite', int8=False, half=True, dynamic=False)

# Pour une quantification int8 (plus petit mais parfois moins précis) :
# model.export(format='tflite', int8=True)