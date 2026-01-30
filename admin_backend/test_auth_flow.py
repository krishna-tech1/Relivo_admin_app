import requests
import random
import string
import time

BASE_URL = "http://localhost:8000"

def get_random_string(length=8):
    return ''.join(random.choices(string.ascii_lowercase, k=length))

def test_auth_flow():
    # Wait for server to be ready?
    # We'll just try connecting
    
    # 1. Register
    email = f"test_{get_random_string()}@example.com"
    password = "securepassword123"
    print(f"\n1. Registering user: {email}")
    
    try:
        response = requests.post(f"{BASE_URL}/auth/register", json={
            "email": email,
            "password": password,
            "full_name": "Test User"
        })
    except requests.exceptions.ConnectionError as e:
        print(f"\n❌ Connection Error: Could not reach {BASE_URL}")
        print("Please ensure the backend server is running via: python -m uvicorn app.main:app")
        print(f"Details: {e}")
        return

    if response.status_code != 200:
        print(f"Registration failed: {response.text}")
        return

    data = response.json()
    print(f"Registration successful. Response: {data}")
    
    # Extract debug verification code (backend includes it for testing)
    verification_code = data.get("debug_code")
    if not verification_code:
        print("No verification code found in response (check backend debug mode).")
        return

    # 2. Verify
    print(f"\n2. Verifying email with code: {verification_code}")
    response = requests.post(f"{BASE_URL}/auth/verify", json={
        "email": email,
        "code": verification_code
    })
    
    if response.status_code != 200:
        print(f"Verification failed: {response.text}")
        return
        
    print(f"Verification successful. Response: {response.json()}")

    # 3. Login
    print(f"\n3. Logging in...")
    response = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": password
    })
    
    if response.status_code != 200:
        print(f"Login failed: {response.text}")
        return
        
    data = response.json()
    access_token = data.get("access_token")
    print(f"Login successful. Token type: {data.get('token_type')}")

    # 4. Get Current User (Protected Route)
    print(f"\n4. Fetching protected user profile...")
    headers = {"Authorization": f"Bearer {access_token}"}
    response = requests.get(f"{BASE_URL}/auth/me", headers=headers)
    
    if response.status_code != 200:
        print(f"Fetch profile failed: {response.text}")
        return
        
    user_profile = response.json()
    print(f"Profile fetched successfully!")
    print(f"ID: {user_profile.get('id')}")
    print(f"Email: {user_profile.get('email')}")
    print(f"Role: {user_profile.get('role')}")
    print("\n✅ Authentication flow test PASSED!")

if __name__ == "__main__":
    test_auth_flow()
