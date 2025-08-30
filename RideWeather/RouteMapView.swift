//
//  RouteMapView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI
import CoreLocation
import MapKit

struct RouteMapView: View {
    let trip: Trip
    @State private var region: MKCoordinateRegion
    
    init(trip: Trip) {
        self.trip = trip
        
        // Bereken de region die alle route punten omvat
        let coordinates = trip.routePoints.map { $0.coordinate }
        var region = MKCoordinateRegion(coordinates: coordinates)
        
        // Voeg wat padding toe voor betere weergave
        let padding = 0.01 // Ongeveer 1km padding
        region.span.latitudeDelta = max(region.span.latitudeDelta + padding, 0.01)
        region.span.longitudeDelta = max(region.span.longitudeDelta + padding, 0.01)
        
        self._region = State(initialValue: region)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "map")
                    .foregroundColor(.blue)
                Text("Route Overview".localized)
                    .font(.headline)
                Spacer()
            }
            .padding(.horizontal)
            
            MapViewRepresentable(trip: trip, region: $region)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
        }
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Map View Representable

struct MapViewRepresentable: UIViewRepresentable {
    let trip: Trip
    @Binding var region: MKCoordinateRegion
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.isUserInteractionEnabled = true
        mapView.showsCompass = true
        mapView.showsScale = true
        
        return mapView
    }
    
    func updateUIView(_ mapView: MKMapView, context: Context) {
        // Verwijder bestaande overlays en annotations
        mapView.removeOverlays(mapView.overlays)
        mapView.removeAnnotations(mapView.annotations)
        
        guard trip.routePoints.count > 1 else { return }
        
        // Debug: Print route points
        print("🗺️ Route points count: \(trip.routePoints.count)")
        for (index, point) in trip.routePoints.enumerated() {
            print("   \(index): (\(point.latitude), \(point.longitude)) - \(point.distanceFromStart) km")
        }
        
        // Voeg route lijn toe - gebruik alle GPX punten voor nauwkeurige route
        // Sorteer route punten op basis van hun segment index om de juiste volgorde te garanderen
        let sortedRoutePoints = trip.routePoints.sorted { $0.segmentIndex < $1.segmentIndex }
        let coordinates = sortedRoutePoints.map { $0.coordinate }
        
        // Debug: Controleer coördinaten volgorde
        print("🗺️ Route points count: \(trip.routePoints.count)")
        print("🗺️ Sorted route points count: \(sortedRoutePoints.count)")
        print("🗺️ First coordinate (index 0): (\(coordinates.first?.latitude ?? 0), \(coordinates.first?.longitude ?? 0))")
        print("🗺️ Last coordinate (index \(sortedRoutePoints.count - 1)): (\(coordinates.last?.latitude ?? 0), \(coordinates.last?.longitude ?? 0))")
        
        // Debug: Print alle route punten met hun index
        for (index, point) in sortedRoutePoints.enumerated() {
            print("🗺️ Point \(index): (\(point.latitude), \(point.longitude)) - Distance: \(point.distanceFromStart) km - Index: \(point.segmentIndex)")
        }
        
        // Maak polyline met alle coördinaten
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
        print("🗺️ Added polyline with \(coordinates.count) coordinates for precise GPX route")
        
        // Voeg annotations toe voor start, eind en belangrijke punten
        for (index, point) in sortedRoutePoints.enumerated() {
            let annotation = MKPointAnnotation()
            annotation.coordinate = point.coordinate
            
            if index == 0 {
                annotation.title = "Start"
                annotation.subtitle = "0.0 km"
                print("🗺️ Added start annotation at (\(point.latitude), \(point.longitude)) - Index: \(point.segmentIndex)")
            } else if index == sortedRoutePoints.count - 1 {
                annotation.title = "Eind"
                annotation.subtitle = String(format: "%.1f km", point.distanceFromStart)
                print("🗺️ Added end annotation at (\(point.latitude), \(point.longitude)) - Index: \(point.segmentIndex)")
            } else if index % 5 == 0 { // Toon elke 5e punt
                annotation.title = String(format: "%.1f km", point.distanceFromStart)
                annotation.subtitle = point.estimatedPassTime.formatted(date: .omitted, time: .shortened)
                print("🗺️ Added waypoint annotation at (\(point.latitude), \(point.longitude)) - Index: \(point.segmentIndex)")
            }
            
            mapView.addAnnotation(annotation)
        }
        
        // Stel de region in
        mapView.setRegion(region, animated: false)
        print("🗺️ Set region: center (\(region.center.latitude), \(region.center.longitude)), span (\(region.span.latitudeDelta), \(region.span.longitudeDelta))")
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        
        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }
        
        // Custom styling voor de route lijn
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let polyline = overlay as? MKPolyline {
                let renderer = MKPolylineRenderer(polyline: polyline)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 5
                renderer.alpha = 0.9
                renderer.lineCap = .round
                renderer.lineJoin = .round
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
        
        // Custom styling voor de annotations
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip user location
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "RoutePoint"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            }
            
            // Bepaal het type marker op basis van de titel
            if annotation.title == "Start" {
                // Maak een groene start bol
                let startImage = createColoredCircleImage(color: .systemGreen, size: CGSize(width: 18, height: 18))
                annotationView?.image = startImage
            } else if annotation.title == "Eind" {
                // Maak een rode eind bol
                let endImage = createColoredCircleImage(color: .systemRed, size: CGSize(width: 18, height: 18))
                annotationView?.image = endImage
            } else {
                // Route punt marker - blauwe cirkel
                let pointImage = createColoredCircleImage(color: .systemBlue, size: CGSize(width: 8, height: 8))
                annotationView?.image = pointImage
            }
            
            return annotationView
        }
        
        // Helper functie om gekleurde cirkels te maken
        private func createColoredCircleImage(color: UIColor, size: CGSize) -> UIImage {
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                color.setFill()
                
                let circlePath = UIBezierPath(ovalIn: CGRect(origin: .zero, size: size))
                circlePath.fill()
            }
        }
    }
}

// MARK: - MKCoordinateRegion Extension

extension MKCoordinateRegion {
    init(coordinates: [CLLocationCoordinate2D]) {
        guard !coordinates.isEmpty else {
            self.init()
            return
        }
        
        let minLat = coordinates.map { $0.latitude }.min() ?? 0
        let maxLat = coordinates.map { $0.latitude }.max() ?? 0
        let minLon = coordinates.map { $0.longitude }.min() ?? 0
        let maxLon = coordinates.map { $0.longitude }.max() ?? 0
        
        // Check voor NaN waarden en vervang door geldige waarden
        let safeMinLat = minLat.isNaN ? 0 : minLat
        let safeMaxLat = maxLat.isNaN ? 0 : maxLat
        let safeMinLon = minLon.isNaN ? 0 : minLon
        let safeMaxLon = maxLon.isNaN ? 0 : maxLon
        
        let center = CLLocationCoordinate2D(
            latitude: (safeMinLat + safeMaxLat) / 2,
            longitude: (safeMinLon + safeMaxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: max((safeMaxLat - safeMinLat) * 1.1, 0.01), // Minimum span van 0.01
            longitudeDelta: max((safeMaxLon - safeMinLon) * 1.1, 0.01) // Minimum span van 0.01
        )
        
        self.init(center: center, span: span)
    }
}
