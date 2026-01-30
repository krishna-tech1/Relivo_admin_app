"""
Test Script for Grants.gov Integration

This script tests the core functionality of the Grants.gov integration.
Run this after migration to verify everything works.
"""

import sys
import os

# Add parent directory to path
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from db.session import SessionLocal
from db import models
from app.services.grants_gov_importer import GrantsGovImporter
from datetime import datetime

def test_database_schema():
    """Test that new columns exist in database"""
    print("=" * 60)
    print("Testing Database Schema...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        # Try to query with new fields
        grant = db.query(models.Grant).first()
        
        if grant:
            print("✅ Found existing grant")
            print(f"   Title: {grant.title}")
            print(f"   Organizer: {getattr(grant, 'organizer', 'N/A')}")
            print(f"   Is Verified: {getattr(grant, 'is_verified', 'N/A')}")
            print(f"   Is Active: {getattr(grant, 'is_active', 'N/A')}")
            print(f"   Source: {getattr(grant, 'source', 'N/A')}")
            print(f"   Refugee Country: {getattr(grant, 'refugee_country', 'N/A')}")
        else:
            print("ℹ️  No grants in database yet")
        
        print("\n✅ Database schema is correct!")
        return True
        
    except Exception as e:
        print(f"\n❌ Database schema test failed: {str(e)}")
        print("   Did you run the migration script?")
        return False
    finally:
        db.close()


def test_create_manual_grant():
    """Test creating a manual grant"""
    print("\n" + "=" * 60)
    print("Testing Manual Grant Creation...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        # Create a test grant
        test_grant = models.Grant(
            title="Test Grant - Manual",
            organizer="Test Organization",
            description="This is a test grant created manually",
            eligibility="Test eligibility criteria",
            deadline=datetime(2026, 12, 31),
            apply_url="https://example.com/apply",
            source="manual",
            is_verified=False,
            is_active=True,
            refugee_country=None
        )
        
        db.add(test_grant)
        db.commit()
        db.refresh(test_grant)
        
        print(f"✅ Created manual grant with ID: {test_grant.id}")
        print(f"   Title: {test_grant.title}")
        print(f"   Source: {test_grant.source}")
        print(f"   Is Verified: {test_grant.is_verified}")
        
        # Clean up
        db.delete(test_grant)
        db.commit()
        print("✅ Test grant cleaned up")
        
        return True
        
    except Exception as e:
        print(f"❌ Manual grant creation failed: {str(e)}")
        db.rollback()
        return False
    finally:
        db.close()


def test_verification_workflow():
    """Test grant verification workflow"""
    print("\n" + "=" * 60)
    print("Testing Verification Workflow...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        # Create unverified grant
        grant = models.Grant(
            title="Test Grant - Verification",
            organizer="Test Org",
            description="Testing verification",
            apply_url="https://example.com",
            source="manual",
            is_verified=False,
            is_active=True
        )
        
        db.add(grant)
        db.commit()
        db.refresh(grant)
        
        print(f"✅ Created unverified grant (ID: {grant.id})")
        print(f"   Is Verified: {grant.is_verified}")
        
        # Verify the grant
        grant.is_verified = True
        grant.refugee_country = "Germany"
        db.commit()
        db.refresh(grant)
        
        print(f"✅ Verified grant")
        print(f"   Is Verified: {grant.is_verified}")
        print(f"   Refugee Country: {grant.refugee_country}")
        
        # Test public query (verified & active)
        public_grants = db.query(models.Grant).filter(
            models.Grant.is_verified == True,
            models.Grant.is_active == True
        ).all()
        
        print(f"✅ Public query returned {len(public_grants)} grants")
        
        # Clean up
        db.delete(grant)
        db.commit()
        print("✅ Test grant cleaned up")
        
        return True
        
    except Exception as e:
        print(f"❌ Verification workflow test failed: {str(e)}")
        db.rollback()
        return False
    finally:
        db.close()


def test_duplicate_prevention():
    """Test that duplicate external_id is prevented"""
    print("\n" + "=" * 60)
    print("Testing Duplicate Prevention...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        # Create grant with external_id
        grant1 = models.Grant(
            title="Test Grant 1",
            organizer="Test Org",
            apply_url="https://example.com",
            source="grants.gov",
            external_id="TEST-123456",
            is_verified=False,
            is_active=True
        )
        
        db.add(grant1)
        db.commit()
        print(f"✅ Created grant with external_id: TEST-123456")
        
        # Try to create duplicate
        grant2 = models.Grant(
            title="Test Grant 2 (Duplicate)",
            organizer="Test Org",
            apply_url="https://example.com",
            source="grants.gov",
            external_id="TEST-123456",  # Same external_id
            is_verified=False,
            is_active=True
        )
        
        try:
            db.add(grant2)
            db.commit()
            print("❌ Duplicate was allowed (should have failed!)")
            success = False
        except Exception as e:
            db.rollback()
            print(f"✅ Duplicate correctly prevented: {type(e).__name__}")
            success = True
        
        # Clean up
        db.delete(grant1)
        db.commit()
        print("✅ Test grant cleaned up")
        
        return success
        
    except Exception as e:
        print(f"❌ Duplicate prevention test failed: {str(e)}")
        db.rollback()
        return False
    finally:
        db.close()


def test_import_service():
    """Test the import service (without actually importing)"""
    print("\n" + "=" * 60)
    print("Testing Import Service...")
    print("=" * 60)
    
    db = SessionLocal()
    try:
        importer = GrantsGovImporter(db)
        print("✅ GrantsGovImporter initialized")
        print(f"   XML URL: {importer.GRANTS_GOV_XML_URL}")
        
        # Test date parsing
        test_dates = [
            "01/31/2026",
            "2026-01-31",
            "01-31-2026"
        ]
        
        for date_str in test_dates:
            parsed = importer._parse_date(date_str)
            if parsed:
                print(f"✅ Parsed date: {date_str} → {parsed}")
            else:
                print(f"⚠️  Could not parse: {date_str}")
        
        print("\n✅ Import service is ready")
        print("   To test actual import, run:")
        print("   POST /api/grants/admin/import")
        
        return True
        
    except Exception as e:
        print(f"❌ Import service test failed: {str(e)}")
        return False
    finally:
        db.close()


def run_all_tests():
    """Run all tests"""
    print("\n" + "=" * 60)
    print("GRANTS.GOV INTEGRATION TEST SUITE")
    print("=" * 60)
    
    tests = [
        ("Database Schema", test_database_schema),
        ("Manual Grant Creation", test_create_manual_grant),
        ("Verification Workflow", test_verification_workflow),
        ("Duplicate Prevention", test_duplicate_prevention),
        ("Import Service", test_import_service),
    ]
    
    results = []
    for test_name, test_func in tests:
        try:
            result = test_func()
            results.append((test_name, result))
        except Exception as e:
            print(f"\n❌ Test '{test_name}' crashed: {str(e)}")
            results.append((test_name, False))
    
    # Summary
    print("\n" + "=" * 60)
    print("TEST SUMMARY")
    print("=" * 60)
    
    passed = sum(1 for _, result in results if result)
    total = len(results)
    
    for test_name, result in results:
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}: {test_name}")
    
    print("\n" + "=" * 60)
    print(f"Results: {passed}/{total} tests passed")
    print("=" * 60)
    
    if passed == total:
        print("\n🎉 All tests passed! Integration is working correctly.")
        print("\nNext steps:")
        print("1. Start backend: uvicorn app.main:app --reload")
        print("2. Test import: POST /api/grants/admin/import")
        print("3. Update frontend to use new endpoints")
    else:
        print("\n⚠️  Some tests failed. Please review the errors above.")
        print("   Make sure you ran the migration script first:")
        print("   python migrate_grants_schema.py")


if __name__ == "__main__":
    run_all_tests()
