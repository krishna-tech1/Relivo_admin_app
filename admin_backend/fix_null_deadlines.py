"""
Script to fix NULL deadlines in production database via API endpoint

This script calls the /grants/admin/fix-null-deadlines endpoint to update
all grants with NULL deadlines to a default date (30 days from now).
"""

import requests
import json

# Production API URL
API_URL = "https://relivo-admin-app.onrender.com"

def fix_null_deadlines(admin_token: str):
    """
    Call the fix-null-deadlines endpoint
    
    Args:
        admin_token: Admin JWT token for authentication
    """
    endpoint = f"{API_URL}/grants/admin/fix-null-deadlines"
    
    headers = {
        "Authorization": f"Bearer {admin_token}",
        "Content-Type": "application/json"
    }
    
    try:
        print(f"Calling endpoint: {endpoint}")
        response = requests.post(endpoint, headers=headers)
        
        print(f"Status Code: {response.status_code}")
        print(f"Response: {json.dumps(response.json(), indent=2)}")
        
        if response.status_code == 200:
            result = response.json()
            if "error" in result:
                print(f"\n❌ Error: {result['error']}")
            else:
                print(f"\n✅ Success! Fixed {result.get('fixed', 0)} grants")
        else:
            print(f"\n❌ Request failed with status {response.status_code}")
            
    except Exception as e:
        print(f"\n❌ Exception occurred: {str(e)}")

if __name__ == "__main__":
    print("=" * 60)
    print("Fix NULL Deadlines in Production Database")
    print("=" * 60)
    print("\nThis script will fix grants with NULL deadlines.")
    print("You need an admin JWT token to run this.\n")
    
    # Get admin token from user
    admin_token = input("Enter your admin JWT token: ").strip()
    
    if not admin_token:
        print("❌ No token provided. Exiting.")
        exit(1)
    
    print("\nProceeding with fix...")
    fix_null_deadlines(admin_token)
