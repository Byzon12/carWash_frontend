// Test file to demonstrate enhanced error handling
// This shows the types of server errors that will now be properly handled

// Example 1: Invalid credentials response from Django REST Framework
{
  "detail": "Invalid credentials"
}
// Will be displayed as: "The username/email or password you entered is incorrect."

// Example 2: Non-field errors
{
  "non_field_errors": ["Unable to log in with provided credentials."]
}
// Will be displayed as: "The username/email or password you entered is incorrect."

// Example 3: Field-specific validation errors
{
  "username": ["This field may not be blank."],
  "password": ["This field is required."]
}
// Will be displayed as: "Username: This field is required.\nPassword: This field is required."

// Example 4: Account status errors
{
  "detail": "User is not active"
}
// Will be displayed as: "Your account has been deactivated. Please contact support."

// Example 5: Rate limiting
{
  "detail": "Rate limit exceeded"
}
// Will be displayed as: "Too many login attempts. Please try again later."

// Example 6: Password reset errors
{
  "detail": "User with this email does not exist"
}
// Will be displayed as: "No account found with this email address."

// Example 7: Email validation errors
{
  "email": ["Enter a valid email address."]
}
// Will be displayed as: "Email: Please enter a valid email address."

/* 
Key Improvements Made:

1. **Comprehensive Error Parsing**: 
   - Handles Django REST Framework standard error formats
   - Parses 'detail', 'error', 'message', 'non_field_errors' fields
   - Handles field-specific validation errors

2. **User-Friendly Messages**:
   - Translates technical server messages to user-friendly text
   - Provides actionable feedback
   - Maintains professional tone

3. **Status Code Handling**:
   - 400: Invalid request/validation errors
   - 401: Invalid credentials
   - 403: Account disabled/forbidden
   - 404: Account not found
   - 429: Rate limiting
   - 500+: Server errors

4. **Password Reset Enhancement**:
   - Specific error messages for email not found
   - Rate limiting feedback
   - Email validation errors

5. **Icon Selection**:
   - Contextual icons based on error type
   - Visual cues for different error categories

6. **Debugging Support**:
   - Enhanced logging in API calls
   - Detailed error information in console
   - Response parsing error handling
*/
