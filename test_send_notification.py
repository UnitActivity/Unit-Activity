"""
Test script untuk mengirim push notification ke FCM
Digunakan untuk testing notification system

Requirements:
    pip install requests python-dotenv

Usage:
    python test_send_notification.py --token YOUR_FCM_TOKEN --title "Test" --message "Hello"
"""

import requests
import json
import argparse
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

def send_notification(
    fcm_token: str,
    title: str,
    message: str,
    notification_type: str = "info",
    data: dict = None,
    server_key: str = None
):
    """
    Send push notification via FCM HTTP API
    
    Args:
        fcm_token: FCM registration token
        title: Notification title
        message: Notification body
        notification_type: Type of notification (info, warning, success, event)
        data: Additional data payload
        server_key: Firebase Cloud Messaging server key
    
    Returns:
        Response from FCM API
    """
    
    # Get server key from env or parameter
    if server_key is None:
        server_key = os.getenv('FCM_SERVER_KEY')
    
    if not server_key:
        raise ValueError(
            "FCM_SERVER_KEY not found. "
            "Set it in .env file or pass as parameter"
        )
    
    url = "https://fcm.googleapis.com/fcm/send"
    
    headers = {
        "Authorization": f"key={server_key}",
        "Content-Type": "application/json"
    }
    
    # Build payload
    payload = {
        "to": fcm_token,
        "notification": {
            "title": title,
            "body": message,
            "sound": "default",
            "badge": "1"
        },
        "data": {
            "type": notification_type,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            **(data or {})
        },
        "priority": "high",
        # Important for background delivery
        "content_available": True
    }
    
    print("=" * 60)
    print("Sending notification to FCM...")
    print("-" * 60)
    print(f"Token: {fcm_token[:20]}...{fcm_token[-20:]}")
    print(f"Title: {title}")
    print(f"Message: {message}")
    print(f"Type: {notification_type}")
    print(f"Extra Data: {data}")
    print("=" * 60)
    
    try:
        response = requests.post(
            url,
            headers=headers,
            data=json.dumps(payload),
            timeout=10
        )
        
        response.raise_for_status()
        result = response.json()
        
        print("\n✅ SUCCESS!")
        print("-" * 60)
        print(f"Status Code: {response.status_code}")
        print(f"Message ID: {result.get('message_id', 'N/A')}")
        print(f"Success Count: {result.get('success', 0)}")
        print(f"Failure Count: {result.get('failure', 0)}")
        
        if result.get('results'):
            for idx, res in enumerate(result['results']):
                print(f"\nResult {idx + 1}:")
                print(f"  Message ID: {res.get('message_id', 'N/A')}")
                if 'error' in res:
                    print(f"  Error: {res['error']}")
        
        print("=" * 60)
        
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"\n❌ ERROR: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        raise


def send_to_topic(
    topic: str,
    title: str,
    message: str,
    notification_type: str = "info",
    data: dict = None,
    server_key: str = None
):
    """
    Send notification to a topic (broadcast)
    
    Args:
        topic: FCM topic name (e.g., 'all_users', 'ukm_UUID')
        title: Notification title
        message: Notification body
        notification_type: Type of notification
        data: Additional data payload
        server_key: Firebase server key
    """
    
    if server_key is None:
        server_key = os.getenv('FCM_SERVER_KEY')
    
    if not server_key:
        raise ValueError("FCM_SERVER_KEY not found")
    
    url = "https://fcm.googleapis.com/fcm/send"
    
    headers = {
        "Authorization": f"key={server_key}",
        "Content-Type": "application/json"
    }
    
    payload = {
        "to": f"/topics/{topic}",
        "notification": {
            "title": title,
            "body": message,
            "sound": "default",
            "badge": "1"
        },
        "data": {
            "type": notification_type,
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            **(data or {})
        },
        "priority": "high",
        "content_available": True
    }
    
    print("=" * 60)
    print(f"Sending notification to topic: {topic}")
    print("-" * 60)
    print(f"Title: {title}")
    print(f"Message: {message}")
    print("=" * 60)
    
    try:
        response = requests.post(
            url,
            headers=headers,
            data=json.dumps(payload),
            timeout=10
        )
        
        response.raise_for_status()
        result = response.json()
        
        print("\n✅ SUCCESS!")
        print(f"Message ID: {result.get('message_id', 'N/A')}")
        print("=" * 60)
        
        return result
        
    except requests.exceptions.RequestException as e:
        print(f"\n❌ ERROR: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        raise


def main():
    parser = argparse.ArgumentParser(
        description='Send test push notification via FCM'
    )
    
    # Required arguments
    parser.add_argument(
        '--token',
        type=str,
        help='FCM device token (optional if using --topic)'
    )
    
    parser.add_argument(
        '--topic',
        type=str,
        help='FCM topic name (e.g., all_users, ukm_UUID)'
    )
    
    parser.add_argument(
        '--title',
        type=str,
        required=True,
        help='Notification title'
    )
    
    parser.add_argument(
        '--message',
        type=str,
        required=True,
        help='Notification message/body'
    )
    
    # Optional arguments
    parser.add_argument(
        '--type',
        type=str,
        default='info',
        choices=['info', 'warning', 'success', 'event', 'announcement'],
        help='Notification type (default: info)'
    )
    
    parser.add_argument(
        '--data',
        type=str,
        help='Additional data as JSON string (e.g., \'{"page": "home"}\')'
    )
    
    parser.add_argument(
        '--server-key',
        type=str,
        help='Firebase server key (or set FCM_SERVER_KEY in .env)'
    )
    
    args = parser.parse_args()
    
    # Parse additional data
    extra_data = None
    if args.data:
        try:
            extra_data = json.loads(args.data)
        except json.JSONDecodeError:
            print(f"❌ Invalid JSON in --data: {args.data}")
            return
    
    # Send to topic or token
    if args.topic:
        send_to_topic(
            topic=args.topic,
            title=args.title,
            message=args.message,
            notification_type=args.type,
            data=extra_data,
            server_key=args.server_key
        )
    elif args.token:
        send_notification(
            fcm_token=args.token,
            title=args.title,
            message=args.message,
            notification_type=args.type,
            data=extra_data,
            server_key=args.server_key
        )
    else:
        print("❌ ERROR: Either --token or --topic must be provided")
        parser.print_help()


if __name__ == '__main__':
    main()
