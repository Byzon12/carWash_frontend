# Logout Implementation Guide

## Overview
The logout functionality has been enhanced to properly call the backend logout API before clearing local storage.

## How It Works

### 1. **Enhanced Logout API Method**
Location: `lib/api/api_connect.dart`

**Features:**
- ✅ Calls backend `/user/logout/` endpoint with JWT token
- ✅ Sends proper Authorization header
- ✅ Always clears local storage (even if backend call fails)
- ✅ Returns boolean indicating success
- ✅ Comprehensive error handling and logging

**API Call Details:**
```
POST {baseUrl}user/logout/
Headers:
  Content-Type: application/json
  Authorization: Bearer {jwt_token}
```

### 2. **Enhanced Profile Logout UI**
Location: `lib/profile.dart`

**Features:**
- ✅ Improved confirmation dialog with detailed information
- ✅ Loading indicator during logout process
- ✅ Success/warning messages based on API response
- ✅ Proper navigation to login screen
- ✅ Error handling with retry option

## Backend API Requirements

### Expected Endpoint
```
POST /user/logout/
```

### Expected Headers
```
Content-Type: application/json
Authorization: Bearer <jwt_token>
```

### Expected Responses

**Success:**
- Status: `200 OK` or `204 No Content`
- Body: Can be empty or JSON with success message

**Error:**
- Status: `401 Unauthorized` (invalid/expired token)
- Status: `400 Bad Request` (malformed request)
- Status: `500 Internal Server Error` (server issues)

## How to Use

### From Profile Page
1. User taps the logout button (top-right corner)
2. Confirmation dialog appears with detailed information
3. User confirms logout
4. Loading indicator shows "Logging out..."
5. Backend API is called to invalidate the session
6. Local storage is cleared
7. Success message is shown
8. User is redirected to login screen

### Programmatically
```dart
// Simple logout (returns boolean)
final success = await ApiConnect.logout();

// Test the logout API directly
await ApiConnect.testLogoutAPI();
```

## Debug and Testing

### Console Messages to Watch For
- `[DEBUG] ApiConnect: Starting logout process...`
- `[DEBUG] ApiConnect: Calling backend logout API...`
- `[SUCCESS] ApiConnect: Backend logout successful`
- `[SUCCESS] ApiConnect: Local storage cleared successfully`

### Test the Logout API
```dart
await ApiConnect.testLogoutAPI();
```

### Profile Page Debug Messages
- `[DEBUG] ProfilePage: Starting logout process`
- `[DEBUG] ProfilePage: Logout confirmed by user`
- `[DEBUG] ProfilePage: Performing logout operation`
- `[DEBUG] ProfilePage: Navigation to login completed`

## Error Handling

### Backend API Fails
- ✅ Local storage still gets cleared
- ✅ User sees warning message but still gets logged out
- ✅ Navigation to login screen happens
- ✅ Debug logs show the backend error

### Network Issues
- ✅ Local storage gets cleared after timeout
- ✅ User sees error message with retry option
- ✅ Detailed error logging for debugging

### Local Storage Issues
- ✅ Returns `false` but attempts navigation anyway
- ✅ Error message shown to user
- ✅ Retry option available

## Security Benefits

### Server-Side Session Invalidation
- ✅ JWT token is invalidated on the server
- ✅ Prevents token reuse if device is compromised
- ✅ Proper session management

### Local Data Cleanup
- ✅ All stored tokens are removed
- ✅ User profile data is cleared
- ✅ No sensitive data remains on device

## Troubleshooting

### Backend Not Responding
1. Check backend server is running
2. Verify the logout endpoint exists
3. Check network connectivity
4. Review backend logs for errors

### Local Storage Issues
1. Check device storage permissions
2. Verify flutter_secure_storage is working
3. Review app permissions

### Navigation Issues
1. Verify routes are properly configured in `main.dart`
2. Check if splash screen is working
3. Ensure login screen is accessible

## Files Modified
- `lib/api/api_connect.dart`: Enhanced logout method + test method
- `lib/profile.dart`: Improved logout UI and handling

## Next Steps
1. Test the logout flow in your app
2. Verify the backend logout endpoint is working
3. Check console logs for any issues
4. Test network error scenarios
