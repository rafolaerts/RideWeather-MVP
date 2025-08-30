# RideWeather 🚴‍♂️🌤️

**Smart route planning with weather integration for motorcyclists**

RideWeather is an iOS app that helps you plan motorcycle routes with detailed weather information. The app combines route planning, weather data, and smart warnings to help you choose the best time for your motorcycle ride.

## ✨ Main Features

- 🗺️ **Route Planning**: Manual route planning and GPX import (optimized for motorcyclists)
- 🌤️ **Weather Integration**: Real-time weather data from OpenWeatherMap
- 🚨 **Rain Focus**: Smart warnings for bad weather
- 📱 **iOS Native**: Built with SwiftUI and Core Data
- 🔧 **Configuration**: Customizable route points (2-20) and weather thresholds

## 🚀 New Features (Version 1.0)

### Route Points Configuration
- **Slider interface** for 2-20 route points
- **Proportional distribution** over route length
- **Default 10 points** for optimal balance during motorcycle rides

### Improved Location Service
- **Real GPS location** instead of simulator defaults
- **Timeout handling** for reliable location retrieval
- **Permission management** with clear feedback

### Rain Focus System
- **Flexible rule types**: rain chance only, amount only, or both
- **Customizable thresholds**: 30% rain chance, 0.3 mm rain amount
- **Visual highlighting** of problematic route points

## 📱 Screenshots

*Screenshots will be added in the next update*

## 🛠️ Technical Details

- **Platform**: iOS 18.5+
- **Framework**: SwiftUI + Core Data
- **APIs**: OpenWeatherMap, MapKit, Core Location
- **Architecture**: MVVM with Repository Pattern
- **Data Storage**: SQLite via Core Data

## 📚 Documentation

- **[User Guide](RideWeather/USER_GUIDE.md)** - Comprehensive user instructions
- **[Developer Guide](RideWeather/DEVELOPER_GUIDE.md)** - Technical implementation details
- **[API Configuration](RideWeather/API_CONFIGURATION_README.md)** - OpenWeatherMap setup
- **[Error Handling](RideWeather/ERROR_HANDLING_README.md)** - Error handling and debugging

## 🚀 Installation

### Requirements
- Xcode 16.0+
- iOS 18.5+ deployment target
- OpenWeatherMap API key

### Steps
1. Clone the repository
2. Open `RideWeather.xcodeproj` in Xcode
3. Add your OpenWeatherMap API key to the build settings
4. Build and run on your device or simulator

### Setting up API Key
1. Create an account on [OpenWeatherMap](https://openweathermap.org/)
2. Copy your API key
3. Add `OPENWEATHER_API_KEY` to the build settings
4. See [API Configuration](RideWeather/API_CONFIGURATION_README.md) for details

## 🧪 Testing

The app is optimized for testing on the iPhone 16 Pro Max simulator:

```bash
# Build the app
xcodebuild -project RideWeather.xcodeproj -scheme RideWeather -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' build

# Run tests (if implemented)
xcodebuild -project RideWeather.xcodeproj -scheme RideWeather -destination 'platform=iOS Simulator,name=iPhone 16 Pro Max' test
```

## 🔧 Configuration

### Route Points
- **Minimum**: 2 points
- **Maximum**: 20 points
- **Default**: 10 points
- **Step size**: 1 point

### Weather Thresholds
- **Rain chance**: 30% (default)
- **Rain amount**: 0.3 mm (default)
- **Rule type**: "BOTH" (both criteria)

## 📊 Project Structure

```
RideWeather/
├── Views/                 # SwiftUI Views
│   ├── RoutePlannerView.swift
│   ├── TripDetailView.swift
│   ├── RoutePreviewView.swift
│   └── ...
├── Models/               # Data Models
│   ├── Trip.swift
│   ├── RouteModels.swift
│   └── WeatherModels.swift
├── Services/             # Business Logic
│   ├── MapKitRouteService.swift
│   ├── WeatherService.swift
│   └── LocationService.swift
├── Core Data/            # Persistence Layer
│   ├── CoreDataManager.swift
│   ├── CoreDataTripStore.swift
│   └── RideWeather.xcdatamodeld/
└── Documentation/        # README files
    ├── USER_GUIDE.md
    ├── DEVELOPER_GUIDE.md
    └── ...
```

## 🐛 Known Issues

### Resolved ✅
- Route lines not visible in preview
- Wrong simulator location (San Francisco)
- Too many route points generated (1000+)
- Rain focus highlighting not working

### In Progress 🔄
- Performance optimizations for large routes
- Offline maps support


## 🤝 Contributing

Contributions are welcome! Here are some ways to help:

1. **Bug Reports**: Open an issue for problems
2. **Feature Requests**: Suggest new functionality
3. **Code Reviews**: Review pull requests
4. **Documentation**: Help improve the documentation

## 📄 License

This project is developed for educational and personal purposes.

## 🙏 Acknowledgments

- **OpenWeatherMap** for weather data API
- **Apple** for iOS frameworks and tools
- **SwiftUI community** for best practices and examples

## 📞 Contact

For questions or support:
- **Issues**: Use GitHub Issues
- **Documentation**: Consult the guides in the `RideWeather/` folder
- **Console Output**: Check debug logs for technical details

---

**RideWeather** - Make your motorcycle rides weather-proof! 🏍️🌤️

*Last updated: August 2025*
