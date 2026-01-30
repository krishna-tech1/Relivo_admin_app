import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.exc import OperationalError
from dotenv import load_dotenv

# Add parent directory
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

def full_debug():
    print("--- STARTING DB DEBUG ---")
    load_dotenv()
    database_url = os.getenv("DATABASE_URL")
    print(f"1. Connection String Found: {bool(database_url)}")
    if database_url:
        masked_url = database_url.replace(database_url.split(":")[2].split("@")[0], "****")
        print(f"   URL: {masked_url}")
    
    try:
        print("\n2. Attempting Engine Creation...")
        engine = create_engine(database_url)
        print("   Engine created.")
        
        print("\n3. Attempting Connection...")
        with engine.connect() as connection:
            print("   ✅ CONNECTION SUCCESSFUL!")
            
            print("\n4. Checking Database Version...")
            result = connection.execute(text("SELECT version();"))
            version = result.fetchone()[0]
            print(f"   DB Version: {version}")
            
            print("\n5. Checking Tables...")
            result = connection.execute(text("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public';"))
            tables = [row[0] for row in result.fetchall()]
            print(f"   Tables found: {tables}")
            
            if 'users' in tables:
                print("\n6. Checking 'users' table columns...")
                result = connection.execute(text("SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'users';"))
                columns = result.fetchall()
                for col in columns:
                    print(f"   - {col[0]}: {col[1]}")
            else:
                print("\n❌ 'users' table NOT found!")

    except Exception as e:
        print(f"\n❌ CONNECTION FAILED: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    full_debug()
