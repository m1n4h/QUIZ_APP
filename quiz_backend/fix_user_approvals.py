#!/usr/bin/env python
import os
import django

# Setup Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'quiz_backend.settings')
django.setup()

from quiz_api.models import User

def fix_user_approvals():
    """Fix user approvals - auto-approve students and admins"""
    print("=== FIXING USER APPROVALS ===")
    
    # Get all users who should be auto-approved but aren't
    users_to_fix = User.objects.filter(
        role__in=['student', 'admin'],
        is_approved=False
    )
    
    print(f"Found {users_to_fix.count()} users to fix:")
    
    for user in users_to_fix:
        print(f"  - {user.email} | Role: {user.role} | Currently Approved: {user.is_approved}")
        user.is_approved = True
        user.save()
        print(f"    ✅ Fixed: {user.email} is now approved")
    
    print("\n=== VERIFICATION ===")
    all_users = User.objects.all()
    for user in all_users:
        status = "✅ Approved" if user.is_approved else "❌ Pending"
        print(f"  - {user.email} | Role: {user.role} | {status}")

if __name__ == '__main__':
    fix_user_approvals()