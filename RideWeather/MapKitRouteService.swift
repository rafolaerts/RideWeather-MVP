//
//  MapKitRouteService.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import MapKit
import CoreLocation

// MARK: - Route Types

enum RouteType: String, CaseIterable {
    case fastest = "fastest"
    case shortest = "shortest"
    case scenic = "scenic"
    
    var displayName: String {
        switch self {
        case .fastest: return "Snelste route"
        case .shortest: return "Kortste route"
        case .scenic: return "Mooiste route"
        }
    }
    
    var transportType: MKDirectionsTransportType {
        switch self {
        case .fastest, .shortest:
            return .automobile // Motorfiets routes via auto (dichtstbijzijnde)
        case .scenic:
            return .automobile // Voor mooie routes
        }
    }
}

// MARK: - Route Request Models

struct RouteRequest {
    let startLocation: RouteLocation
    let destination: RouteLocation
    let waypoints: [RouteLocation]
    let routeType: RouteType
    let avoidHighways: Bool
    let avoidTolls: Bool
    let maxRoutePoints: Int // Maximum aantal route punten voor weer data
}

struct RouteLocation {
    let coordinate: CLLocationCoordinate2D?
    let address: String?
    let name: String?
    
    var displayName: String {
        if let name = name, !name.isEmpty {
            return name
        } else if let address = address, !address.isEmpty {
            return address
        } else if let coordinate = coordinate {
            return String(format: "%.4f°, %.4f°", coordinate.latitude, coordinate.longitude)
        } else {
            return "Onbekende locatie"
        }
    }
}

// MARK: - Route Result Models

struct PlannedRoute {
    let startLocation: RouteLocation
    let destination: RouteLocation
    let waypoints: [RouteLocation]
    let routeType: RouteType
    let distance: Double // in kilometers
    let duration: TimeInterval // in seconden
    let routePoints: [GPXWaypoint]
    let polyline: MKPolyline
    let boundingRegion: MKCoordinateRegion
}

// MARK: - MapKit Route Service

class MapKitRouteService: ObservableObject {
    private let geocoder = CLGeocoder()
    
    @Published var isCalculatingRoute = false
    @Published var errorMessage: String?
    
    /// Plan een route van start naar bestemming
    func planRoute(request: RouteRequest) async throws -> PlannedRoute {
        await MainActor.run {
            isCalculatingRoute = true
            errorMessage = nil
        }
        
        defer {
            Task { @MainActor in
                isCalculatingRoute = false
            }
        }
        
        // Geocode start en bestemming als ze adressen zijn
        let startCoordinate = try await geocodeLocation(request.startLocation)
        let destinationCoordinate = try await geocodeLocation(request.destination)
        
        // Geocode waypoints als ze adressen zijn
        var waypointCoordinates: [CLLocationCoordinate2D] = []
        for waypoint in request.waypoints {
            let coordinate = try await geocodeLocation(waypoint)
            waypointCoordinates.append(coordinate)
        }
        
        // Maak route request
        let routeRequest = try await createRouteRequest(
            start: startCoordinate,
            destination: destinationCoordinate,
            waypoints: waypointCoordinates,
            routeType: request.routeType,
            avoidHighways: request.avoidHighways,
            avoidTolls: request.avoidTolls
        )
        
        // Bereken route
        let route = try await calculateRoute(routeRequest)
        
        // Converteer naar PlannedRoute
        return try await convertToPlannedRoute(
            route: route,
            request: request,
            startCoordinate: startCoordinate,
            destinationCoordinate: destinationCoordinate,
            waypointCoordinates: waypointCoordinates
        )
    }
    
    /// Geocode een locatie (adres naar coördinaten)
    private func geocodeLocation(_ location: RouteLocation) async throws -> CLLocationCoordinate2D {
        // Als er al coördinaten zijn, gebruik die
        if let coordinate = location.coordinate {
            return coordinate
        }
        
        // Anders geocode het adres
        guard let address = location.address, !address.isEmpty else {
            throw RoutePlanningError.invalidLocation
        }
        
        do {
            let placemarks = try await geocoder.geocodeAddressString(address)
            guard let placemark = placemarks.first,
                  let coordinate = placemark.location?.coordinate else {
                throw RoutePlanningError.geocodingFailed
            }
            return coordinate
        } catch {
            throw RoutePlanningError.geocodingFailed
        }
    }
    
    /// Maak MKDirections.Request aan
    private func createRouteRequest(
        start: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        waypoints: [CLLocationCoordinate2D],
        routeType: RouteType,
        avoidHighways: Bool,
        avoidTolls: Bool
    ) async throws -> MKDirections.Request {
        let request = MKDirections.Request()
        
        // Start en bestemming
        let startPlacemark = MKPlacemark(coordinate: start)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        request.source = MKMapItem(placemark: startPlacemark)
        request.destination = MKMapItem(placemark: destinationPlacemark)
        
        // Waypoints - MapKit ondersteunt geen waypoints in MKDirections.Request
        // We moeten de route in segmenten berekenen
        if !waypoints.isEmpty {
            // Voor nu slaan we waypoints over - dit zou geïmplementeerd moeten worden
            // door meerdere route requests te maken
            print("⚠️ Waypoints worden momenteel niet ondersteund in deze implementatie")
        }
        
        // Route type en voorkeuren
        request.transportType = routeType.transportType
        
        // Voor motorfiets routes, probeer secundaire wegen te gebruiken
        if routeType == .scenic {
            request.requestsAlternateRoutes = true
        }
        
        // Voorkeuren instellen - MapKit heeft beperkte ondersteuning voor voorkeuren
        // Voor motorfiets routes, probeer secundaire wegen te gebruiken
        if routeType == .scenic {
            // Voor mooie routes, probeer alternatieve routes
            request.requestsAlternateRoutes = true
        }
        
        return request
    }
    
    /// Bereken route met MKDirections
    private func calculateRoute(_ request: MKDirections.Request) async throws -> MKRoute {
        return try await withCheckedThrowingContinuation { continuation in
            let directions = MKDirections(request: request)
            
            directions.calculate { response, error in
                if let error = error {
                    continuation.resume(throwing: RoutePlanningError.routeCalculationFailed(error))
                    return
                }
                
                guard let route = response?.routes.first else {
                    continuation.resume(throwing: RoutePlanningError.noRouteFound)
                    return
                }
                
                continuation.resume(returning: route)
            }
        }
    }
    
    /// Converteer MKRoute naar PlannedRoute
    private func convertToPlannedRoute(
        route: MKRoute,
        request: RouteRequest,
        startCoordinate: CLLocationCoordinate2D,
        destinationCoordinate: CLLocationCoordinate2D,
        waypointCoordinates: [CLLocationCoordinate2D]
    ) async throws -> PlannedRoute {
        // Converteer route naar GPX waypoints
        let routePoints = try await convertRouteToGPXWaypoints(route, maxPoints: request.maxRoutePoints)
        
        // Maak polyline voor kaart weergave
        let polyline = route.polyline
        
        // Bereken bounding region op een veilige manier
        let coordinates = polyline.coordinates
        let region = MKCoordinateRegion(coordinates: coordinates)
        
        return PlannedRoute(
            startLocation: request.startLocation,
            destination: request.destination,
            waypoints: request.waypoints,
            routeType: request.routeType,
            distance: route.distance / 1000.0, // Convert to kilometers
            duration: route.expectedTravelTime,
            routePoints: routePoints,
            polyline: polyline,
            boundingRegion: region
        )
    }
    
    /// Converteer MKRoute naar GPX waypoints
    private func convertRouteToGPXWaypoints(_ route: MKRoute, maxPoints: Int = 50) async throws -> [GPXWaypoint] {
        let coordinates = route.polyline.coordinates
        var waypoints: [GPXWaypoint] = []
        
        // Bereken hoeveel punten we moeten overslaan om tot maxPoints te komen
        let totalCoordinates = coordinates.count
        let step = max(1, totalCoordinates / maxPoints)
        
        print("🔄 convertRouteToGPXWaypoints: Total coordinates: \(totalCoordinates), maxPoints: \(maxPoints), step: \(step)")
        
        // Neem punten met gelijke tussenruimte
        for i in stride(from: 0, to: totalCoordinates, by: step) {
            let coordinate = coordinates[i]
            let waypoint = GPXWaypoint(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                elevation: nil,
                time: nil,
                name: ""
            )
            waypoints.append(waypoint)
            
            // Stop als we het maximum aantal punten hebben bereikt
            if waypoints.count >= maxPoints {
                break
            }
        }
        
        // Zorg ervoor dat we altijd het start- en eindpunt hebben
        if !coordinates.isEmpty && waypoints.count >= 2 {
            let firstCoordinate = coordinates.first!
            let lastCoordinate = coordinates.last!
            
            // Vervang eerste waypoint door startpunt als het anders is
            if waypoints.first?.latitude != firstCoordinate.latitude || waypoints.first?.longitude != firstCoordinate.longitude {
                waypoints[0] = GPXWaypoint(
                    latitude: firstCoordinate.latitude,
                    longitude: firstCoordinate.longitude,
                    elevation: nil,
                    time: nil,
                    name: "Start"
                )
            }
            
            // Vervang laatste waypoint door eindpunt als het anders is
            if waypoints.last?.latitude != lastCoordinate.latitude || waypoints.last?.longitude != lastCoordinate.longitude {
                waypoints[waypoints.count - 1] = GPXWaypoint(
                    latitude: lastCoordinate.latitude,
                    longitude: lastCoordinate.longitude,
                    elevation: nil,
                    time: nil,
                    name: "Bestemming"
                )
            }
        }
        
        print("🔄 convertRouteToGPXWaypoints: Generated \(waypoints.count) waypoints")
        return waypoints
    }
    
    /// Zoek POI's (Points of Interest) voor een query
    func searchPOIs(query: String, region: MKCoordinateRegion? = nil) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let region = region {
            request.region = region
        }
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems
    }
    
    /// Haal huidige locatie op
    func getCurrentLocation() async throws -> CLLocationCoordinate2D {
        print("📍 getCurrentLocation: Start ophalen huidige locatie")
        
        // Controleer locatie permissie
        let locationManager = CLLocationManager()
        let status = locationManager.authorizationStatus
        
        print("📍 getCurrentLocation: Locatie permissie status: \(status.rawValue)")
        
        switch status {
        case .notDetermined:
            print("📍 getCurrentLocation: Permissie nog niet bepaald, vraag aan")
            // Vraag permissie aan
            locationManager.requestWhenInUseAuthorization()
            // Wacht even en probeer opnieuw
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde
            return try await getCurrentLocation()
            
        case .restricted, .denied:
            print("📍 getCurrentLocation: Locatie permissie geweigerd")
            throw RoutePlanningError.locationPermissionDenied
            
        case .authorizedWhenInUse, .authorizedAlways:
            print("📍 getCurrentLocation: Locatie permissie toegestaan, haal locatie op")
            // Haal huidige locatie op
            return try await withCheckedThrowingContinuation { continuation in
                // Zorg ervoor dat dit op de main thread gebeurt
                DispatchQueue.main.async {
                    let tempLocationManager = CLLocationManager()
                    tempLocationManager.desiredAccuracy = kCLLocationAccuracyBest
                    
                    print("📍 getCurrentLocation: Maak CLLocationManager en delegate")
                    
                    let delegate = CurrentLocationDelegate { coordinate in
                        print("📍 getCurrentLocation: Locatie succesvol opgehaald: (\(coordinate.latitude), \(coordinate.longitude))")
                        DispatchQueue.main.async {
                            continuation.resume(returning: coordinate)
                        }
                    }
                    
                    // Voeg foutafhandeling toe
                    delegate.onLocationError = { error in
                        print("📍 getCurrentLocation: Fout bij ophalen locatie: \(error)")
                        DispatchQueue.main.async {
                            continuation.resume(throwing: error)
                        }
                    }
                    
                                    // Houd delegate in leven tijdens de operatie
                tempLocationManager.delegate = delegate
                
                print("📍 getCurrentLocation: Start locatie opvragen")
                tempLocationManager.requestLocation()
                
                // Timeout na 10 seconden
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    print("📍 getCurrentLocation: Timeout bereikt")
                    // Controleer of de delegate al heeft gereageerd
                    if !delegate.hasResponded {
                        delegate.timeout()
                    }
                }
                }
            }
            
        @unknown default:
            print("📍 getCurrentLocation: Onbekende permissie status: \(status)")
            throw RoutePlanningError.locationPermissionDenied
        }
    }
}



// MARK: - Errors

enum RoutePlanningError: Error, LocalizedError {
    case invalidLocation
    case geocodingFailed
    case routeCalculationFailed(Error)
    case noRouteFound
    case tooManyWaypoints
    case locationPermissionDenied
    
    var errorDescription: String? {
        switch self {
        case .invalidLocation:
            return "Ongeldige locatie opgegeven"
        case .geocodingFailed:
            return "Kon adres niet vinden"
        case .routeCalculationFailed(let error):
            return "Route berekening mislukt: \(error.localizedDescription)"
        case .noRouteFound:
            return "Geen route gevonden tussen de opgegeven locaties"
        case .tooManyWaypoints:
            return "Te veel waypoints opgegeven"
        case .locationPermissionDenied:
            return "Locatie permissie geweigerd of niet beschikbaar"
        }
    }
}

// MARK: - MKPolyline Extension

extension MKPolyline {
    var coordinates: [CLLocationCoordinate2D] {
        var coordinates: [CLLocationCoordinate2D] = []
        let pointCount = self.pointCount
        
        coordinates.reserveCapacity(pointCount)
        
        for i in 0..<pointCount {
            var coordinate = CLLocationCoordinate2D()
            self.getCoordinates(&coordinate, range: NSRange(location: i, length: 1))
            coordinates.append(coordinate)
        }
        
        return coordinates
    }
}

// MARK: - Current Location Delegate

class CurrentLocationDelegate: NSObject, CLLocationManagerDelegate {
    private let onSuccess: (CLLocationCoordinate2D) -> Void
    var onLocationError: ((Error) -> Void)?
    var hasResponded = false
    
    init(onSuccess: @escaping (CLLocationCoordinate2D) -> Void) {
        self.onSuccess = onSuccess
        print("📍 CurrentLocationDelegate: Geïnitialiseerd")
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        print("📍 CurrentLocationDelegate: Locatie update ontvangen, \(locations.count) locaties")
        guard !hasResponded, let location = locations.first else { 
            print("📍 CurrentLocationDelegate: Geen geldige locatie of al gereageerd")
            return 
        }
        
        print("📍 CurrentLocationDelegate: Locatie succesvol: (\(location.coordinate.latitude), \(location.coordinate.longitude))")
        hasResponded = true
        onSuccess(location.coordinate)
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("📍 CurrentLocationDelegate: Locatie fout: \(error.localizedDescription)")
        guard !hasResponded else { 
            print("📍 CurrentLocationDelegate: Al gereageerd op fout")
            return 
        }
        hasResponded = true
        onLocationError?(error)
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("📍 CurrentLocationDelegate: Permissie status gewijzigd: \(status.rawValue)")
        // Permissie wijzigingen worden niet meer afgehandeld door de delegate
        // omdat de permissie al is gecontroleerd voordat de delegate wordt aangemaakt
    }
    
    nonisolated func timeout() {
        print("📍 CurrentLocationDelegate: Timeout aangeroepen")
        guard !hasResponded else { 
            print("📍 CurrentLocationDelegate: Al gereageerd op timeout")
            return 
        }
        hasResponded = true
        print("📍 CurrentLocationDelegate: Timeout, roep onLocationError aan")
        onLocationError?(RoutePlanningError.locationPermissionDenied)
    }
}
