# RideWeather - Developer Guide

## Overview

This guide describes the technical implementation and architecture of the RideWeather iOS app. The app is built with SwiftUI, Core Data, and integrates with external APIs for route planning and weather data.

## Architecture

### App Structure
```
RideWeather/
├── Views/                 # SwiftUI Views
├── Models/               # Data Models
├── Services/             # Business Logic
├── Core Data/            # Persistence Layer
├── Utilities/            # Helper Classes
└── Resources/            # Assets & Configuration
```

### Design Patterns
- **MVVM**: Model-View-ViewModel architecture
- **Repository Pattern**: For data access
- **Observer Pattern**: For state management
- **Factory Pattern**: For object creation

## Core Components

### 1. Route Planning System

#### MapKitRouteService
```swift
class MapKitRouteService: ObservableObject {
    // Route planning functionality
    func planRoute(_ request: RouteRequest) async throws -> PlannedRoute
    
    // Location services
    func getCurrentLocation() async throws -> CLLocationCoordinate2D
    
    // GPX conversion
    func convertRouteToGPXWaypoints(_ route: MKRoute, maxPoints: Int) -> [GPXWaypoint]
}
```

**Key functions:**
- **Route planning** with MapKit
- **Location retrieval** with Core Location
- **Route optimization** for motorcyclists
- **GPX conversion** with route points configuration

#### RouteRequest Model
```swift
struct RouteRequest {
    let startLocation: RouteLocation
    let destination: RouteLocation
    let waypoints: [RouteLocation]
    let routeType: RouteType
    let avoidHighways: Bool
    let avoidTolls: Bool
    let maxRoutePoints: Int  // NEW: Maximum number of route points
}
```

### 2. Weather Integration System

#### WeatherService
```swift
class WeatherService: ObservableObject {
    // Fetch weather data
    func fetchWeatherData(for coordinates: [CLLocationCoordinate2D]) async throws -> [WeatherSnapshot]
    
    // Cache management
    func getCachedWeather(for coordinate: CLLocationCoordinate2D) -> WeatherSnapshot?
    
    // Error handling
    func handleWeatherError(_ error: WeatherError) -> String
}
```

**Features:**
- **OpenWeatherMap API** integration
- **Intelligent caching** for offline use
- **Batch processing** of multiple coordinates
- **Error handling** with retry mechanisms

### 3. Core Data Integration

#### CoreDataManager
```swift
class CoreDataManager: ObservableObject {
    // Singleton instance
    static let shared = CoreDataManager()
    
    // Context management
    var managedObjectContext: NSManagedObjectContext
    
    // App settings
    func getAppSettings() -> AppSettingsEntity
    func updateAppSettings(...) -> Bool
    
    // NEW FUNCTIONS
    func resetAppSettingsToDefaults()
    func checkAndUpdateSettingsIfNeeded()
}
```

#### Data Models
```swift
// Trip Entity
class Trip: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var name: String
    @NSManaged var date: Date
    @NSManaged var routePoints: Set<RoutePoint>
    @NSManaged var rainFocusEnabled: Bool  // NEW: Rain focus toggle
}

// RoutePoint Entity
class RoutePoint: NSManagedObject {
    @NSManaged var coordinate: CLLocationCoordinate2D
    @NSManaged var estimatedPassTime: Date
    @NSManaged var weather: WeatherSnapshot?
    @NSManaged var distance: Double
}

// WeatherSnapshot Entity
class WeatherSnapshot: NSManagedObject {
    @NSManaged var temperature: Double
    @NSManaged var chanceOfRain: Double
    @NSManaged var rainAmount: Double
    @NSManaged var weatherCondition: String
}
```

### 4. Rain Focus System

#### Implementation Details
```swift
// RoutePointRow.swift
private var isRainy: Bool {
    guard let weather = weather else { return false }
    
    let settings = coreDataStore.getAppSettings()
    let rainRuleType = settings.rainRuleType
    let chanceThreshold = settings.rainChanceThreshold / 100.0
    let amountThreshold = settings.rainAmountThreshold
    
    switch rainRuleType {
    case "CHANCE_ONLY":
        return weather.chanceOfRain >= chanceThreshold
    case "AMOUNT_ONLY":
        return weather.rainAmount >= amountThreshold
    case "BOTH":
        return weather.chanceOfRain >= chanceThreshold && 
               weather.rainAmount >= amountThreshold
    default:
        return false
    }
}
```

**Rule Types:**
- **CHANCE_ONLY**: Rain chance percentage only
- **AMOUNT_ONLY**: Rain amount only
- **BOTH**: Both criteria must be met

## New Features (Version 1.0)

### 1. Route Points Configuration

#### RoutePlannerView
```swift
@State private var maxRoutePoints: Int = 10

private var routePointsSection: some View {
    Section("ROUTE POINTS FOR WEATHER DATA") {
        VStack(alignment: .leading, spacing: 8) {
            Text("Number of route points")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                Text("\(maxRoutePoints)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(spacing: 8) {
                    Slider(
                        value: Binding(
                            get: { Double(maxRoutePoints) },
                            set: { maxRoutePoints = Int($0) }
                        ),
                        in: 2...20,
                        step: 1
                    )
                    .frame(width: 120)
                    
                    HStack {
                        Text("2")
                        Spacer()
                        Text("20")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
        }
    }
}
```

#### MapKitRouteService Integration
```swift
private func convertRouteToGPXWaypoints(_ route: MKRoute, maxPoints: Int = 50) async throws -> [GPXWaypoint] {
    let coordinates = route.polyline.coordinates
    var waypoints: [GPXWaypoint] = []
    
    // Calculate step size for proportional distribution
    let totalCoordinates = coordinates.count
    let step = max(1, totalCoordinates / maxPoints)
    
    // Always add start point
    waypoints.append(GPXWaypoint(
        coordinate: coordinates.first!,
        name: "Start",
        type: .start
    ))
    
    // Add route points proportionally
    for i in stride(from: step, to: totalCoordinates - step, by: step) {
        waypoints.append(GPXWaypoint(
            coordinate: coordinates[i],
            name: "Route Point \(waypoints.count)",
            type: .waypoint
        ))
    }
    
    // Always add end point
    waypoints.append(GPXWaypoint(
        coordinate: coordinates.last!,
        name: "End",
        type: .destination
    ))
    
    return waypoints
}
```

### 2. Improved Location Service

#### CurrentLocationDelegate
```swift
class CurrentLocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onSuccess: (CLLocationCoordinate2D) -> Void
    var onLocationError: ((Error) -> Void)?
    var hasResponded = false
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !hasResponded, let location = locations.first else { return }
        
        hasResponded = true
        onSuccess(location.coordinate)
    }
    
    nonisolated func timeout() {
        guard !hasResponded else { return }
        hasResponded = true
        onLocationError?(RoutePlanningError.locationPermissionDenied)
    }
}
```

#### Location Retrieval
```swift
func getCurrentLocation() async throws -> CLLocationCoordinate2D {
    let manager = CLLocationManager()
    
    // Check permissions
    let status = manager.authorizationStatus
    guard status == .authorizedWhenInUse || status == .authorizedAlways else {
        if status == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        throw RoutePlanningError.locationPermissionDenied
    }
    
    return try await withCheckedThrowingContinuation { continuation in
        let delegate = CurrentLocationDelegate { coordinate in
            continuation.resume(returning: coordinate)
        }
        
        delegate.onLocationError = { error in
            continuation.resume(throwing: error)
        }
        
        manager.delegate = delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestLocation()
        
        // Timeout after 10 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
            if !delegate.hasResponded {
                delegate.timeout()
            }
        }
    }
}
```

### 3. Route Preview Improvements

#### RoutePreviewMapView
```swift
struct RoutePreviewMapView: UIViewRepresentable {
    let plannedRoute: PlannedRoute
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Add route polyline
        mapView.addOverlay(plannedRoute.polyline)
        
        // Add annotations
        mapView.addAnnotation(plannedRoute.startAnnotation)
        mapView.addAnnotation(plannedRoute.destinationAnnotation)
        
        // Set region
        mapView.setRegion(plannedRoute.region, animated: true)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        let parent: RoutePreviewMapView
        
        init(_ parent: RoutePreviewMapView) {
            self.parent = parent
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = .blue
                renderer.lineWidth = 4
                return renderer
            }
            return MKOverlayRenderer()
        }
    }
}
```

## Data Flow

### Route Planning Flow
```
User Input → RouteRequest → MapKitRouteService → MKRoute → GPX Conversion → Trip Creation
     ↓
Route Preview → User Confirmation → Core Data Storage → Trip List Update
```

### Weather Data Flow
```
Route Points → WeatherService → OpenWeatherMap API → WeatherSnapshot → Core Data
     ↓
Trip Detail View → RoutePointRow → Rain Focus Logic → Visual Highlighting
```

### Rain Focus Flow
```
App Settings → RoutePointRow → isRainy() → Visual Styling → User Feedback
     ↓
Real-time Updates → Highlighting Changes → Trip State Synchronization
```

## Performance Optimizations

### 1. Route Points Optimization
- **Proportional distribution** over route length
- **Configuration of 2-20 points** for balance between detail and performance
- **Efficient polyline rendering** with MapKit

### 2. Weather Data Caching
- **Intelligent cache TTL** settings
- **Batch processing** of multiple coordinates
- **Offline functionality** for cached data

### 3. Core Data Performance
- **Efficient queries** with fetch limits
- **Batch updates** for large datasets
- **Memory management** with proper cleanup

## Error Handling

### Weather Service Errors
```swift
enum WeatherError: Error, LocalizedError {
    case invalidResponse
    case apiError(Int, String?)
    case noData
    case networkError(NetworkError)
    case invalidURL
    case decodingError(Error)
    case timeout
    case rateLimitExceeded
    case invalidAPIKey
    case locationServiceError(Error)
}
```

### Route Planning Errors
```swift
enum RoutePlanningError: Error, LocalizedError {
    case invalidLocation
    case routeNotFound
    case locationPermissionDenied
    case networkError
    case timeout
}
```

### Core Data Errors
```swift
enum CoreDataError: Error, LocalizedError {
    case contextError(Error)
    case saveFailed(Error)
    case fetchFailed(Error)
    case invalidData
}
```

## Testing

### Unit Tests
- **Service layer testing** with mocks
- **Model validation** tests
- **Error handling** scenarios

### Integration Tests
- **Core Data operations** testing
- **API integration** testing
- **Route planning** end-to-end tests

### UI Tests
- **User flow** testing
- **Accessibility** testing
- **Performance** testing

## Deployment

### Build Configuration
- **Debug**: Extensive logging and error reporting
- **Release**: Optimized performance and minimal logging

### App Store Submission
- **Privacy declarations** in PrivacyInfo.xcprivacy
- **App metadata** in Info.plist
- **Screenshots** for different device sizes

## Future Improvements

### Planned Features

- **Offline maps** support
- **Route sharing** functionality
- **Weather history** analysis
- **Motorcycle-specific** route optimization

### Technical Improvements
- **Background refresh** for weather data
- **Advanced caching** strategies
- **Machine learning** for weather predictions
- **Accessibility** improvements

## Conclusion

The RideWeather app implements a robust architecture for route planning with weather integration, specifically optimized for motorcyclists. The new features for route points configuration and improved location services make the app more user-friendly and efficient.

The app follows iOS best practices and uses modern SwiftUI patterns for a consistent and maintainable codebase.

---

**For developers**: This guide is updated with each new version. Check regularly for updates and new features.
