import re
import json

# 🔁 Make sure this file exists in the SAME folder
mapping_file = "train_mapping.txt"

label_map = {}

with open(mapping_file, "r", encoding="utf-8") as f:
    for line in f:
        left, right = line.strip().split("\t")

        # Extract disease name
        disease = left.split("/")[2]
        disease = disease.replace("___", " ").replace("_", " ")

        # Extract class number
        class_id = int(re.search(r"train/(\d+)", right).group(1))

        label_map[class_id] = disease

# Sort by class id
label_map = dict(sorted(label_map.items()))

# ✅ SAVE WITH CORRECT FILE NAME
with open("labels.json", "w", encoding="utf-8") as f:
    json.dump(label_map, f, indent=2)

print("✅ labels.json created successfully")
print("🔢 Number of classes:", len(label_map))
print("📋 First 5 entries:", list(label_map.items())[:5])
