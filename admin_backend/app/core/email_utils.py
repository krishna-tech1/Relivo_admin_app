import requests
import json
from app.core.config import settings

def send_verification_email(email_to: str, code: str, subject: str = "Your Verification Code - Relivo", heading: str = "Verification Code"):
    print(f"DEBUG: Attempting to send email via Brevo API to {email_to}")
    
    url = "https://api.brevo.com/v3/smtp/email"
    
    # The API Key is stored in MAIL_PASSWORD env var based on USER configuration
    # Assuming 'xkeysib-...' is the API key.
    api_key = settings.MAIL_PASSWORD
    
    if not api_key:
        print("[ERROR] No API Key (MAIL_PASSWORD) found.")
        return False
        
    sender_email = settings.MAIL_FROM or "no-reply@relivo.app"
    sender_name = "Relivo App"
    
    # Construct Payload
    payload = {
        "sender": {
            "name": sender_name,
            "email": sender_email
        },
        "to": [
            {
                "email": email_to
            }
        ],
        "subject": subject,
        "htmlContent": f"""
        <html>
            <body style="font-family: Arial, sans-serif;">
                <div style="padding: 20px; background-color: #f4f4f4; border-radius: 10px;">
                    <h2 style="color: #333;">{heading}</h2>
                    <p style="font-size: 16px;">Your code is:</p>
                    <h1 style="color: #4CAF50; letter-spacing: 5px;">{code}</h1>
                    <p style="font-size: 14px; color: #666;">Please do not share this code with anyone.</p>
                </div>
            </body>
        </html>
        """
    }
    
    headers = {
        'accept': 'application/json',
        'api-key': api_key,
        'content-type': 'application/json'
    }
    
    try:
        response = requests.post(url, headers=headers, json=payload, timeout=10)
        
        if response.status_code == 201 or response.status_code == 200:
            print(f"[SUCCESS] Email sent successfully via Brevo API. Response: {response.text}")
            return True
        else:
            print(f"[ERROR] Failed to send email via Brevo API. Status: {response.status_code}")
            print(f"[ERROR] Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"[ERROR] Exception sending email via API: {str(e)}")
        return False
