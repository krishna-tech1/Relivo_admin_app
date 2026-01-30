
import sys
import os

# Add current directory to sys.path to ensure imports work as expected
sys.path.append(os.getcwd())

try:
    print("Attempting to import app.main...")
    from app import main
    print("Success: app.main imported.")
except Exception as e:
    print(f"Error importing app.main: {e}")
    import traceback
    traceback.print_exc()
