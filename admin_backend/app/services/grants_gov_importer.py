"""
Grants.gov XML Import Service

Downloads, parses, and imports grant data from Grants.gov public XML extract.
"""

import requests
import zipfile
import io
import xml.etree.ElementTree as ET
from datetime import datetime
from typing import List, Dict, Tuple
from sqlalchemy.orm import Session
from db import models


class GrantsGovImporter:
    """Service for importing grants from Grants.gov XML extract"""
    
    # Grants.gov XML extract URL (latest version)
    GRANTS_GOV_XML_URL = "https://www.grants.gov/xml/extract/GrantsDBExtractv2.zip"
    
    def __init__(self, db: Session):
        self.db = db
        self.imported_count = 0
        self.skipped_count = 0
        self.errors: List[str] = []
    
    def import_grants(self, xml_url: str = None) -> Dict[str, any]:
        """
        Main import method - downloads, parses, and imports grants
        
        Args:
            xml_url: Optional custom URL for the XML extract
            
        Returns:
            Dict with import statistics: {imported, skipped, errors}
        """
        try:
            # Step 1: Download ZIP file
            # Use custom URL if provided, otherwise default
            target_url = xml_url or self.GRANTS_GOV_XML_URL
            print(f"Downloading Grants.gov XML extract from {target_url}...")
            xml_content = self._download_and_extract_xml(target_url)
            
            # Step 2: Parse XML
            print("Parsing XML...")
            grants_data = self._parse_xml(xml_content)
            
            # Step 3: Import to database
            print(f"Importing {len(grants_data)} grants...")
            self._import_to_database(grants_data)
            
            return {
                "imported": self.imported_count,
                "skipped": self.skipped_count,
                "errors": self.errors
            }
            
        except Exception as e:
            error_msg = f"Import failed: {str(e)}"
            self.errors.append(error_msg)
            print(error_msg)
            return {
                "imported": self.imported_count,
                "skipped": self.skipped_count,
                "errors": self.errors
            }
    
    def _download_and_extract_xml(self, url: str) -> str:
        """Download ZIP file and extract XML content"""
        try:
            # Download ZIP file
            response = requests.get(url, timeout=60)
            response.raise_for_status()
            
            # Extract XML from ZIP
            with zipfile.ZipFile(io.BytesIO(response.content)) as zip_file:
                # Get the first XML file in the archive
                xml_files = [f for f in zip_file.namelist() if f.endswith('.xml')]
                if not xml_files:
                    raise Exception("No XML file found in ZIP archive")
                
                xml_content = zip_file.read(xml_files[0]).decode('utf-8')
                return xml_content
                
        except requests.RequestException as e:
            raise Exception(f"Failed to download XML: {str(e)}")
        except zipfile.BadZipFile as e:
            raise Exception(f"Invalid ZIP file: {str(e)}")
    
    def _parse_xml(self, xml_content: str) -> List[Dict]:
        """Parse XML and extract grant data"""
        grants_data = []
        
        try:
            root = ET.fromstring(xml_content)
            
            # Find all opportunity elements (adjust tag names based on actual XML structure)
            # Common tags: OpportunityForecastDetail, OpportunitySynopsisDetail_1_0
            opportunities = root.findall('.//OpportunityForecastDetail') or \
                          root.findall('.//OpportunitySynopsisDetail_1_0') or \
                          root.findall('.//Opportunity')
            
            print(f"DEBUG: Found {len(opportunities)} opportunities in XML") 
            
            for opp in opportunities:
                try:
                    grant_data = self._extract_grant_data(opp)
                    if grant_data:
                        grants_data.append(grant_data)
                    else:
                        print("DEBUG: _extract_grant_data returned None for an opportunity")
                except Exception as e:
                    error_msg = f"Error parsing opportunity: {str(e)}"
                    print(f"DEBUG: {error_msg}")
                    self.errors.append(error_msg)
                    continue
            
            print(f"DEBUG: Extracted {len(grants_data)} valid grant objects")
            return grants_data
            
        except ET.ParseError as e:
            raise Exception(f"XML parsing error: {str(e)}")
    
    def _extract_grant_data(self, opportunity_element: ET.Element) -> Dict:
        """Extract grant data from XML element"""
        
        def get_text(element, tag_name: str, default: str = "") -> str:
            """Safely get text from XML element"""
            elem = element.find(tag_name)
            return elem.text.strip() if elem is not None and elem.text else default
        
        # Extract opportunity ID (required for deduplication)
        opportunity_id = get_text(opportunity_element, 'OpportunityID')
        if not opportunity_id:
            print("DEBUG: Missing OpportunityID")
            return None  # Skip if no ID
        
        # Extract title (required)
        title = get_text(opportunity_element, 'OpportunityTitle')
        if not title:
            print(f"DEBUG: Missing OpportunityTitle for ID {opportunity_id}")
            return None  # Skip if no title
        
        # Extract agency/organizer (required)
        organizer = get_text(opportunity_element, 'AgencyName') or \
                   get_text(opportunity_element, 'AgencyCode') or \
                   "Unknown Agency"
        
        # Extract description
        description = get_text(opportunity_element, 'Description') or \
                     get_text(opportunity_element, 'OpportunityDescription') or \
                     get_text(opportunity_element, 'AdditionalInformation')
        
        # Extract deadline
        deadline = None
        close_date_str = get_text(opportunity_element, 'CloseDate') or \
                        get_text(opportunity_element, 'ClosingDate')
        if close_date_str:
            deadline = self._parse_date(close_date_str)
        
        # Extract eligibility
        eligibility = get_text(opportunity_element, 'EligibilityCategory') or \
                     get_text(opportunity_element, 'ApplicantEligibility') or \
                     get_text(opportunity_element, 'Eligibility')
        
        # Construct apply URL
        apply_url = f"https://www.grants.gov/search-results-detail/{opportunity_id}"
        
        # Extract optional fields
        amount = get_text(opportunity_element, 'AwardCeiling') or \
                get_text(opportunity_element, 'EstimatedTotalProgramFunding')
        
        return {
            'external_id': opportunity_id,
            'title': title[:500],  # Limit length
            'organizer': organizer[:200],
            'description': description[:2000] if description else None,
            'eligibility': eligibility[:1000] if eligibility else None,
            'deadline': deadline,
            'apply_url': apply_url,
            'amount': amount[:100] if amount else None,
            'source': 'grants.gov',
            'is_verified': False,
            'is_active': True,
            'refugee_country': None
        }
    
    def _parse_date(self, date_str: str) -> datetime:
        """Parse date string to datetime object"""
        # Try common date formats
        formats = [
            '%m/%d/%Y',      # 01/31/2026
            '%Y-%m-%d',      # 2026-01-31
            '%m-%d-%Y',      # 01-31-2026
            '%d/%m/%Y',      # 31/01/2026
            '%Y/%m/%d',      # 2026/01/31
        ]
        
        for fmt in formats:
            try:
                return datetime.strptime(date_str.strip(), fmt)
            except ValueError:
                continue
        
        # If all formats fail, return None
        return None
    
    def _import_to_database(self, grants_data: List[Dict]):
        """Import grants to database with duplicate checking"""
        
        for grant_data in grants_data:
            try:
                # Check if grant already exists by external_id
                existing_grant = self.db.query(models.Grant).filter(
                    models.Grant.external_id == grant_data['external_id']
                ).first()
                
                if existing_grant:
                    # Skip existing grants (don't overwrite admin edits)
                    self.skipped_count += 1
                    continue
                
                # Create new grant
                new_grant = models.Grant(**grant_data)
                self.db.add(new_grant)
                self.imported_count += 1
                
                # Commit in batches of 100 for performance
                if self.imported_count % 100 == 0:
                    self.db.commit()
                    print(f"Imported {self.imported_count} grants...")
                
            except Exception as e:
                error_msg = f"Error importing grant {grant_data.get('external_id', 'unknown')}: {str(e)}"
                self.errors.append(error_msg)
                continue
        
        # Final commit
        try:
            self.db.commit()
            print(f"Import complete: {self.imported_count} imported, {self.skipped_count} skipped")
        except Exception as e:
            self.db.rollback()
            raise Exception(f"Database commit failed: {str(e)}")
