# RideWeather - User Guide

## Overview

RideWeather is an iOS app that helps you plan motorcycle routes with detailed weather information. The app combines route planning, weather data, and smart warnings to help you choose the best time for your motorcycle ride.

## Main Features

### 🗺️ Route Planning
- **Manual route planning** with start and end location
- **GPX file import** for existing routes
- **Add waypoints** for complex routes
- **Route type selection**: fastest, shortest, or motorcycle-friendly route
- **Avoid options**: highways and toll roads

### 🌤️ Weather Integration
- **Real-time weather data** from OpenWeatherMap API
- **Detailed weather information** for each route point
- **Temperature, rain chance and rain amount** per location
- **Weather cache** for offline use

### 🚨 Smart Warnings
- **Rain Focus system** for weather-dependent planning
- **Customizable thresholds** for rain chance and rain amount
- **Visual highlighting** of problematic route points
- **Flexible rule types**: rain chance only, amount only, or both

## Route Planning

### Manual Route Creation

#### Step 1: Start the Route Planner
1. Open the app
2. Go to the "Trips" tab
3. Tap the "+" button
4. Choose "Plan Route"

#### Step 2: Configure your Route
- **Start location**: Choose between current location or manual address
- **End location**: Enter the destination address
- **Route type**: Select your preference (fastest, shortest, motorcycle-friendly)
- **Avoid options**: Toggle highways and toll roads if desired

#### Step 3: Route Points Configuration
- **Number of route points**: Use the slider to set 2-20 route points
- **Default**: 10 route points (recommended for most motorcycle rides)
- **Points are distributed proportionally** over the route length

#### Step 4: Save Route
1. Tap "Save Route"
2. Review the route preview
3. Confirm route details
4. Give your trip a name and time

### GPX File Import

#### Supported Files
- **GPX 1.1** format
- **Waypoints and tracks** are automatically detected
- **Metadata** is preserved (name, description, etc.)

#### Import Process
1. Tap the "+" button
2. Choose "Import GPX File"
3. Select your GPX file
4. Choose the number of route points for weather data
5. Configure trip details

## Weather Data & Analysis

### Weather Information per Route Point

Each route point shows:
- **Temperature** in Celsius
- **Weather condition** (sunny, cloudy, rain, etc.)
- **Rain chance** as percentage
- **Rain amount** in millimeters
- **Location** with place name and region

### Rain Focus System

#### Configuration
Go to **Settings** to configure rain focus:

- **Rain Focus**: Toggle on/off
- **Rule Type**: 
  - **Rain chance only**: Only percentage counts
  - **Amount only**: Only millimeters count
  - **Rain chance AND amount**: Both criteria must be met
- **Rain chance threshold**: Percentage (default: 30%)
- **Rain amount threshold**: Millimeters (default: 0.3 mm)

#### Visual Feedback
- **Red highlighting**: Route points that meet the criteria
- **Normal display**: Route points that don't meet the criteria
- **Real-time updates**: Highlighting updates when settings change

## Trip Management

### Trip Overview
- **List of all trips** with basic information
- **Sort by date** or name
- **Search functionality** for large trip collections

### Trip Details
- **Detailed route display** on map
- **Weather summary** per route point
- **Rain focus toggle** for quick analysis
- **Edit functionality** for trip adjustments

### Trip Editing
- **Change name and date**
- **Adjust start and end time**
- **Modify route points configuration**
- **Refresh weather data**

## Settings

### General Settings
- **Metric units**: Kilometers and Celsius
- **Weather cache TTL**: How long weather data is kept
- **Point density**: Default number of route points

### Rain Focus Settings
- **Rain rule type**: Flexible criteria configuration
- **Threshold values**: Customizable limits for warnings
- **Notification timing**: How many minutes in advance to warn

### Privacy & Location
- **Location permissions**: Always when in use
- **Data storage**: Local storage in Core Data
- **No external tracking**: All data stays on your device

## Tips & Best Practices

### Route Planning
- **Use 10-15 route points** for most motorcycle rides
- **More points = more detail** but also more weather data calls
- **Plan routes in advance** to analyze weather data

### Weather Analysis
- **Turn on rain focus** for important trips
- **Adjust thresholds** to your comfort level
- **Check multiple time points** for best planning

### Performance
- **Weather data is cached** for offline use
- **Route points are optimized** for efficient processing
- **App uses minimal location data** only when needed

## Troubleshooting

### Route Planning Issues
- **No route visible**: Check if addresses are entered correctly
- **Too many route points**: Use the slider to limit the number
- **Route not saved**: Check if all fields are filled in

### Weather Data Issues
- **No weather data**: Check internet connection
- **Outdated data**: Refresh the trip to get new data
- **Rain focus not working**: Check settings and thresholds

### Location Issues
- **Wrong start location**: Check location permissions
- **Simulator location**: Set location manually for testing

## Technical Details

### Supported iOS Versions
- **iOS 18.5+** (required for latest features)
- **iPhone and iPad** supported
- **Optimized for iPhone 16 Pro Max** and newer models

### Data Storage
- **Core Data** for local storage
- **SQLite database** for efficient data access
- **Automatic backup** via iCloud (if enabled)

### API Integration
- **OpenWeatherMap API** for weather data
- **MapKit** for route planning and maps
- **Core Location** for GPS functionality

## Changelog

### Version 1.0 (Current)
- ✅ Route planning functionality
- ✅ GPX import support
- ✅ Weather integration with OpenWeatherMap
- ✅ Rain focus system
- ✅ Customizable route points (2-20)
- ✅ Smart highlighting of problematic points
- ✅ Core Data integration
- ✅ Offline functionality

### Planned Improvements
- 🔄 Notifications for bad weather
- 🔄 Offline maps support
- 🔄 Route sharing functionality
- 🔄 Weather history analysis
- 🔄 Motorcycle-specific route optimization

## Support

For questions or problems:
1. **Check this guide** for common issues
2. **Check console output** for debug information
3. **Test with different routes** to isolate the problem
4. **Reset app settings** if necessary

---

**RideWeather** - Smart route planning with weather integration for motorcyclists 🏍️🌤️
