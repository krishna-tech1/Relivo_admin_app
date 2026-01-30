"""
Deployment Verification Script
Run this after deploying to verify everything is working
"""
import requests
import sys

# Configuration
BASE_URL = "https://relivo-app.onrender.com"  # Change to your deployment URL
# For local testing, use: BASE_URL = "http://localhost:8000"


def test_root_endpoint():
    """Test root endpoint"""
    print("\n1. Testing root endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Root endpoint working")
            print(f"   Version: {data.get('version')}")
            print(f"   Status: {data.get('status')}")
            return True
        else:
            print(f"   ❌ Root endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Root endpoint error: {e}")
        return False


def test_health_endpoint():
    """Test health check endpoint"""
    print("\n2. Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Health endpoint working")
            print(f"   Status: {data.get('status')}")
            print(f"   Database: {data.get('database')}")
            return data.get('database') == 'connected'
        else:
            print(f"   ❌ Health endpoint failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"   ❌ Health endpoint error: {e}")
        return False


def test_public_grants_endpoint():
    """Test public grants endpoint"""
    print("\n3. Testing public grants endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/grants/public", timeout=10)
        if response.status_code == 200:
            data = response.json()
            print(f"   ✅ Public grants endpoint working")
            print(f"   Grants found: {len(data)}")
            if len(data) > 0:
                print(f"   Sample grant: {data[0].get('title', 'N/A')}")
            return True
        else:
            print(f"   ❌ Public grants endpoint failed: {response.status_code}")
            print(f"   Response: {response.text}")
            return False
    except Exception as e:
        print(f"   ❌ Public grants endpoint error: {e}")
        return False


def test_cors():
    """Test CORS configuration"""
    print("\n4. Testing CORS configuration...")
    try:
        response = requests.options(
            f"{BASE_URL}/grants/public",
            headers={
                'Origin': 'http://localhost:3000',
                'Access-Control-Request-Method': 'GET'
            },
            timeout=10
        )
        cors_header = response.headers.get('Access-Control-Allow-Origin')
        if cors_header:
            print(f"   ✅ CORS configured: {cors_header}")
            return True
        else:
            print(f"   ⚠️  CORS header not found")
            return False
    except Exception as e:
        print(f"   ❌ CORS test error: {e}")
        return False


def main():
    """Run all verification tests"""
    print("=" * 60)
    print("DEPLOYMENT VERIFICATION")
    print(f"Testing: {BASE_URL}")
    print("=" * 60)
    
    results = {
        "Root Endpoint": test_root_endpoint(),
        "Health Check": test_health_endpoint(),
        "Public Grants": test_public_grants_endpoint(),
        "CORS": test_cors()
    }
    
    print("\n" + "=" * 60)
    print("RESULTS SUMMARY")
    print("=" * 60)
    
    for test_name, passed in results.items():
        status = "✅ PASS" if passed else "❌ FAIL"
        print(f"{test_name:.<40} {status}")
    
    total_tests = len(results)
    passed_tests = sum(results.values())
    
    print("\n" + "=" * 60)
    print(f"Total: {passed_tests}/{total_tests} tests passed")
    print("=" * 60)
    
    if passed_tests == total_tests:
        print("\n🎉 All tests passed! Deployment is healthy.")
        sys.exit(0)
    else:
        print("\n⚠️  Some tests failed. Please check the logs above.")
        sys.exit(1)


if __name__ == "__main__":
    main()
