//
//  RoutePreviewView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI
import MapKit

struct RoutePreviewView: View {
    let plannedRoute: PlannedRoute
    let onConfirm: () -> Void
    let onCancel: () -> Void
    @EnvironmentObject var languageManager: LanguageManager
    
    @State private var region: MKCoordinateRegion
    @State private var selectedTab = 0
    
    init(plannedRoute: PlannedRoute, onConfirm: @escaping () -> Void, onCancel: @escaping () -> Void) {
        self.plannedRoute = plannedRoute
        self.onConfirm = onConfirm
        self.onCancel = onCancel
        
        // Initialize region with route bounding region
        self._region = State(initialValue: plannedRoute.boundingRegion)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Tab selector
                Picker("Route Details", selection: $selectedTab) {
                    Text("Map".localized).tag(0)
                    Text("Details".localized).tag(1)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content based on selected tab
                if selectedTab == 0 {
                    routeMapView
                } else {
                    routeDetailsView
                }
                
                // Action buttons
                actionButtons
            }
            .navigationTitle("Route Preview".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel".localized) {
                        onCancel()
                    }
                }
            }
        }
    }
    
    // MARK: - Route Map View
    
    private var routeMapView: some View {
        RoutePreviewMapView(plannedRoute: plannedRoute, region: $region)
            .overlay(alignment: .topTrailing) {
                // Zoom controls
                VStack(spacing: 8) {
                    Button(action: zoomIn) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                    
                    Button(action: zoomOut) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .background(Color.white)
                            .clipShape(Circle())
                    }
                }
                .padding(.trailing, 16)
                .padding(.top, 16)
            }
    }
    
    // MARK: - Route Details View
    
    private var routeDetailsView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Route summary
                routeSummarySection
                
                // Route information
                routeInfoSection
                
                // Waypoints
                if !plannedRoute.waypoints.isEmpty {
                    waypointsSection
                }
                
                // Route statistics
                routeStatsSection
            }
            .padding()
        }
    }
    
    // MARK: - Route Summary Section
    
    private var routeSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Samenvatting")
                .font(.headline)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Van:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plannedRoute.startLocation.displayName)
                        .font(.body)
                }
                
                Spacer()
                
                Image(systemName: "arrow.right")
                    .foregroundColor(.blue)
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Naar:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(plannedRoute.destination.displayName)
                        .font(.body)
                }
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Route Info Section
    
    private var routeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Informatie")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "car.fill")
                        .foregroundColor(.blue)
                    Text("Type:")
                    Spacer()
                    Text(plannedRoute.routeType.displayName)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "map.fill")
                        .foregroundColor(.green)
                    Text("Afstand:")
                    Spacer()
                    Text(String(format: "%.1f km", plannedRoute.distance))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.orange)
                    Text("Geschatte tijd:")
                    Spacer()
                    Text(formatDuration(plannedRoute.duration))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.red)
                    Text("Route punten:")
                    Spacer()
                    Text("\(plannedRoute.routePoints.count)")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Waypoints Section
    
    private var waypointsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Waypoints")
                .font(.headline)
            
            ForEach(Array(plannedRoute.waypoints.enumerated()), id: \.offset) { index, waypoint in
                HStack {
                    Text("\(index + 1).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 20, alignment: .leading)
                    
                    Text(waypoint.displayName)
                        .font(.body)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Route Stats Section
    
    private var routeStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Route Statistieken")
                .font(.headline)
            
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "speedometer")
                        .foregroundColor(.purple)
                    Text("Gemiddelde snelheid:")
                    Spacer()
                    let avgSpeed = plannedRoute.distance / (plannedRoute.duration / 3600)
                    Text(String(format: "%.0f km/h", avgSpeed))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Image(systemName: "arrow.up.arrow.down")
                        .foregroundColor(.brown)
                    Text("Hoogte variatie:")
                    Spacer()
                    Text("Berekening...")
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(Color.purple.opacity(0.1))
            .cornerRadius(8)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: onConfirm) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Route Bevestigen")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
            }
            
            Button(action: onCancel) {
                Text("Annuleren")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding()
        .background(Color.white)
        .shadow(radius: 2)
    }
    
    // MARK: - Helper Methods
    
    private func zoomIn() {
        withAnimation(.easeInOut(duration: 0.3)) {
            region.span.latitudeDelta *= 0.5
            region.span.longitudeDelta *= 0.5
        }
    }
    
    private func zoomOut() {
        withAnimation(.easeInOut(duration: 0.3)) {
            region.span.latitudeDelta *= 2.0
            region.span.longitudeDelta *= 2.0
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        
        if hours > 0 {
            return "\(hours)u \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}



// MARK: - Route Preview Map View

struct RoutePreviewMapView: UIViewRepresentable {
    let plannedRoute: PlannedRoute
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
        
        // Voeg route lijn toe
        mapView.addOverlay(plannedRoute.polyline)
        
        // Voeg annotations toe voor start, eind en waypoints
        var annotations: [MKPointAnnotation] = []
        
        // Start point
        if let startCoord = plannedRoute.startLocation.coordinate {
            let startAnnotation = MKPointAnnotation()
            startAnnotation.coordinate = startCoord
            startAnnotation.title = "Start"
            startAnnotation.subtitle = plannedRoute.startLocation.displayName
            annotations.append(startAnnotation)
        }
        
        // Waypoints
        for (index, waypoint) in plannedRoute.waypoints.enumerated() {
            if let coord = waypoint.coordinate {
                let waypointAnnotation = MKPointAnnotation()
                waypointAnnotation.coordinate = coord
                waypointAnnotation.title = "Waypoint \(index + 1)"
                waypointAnnotation.subtitle = waypoint.displayName
                annotations.append(waypointAnnotation)
            }
        }
        
        // Destination
        if let destCoord = plannedRoute.destination.coordinate {
            let destAnnotation = MKPointAnnotation()
            destAnnotation.coordinate = destCoord
            destAnnotation.title = "Bestemming"
            destAnnotation.subtitle = plannedRoute.destination.displayName
            annotations.append(destAnnotation)
        }
        
        mapView.addAnnotations(annotations)
        
        // Stel de region in
        mapView.setRegion(region, animated: false)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        var parent: RoutePreviewMapView
        
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
            return MKOverlayRenderer(overlay: overlay)
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // Skip user location annotation
            if annotation is MKUserLocation {
                return nil
            }
            
            let identifier = "RouteAnnotation"
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            
            if annotationView == nil {
                annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                annotationView?.canShowCallout = true
            }
            
            // Stel kleur in op basis van annotation type
            if annotation.title == "Start" {
                annotationView?.markerTintColor = .green
            } else if annotation.title == "Bestemming" {
                annotationView?.markerTintColor = .red
            } else {
                annotationView?.markerTintColor = .orange
            }
            
            return annotationView
        }
    }
}



#Preview {
    // Maak een sample polyline van Brussel naar Antwerpen
    let coordinates = [
        CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517), // Brussel
        CLLocationCoordinate2D(latitude: 50.9349, longitude: 4.4266), // Tussenliggend punt
        CLLocationCoordinate2D(latitude: 51.2194, longitude: 4.4025)  // Antwerpen
    ]
    let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
    
    let sampleRoute = PlannedRoute(
        startLocation: RouteLocation(coordinate: CLLocationCoordinate2D(latitude: 50.8503, longitude: 4.3517), address: "Brussel, België", name: "Brussel"),
        destination: RouteLocation(coordinate: CLLocationCoordinate2D(latitude: 51.2194, longitude: 4.4025), address: "Antwerpen, België", name: "Antwerpen"),
        waypoints: [],
        routeType: .fastest,
        distance: 45.2,
        duration: 3600,
        routePoints: [],
        polyline: polyline,
        boundingRegion: MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.0349, longitude: 4.4266), span: MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5))
    )
    
    return RoutePreviewView(
        plannedRoute: sampleRoute,
        onConfirm: {},
        onCancel: {}
    )
    .environmentObject(LanguageManager.shared)
}

