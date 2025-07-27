# Google Maps Configuration

## API Key Setup Required

To enable Google Maps functionality, you need to:

### 1. Get Google Maps API Key
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing one
3. Enable the following APIs:
   - Maps SDK for Android
   - Maps SDK for iOS (if you plan to support iOS)
   - Places API (optional, for place search)
4. Create credentials (API Key)
5. Restrict the API key to your app's package name for security

### 2. Configure Android
Replace `YOUR_GOOGLE_MAPS_API_KEY` in `android/app/src/main/AndroidManifest.xml` with your actual API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ACTUAL_API_KEY_HERE" />
```

### 3. Configure iOS (if needed)
Add your API key to `ios/Runner/AppDelegate.swift`:

```swift
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("YOUR_ACTUAL_API_KEY_HERE")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

## Features Implemented

✅ **Interactive Google Maps** showing Kenya with car wash locations
✅ **Location Markers** for each car wash with info windows
✅ **User Location** tracking and display (with permissions)
✅ **Map Controls** - zoom, pan, my location button
✅ **Floating Action Button** to center map on user location
✅ **Distance Calculation** showing distance from user to car washes
✅ **Marker Tap Navigation** to car wash details screen

## Current Map Configuration

- **Center**: Kenya coordinates (-0.0236, 37.9062)
- **Initial Zoom**: 6.0 (shows most of Kenya)
- **User Location Zoom**: 12.0 (detailed area view)
- **Marker Color**: Blue for car wash locations
- **Permissions**: Location access (FINE and COARSE) already configured

## Testing

1. Add your API key to AndroidManifest.xml
2. Run the app: `flutter run`
3. Navigate to Dashboard (home screen)
4. You should see an interactive map with car wash markers
5. Tap markers to view car wash details
6. Use the floating action button to center on your location

## Troubleshooting

- **Blank map**: Check API key configuration
- **No markers**: Verify car wash API is returning data
- **Location not working**: Check GPS/location permissions
- **App crashes**: Check API key is valid and has proper restrictions
