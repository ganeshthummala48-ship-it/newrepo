import os
import subprocess
import time

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
MODEL_DIR = os.path.join(BASE_DIR, "model")
MODEL_FILE = os.path.join(MODEL_DIR, "plant_disease_model.h5")

# The Kaggle kernel that contains the trained plant disease model output
KAGGLE_KERNEL = "borelange/plant-disease-detection"

def download_model_if_missing():
    """
    Checks if the plant disease model exists. If not, attempts to download it
    via the Kaggle API from the specified kernel's output.
    Required: The Kaggle API token (kaggle.json) must be properly configured on the host machine.
    """
    if os.path.exists(MODEL_FILE):
        print(f"Model file already exists at {MODEL_FILE}")
        return

    print("Plant disease model not found. Attempting to download from Kaggle...")
    
    # Ensure credentials are set from environment variables (Secrets in Render/GitHub)
    os.environ["KAGGLE_USERNAME"] = os.getenv("KAGGLE_USERNAME", "gnshthmmla")
    os.environ["KAGGLE_KEY"] = os.getenv("KAGGLE_KEY", "eee740f86b73aa8d525ecc07ac229335")

    # Ensure model directory exists
    os.makedirs(MODEL_DIR, exist_ok=True)

    try:
        # Check if kaggle is installed
        subprocess.run(["kaggle", "--version"], check=True, capture_output=True)
    except FileNotFoundError:
        print("Error: 'kaggle' python package is not installed. Run 'pip install kaggle'.")
        return
    except subprocess.CalledProcessError:
         print("Error: 'kaggle' is installed but failed to run. Check your python path or installation.")
         return
         
    print(f"Running 'kaggle kernels output {KAGGLE_KERNEL} -p {MODEL_DIR}'...")
    
    max_retries = 3
    for attempt in range(max_retries):
        try:
            # Run the Kaggle download command
            result = subprocess.run(
                ["kaggle", "kernels", "output", KAGGLE_KERNEL, "-p", MODEL_DIR],
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                print(f"Download completed successfully!")
                break
            else:
                print(f"Attempt {attempt+1} failed ({result.returncode})")
                if attempt == max_retries - 1:
                    print("All download attempts failed.")
                    print("Error:", result.stderr)
                    return
                time.sleep(5) # Wait before retry

        except Exception as e:
            print(f"An error occurred: {e}")
            return

    # Post-download check and rename
    downloaded_files = os.listdir(MODEL_DIR)
    h5_files = [f for f in downloaded_files if f.endswith('.h5') and f != 'plant_disease_model.h5']
    if not os.path.exists(MODEL_FILE) and h5_files:
         old_path = os.path.join(MODEL_DIR, h5_files[0])
         os.rename(old_path, MODEL_FILE)
         print(f"Renamed {h5_files[0]} to plant_disease_model.h5")
    elif os.path.exists(MODEL_FILE):
         print("Confirmed: plant_disease_model.h5 is ready.")

if __name__ == "__main__":
    download_model_if_missing()
