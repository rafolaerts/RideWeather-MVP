# API Configuration for RideWeather

## Overview

This app uses the OpenWeatherMap API for weather data. The API key is now safely configured via project settings instead of being hardcoded in the source code.

## Current Configuration

- **API Key**: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` (default value)
- **API Endpoint**: `https://api.openweathermap.org/data/3.0`
- **Configuration File**: `Configuration.swift`

## Setting Up Your Own API Key

### Step 1: OpenWeatherMap Account
1. Go to [OpenWeatherMap](https://openweathermap.org/)
2. Create a free account
3. Go to "My API Keys" in your dashboard
4. Copy your API key

### Step 2: Update Project Configuration
1. Open `RideWeather.xcodeproj` in Xcode
2. Select the RideWeather project in the navigator
3. Select the RideWeather target
4. Go to "Build Settings"
5. Search for "Info.plist Values"
6. Add: `OPENWEATHER_API_KEY` = `YOUR_API_KEY_HERE`

### Step 3: Different Keys for Debug/Release (Optional)
For production use, you can set different API keys:

**Debug Configuration:**
- `OPENWEATHER_API_KEY` = `YOUR_DEBUG_API_KEY`

**Release Configuration:**
- `OPENWEATHER_API_KEY` = `YOUR_PRODUCTION_API_KEY`

## Configuration Validation

The app automatically validates the configuration at startup:
- Checks if the API key is not the default value
- Validates the format of the API key
- Shows warnings in the console if there are problems

## Security

✅ **API key is not in the source code**
✅ **Different keys for debug/release possible**
✅ **Easy to update without code changes**
✅ **Safe enough for MVP and beta testing**

## Troubleshooting

### "API key is still set to default value"
- Check if you've added `INFOPLIST_KEY_OPENWEATHER_API_KEY` to the build settings
- Make sure the value is not empty

### "API key has unexpected format"
- OpenWeatherMap API keys are usually 32 characters long
- Check if you've copied the complete key

### Build Errors
- Clean build folder (Cmd+Shift+K)
- Rebuild project (Cmd+B)

## Next Steps

1. **Replace the default API key** with your own key
2. **Test the app** to ensure weather data is retrieved correctly
3. **Consider rate limiting** for production use
4. **Monitor API usage** in your OpenWeatherMap dashboard
