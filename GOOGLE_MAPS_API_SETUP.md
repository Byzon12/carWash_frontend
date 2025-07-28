# Google Maps API Setup Instructions

## Why the Map Isn't Showing
The map is not displaying because the Google Maps API key is currently set to a placeholder value `YOUR_GOOGLE_MAPS_API_KEY` in the Android configuration.

## How to Fix It

### Step 1: Get a Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the "Maps SDK for Android" API
4. Go to "Credentials" and create an API key
5. Restrict the API key to your app's package name for security

### Step 2: Add the API Key to Your App
1. Open `android/app/src/main/AndroidManifest.xml`
2. Find this line (around line 52):
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="YOUR_GOOGLE_MAPS_API_KEY"/>
   ```
3. Replace `YOUR_GOOGLE_MAPS_API_KEY` with your actual API key:
   ```xml
   <meta-data android:name="com.google.android.geo.API_KEY"
              android:value="AIzaSyBVVt6...YOUR_ACTUAL_KEY_HERE"/>
   ```

### Step 3: Test the Map
1. Save the file
2. Run `flutter clean`
3. Run `flutter pub get`
4. Build and run the app: `flutter run`

## Current App Features (Ready When API Key is Added)
✅ Location permission request after login  
✅ Interactive Google Maps with Kenya view  
✅ User location marker (red marker)  
✅ Car wash location markers (blue markers)  
✅ Smart floating action buttons  
✅ Location status indicators  
✅ Smooth map animations  

## Security Note
- Never commit your actual API key to public repositories
- Use environment variables or secure storage in production
- Restrict your API key to specific Android apps and IP addresses

## Troubleshooting
If the map still doesn't show after adding the API key:
1. Check if the API key is valid
2. Ensure "Maps SDK for Android" is enabled in Google Cloud Console
3. Check the app's package name matches the API key restrictions
4. Look for error messages in the debug console
