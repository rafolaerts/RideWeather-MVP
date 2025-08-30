//
//  GPXParser.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import CoreLocation

class GPXParser: NSObject, XMLParserDelegate {
    private var parser: XMLParser?
    private var currentElement = ""
    private var currentTrack: GPXTrack?
    private var currentTrackSegment: GPXTrackSegment?
    private var currentWaypoint: GPXWaypoint?
    private var tracks: [GPXTrack] = []
    private var routes: [GPXRoute] = []
    private var waypoints: [GPXWaypoint] = []
    
    // Parsing state
    private var isInTrack = false
    private var isInTrackSegment = false
    private var isInRoute = false
    private var isInRoutePoint = false
    private var isInWaypoint = false
    
    // Temporary data storage
    private var currentRoute: GPXRoute?
    private var tempLatitude: String = ""
    private var tempLongitude: String = ""
    private var tempElevation: String = ""
    private var tempTime: String = ""
    private var tempName: String = ""
    
    func parseGPXFile(from url: URL, distanceBetweenPoints: Double = 10.0) throws -> GPXFile {
        // Start accessing the security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            throw GPXParseError.accessDenied
        }
        
        defer {
            // Always stop accessing the security-scoped resource
            url.stopAccessingSecurityScopedResource()
        }
        
        let data = try Data(contentsOf: url)
        return try parseGPXData(data, fileName: url.lastPathComponent, distanceBetweenPoints: distanceBetweenPoints)
    }
    
    func parseGPXData(_ data: Data, fileName: String, distanceBetweenPoints: Double = 10.0) throws -> GPXFile {
        parser = XMLParser(data: data)
        parser?.delegate = self
        
        // Reset state
        tracks.removeAll()
        routes.removeAll()
        waypoints.removeAll()
        currentTrack = nil
        currentTrackSegment = nil
        currentWaypoint = nil
        currentRoute = nil
        
        if parser?.parse() == true {
            // Bereken totale afstand en downsampled punten
            let allPoints = getAllRoutePoints()
            
            guard !allPoints.isEmpty else {
                throw GPXParseError.noRouteData
            }
            
            // Bereken totale afstand op basis van ALLE punten (voor accurate afstand)
            let totalDistance = calculateTotalDistance(from: allPoints)
            
            // Downsample naar instelbare afstand tussen punten - gebruik afstandsgebaseerde verdeling
            let downsampledPoints = downsamplePointsByDistance(allPoints, distanceBetweenPoints: distanceBetweenPoints)
            
            // Bereken afstanden per segment voor efficiënte berekening
            let segmentDistances = calculateSegmentDistances(from: downsampledPoints)
            
            return GPXFile(
                fileName: fileName,
                distance: totalDistance,
                pointCount: allPoints.count,
                routePoints: downsampledPoints,
                segmentDistances: segmentDistances,
                distanceBetweenPoints: distanceBetweenPoints,
                originalPoints: allPoints
            )
        } else {
            throw GPXParseError.parsingFailed
        }
    }
    
    /// Herverwerkt een bestaand GPX bestand met een nieuwe afstand tussen routepunten
    func reprocessGPXFile(_ gpxFile: GPXFile, with newDistanceBetweenPoints: Double) throws -> GPXFile {
        print("🔄 GPXParser: Herverwerken van \(gpxFile.fileName)")
        print("   - Originele punten: \(gpxFile.originalPoints.count)")
        print("   - Huidige route punten: \(gpxFile.routePoints.count)")
        print("   - Nieuwe afstand tussen punten: \(newDistanceBetweenPoints) km")
        
        // Gebruik de originele GPX punten voor herverwerking
        let allPoints = gpxFile.originalPoints
        
        // Downsample naar nieuwe afstand tussen punten - gebruik afstandsgebaseerde verdeling
        let downsampledPoints = downsamplePointsByDistance(allPoints, distanceBetweenPoints: newDistanceBetweenPoints)
        
        print("   - Nieuwe downsampled punten: \(downsampledPoints.count)")
        
        // Bereken afstanden per segment voor efficiënte berekening
        let segmentDistances = calculateSegmentDistances(from: downsampledPoints)
        
        let newGPXFile = GPXFile(
            fileName: gpxFile.fileName,
            distance: gpxFile.distance,
            pointCount: gpxFile.pointCount,
            routePoints: downsampledPoints,
            segmentDistances: segmentDistances,
            distanceBetweenPoints: newDistanceBetweenPoints,
            originalPoints: gpxFile.originalPoints
        )
        
        print("✅ GPXParser: Herverwerking voltooid")
        print("   - Nieuwe GPX bestand route punten: \(newGPXFile.routePoints.count)")
        
        return newGPXFile
    }
    
    // MARK: - XML Parsing Methods
    
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String] = [:]) {
        currentElement = elementName
        
        switch elementName {
        case "trk":
            isInTrack = true
            currentTrack = GPXTrack()
            
        case "trkseg":
            isInTrackSegment = true
            currentTrackSegment = GPXTrackSegment()
            
        case "trkpt":
            isInTrackSegment = true
            currentWaypoint = GPXWaypoint()
            if let lat = attributeDict["lat"], let lon = attributeDict["lon"] {
                tempLatitude = lat
                tempLongitude = lon
            }
            
        case "rte":
            isInRoute = true
            currentRoute = GPXRoute()
            
        case "rtept":
            isInRoutePoint = true
            currentWaypoint = GPXWaypoint()
            if let lat = attributeDict["lat"], let lon = attributeDict["lon"] {
                tempLatitude = lat
                tempLongitude = lon
            }
            
        case "wpt":
            isInWaypoint = true
            currentWaypoint = GPXWaypoint()
            if let lat = attributeDict["lat"], let lon = attributeDict["lon"] {
                tempLatitude = lat
                tempLongitude = lon
            }
            
        default:
            break
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        switch elementName {
        case "trk":
            if let track = currentTrack {
                tracks.append(track)
            }
            isInTrack = false
            currentTrack = nil
            
        case "trkseg":
            if let segment = currentTrackSegment, var track = currentTrack {
                track.segments.append(segment)
                currentTrack = track
            }
            isInTrackSegment = false
            currentTrackSegment = nil
            
        case "trkpt", "rtept", "wpt":
            if var waypoint = currentWaypoint {
                // Finalize waypoint
                if let lat = Double(tempLatitude), let lon = Double(tempLongitude) {
                    waypoint.latitude = lat
                    waypoint.longitude = lon
                    
                    if let elevation = Double(tempElevation) {
                        waypoint.elevation = elevation
                    }
                    
                    if let time = parseGPXTime(tempTime) {
                        waypoint.time = time
                    }
                    
                    if !tempName.isEmpty {
                        waypoint.name = tempName
                    }
                    
                    // Add to appropriate collection
                    if isInTrackSegment {
                        if var segment = currentTrackSegment {
                            segment.points.append(waypoint)
                            currentTrackSegment = segment
                        }
                    } else if isInRoute {
                        if var route = currentRoute {
                            route.points.append(waypoint)
                            currentRoute = route
                        }
                    } else {
                        waypoints.append(waypoint)
                    }
                }
            }
            
            // Reset temp data
            tempLatitude = ""
            tempLongitude = ""
            tempElevation = ""
            tempTime = ""
            tempName = ""
            currentWaypoint = nil
            isInWaypoint = false
            
        case "ele":
            if isInWaypoint || isInTrackSegment || isInRoutePoint {
                tempElevation = currentElement
            }
            
        case "time":
            if isInWaypoint || isInTrackSegment || isInRoutePoint {
                tempTime = currentElement
            }
            
        case "name":
            if isInWaypoint || isInTrackSegment || isInRoutePoint {
                tempName = currentElement
            }
            
        default:
            break
        }
        
        currentElement = ""
    }
    
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            switch currentElement {
            case "ele":
                tempElevation += trimmed
            case "time":
                tempTime += trimmed
            case "name":
                tempName += trimmed
            default:
                break
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func getAllRoutePoints() -> [GPXWaypoint] {
        var allPoints: [GPXWaypoint] = []
        
        // Add track points
        for track in tracks {
            for segment in track.segments {
                allPoints.append(contentsOf: segment.points)
            }
        }
        
        // Add route points if no tracks
        if allPoints.isEmpty {
            allPoints = waypoints
        }
        
        // Als er nog steeds geen punten zijn, probeer routes
        if allPoints.isEmpty {
            for route in routes {
                allPoints.append(contentsOf: route.points)
            }
        }
        
        return allPoints
    }
    
    private func calculateDistance(from coord1: CLLocationCoordinate2D, to coord2: CLLocationCoordinate2D) -> Double {
        let location1 = CLLocation(latitude: coord1.latitude, longitude: coord1.longitude)
        let location2 = CLLocation(latitude: coord2.latitude, longitude: coord2.longitude)
        return location1.distance(from: location2) / 1000.0 // Convert to kilometers
    }
    
    private func calculateTotalDistance(from points: [GPXWaypoint]) -> Double {
        guard points.count > 1 else { return 0.0 }
        
        var totalDistance: Double = 0.0
        
        for i in 0..<(points.count - 1) {
            let point1 = points[i]
            let point2 = points[i + 1]
            
            let distance = self.calculateDistance(
                from: CLLocationCoordinate2D(latitude: point1.latitude, longitude: point1.longitude),
                to: CLLocationCoordinate2D(latitude: point2.latitude, longitude: point2.longitude)
            )
            
            totalDistance += distance
        }
        
        return totalDistance
    }
    
    /// Afstandsgebaseerde downsampling die routepunten genereert op exacte afstanden
    private func downsamplePointsByDistance(_ points: [GPXWaypoint], distanceBetweenPoints: Double) -> [GPXWaypoint] {
        guard points.count > 1 else { return points }
        
        var downsampled: [GPXWaypoint] = []
        
        // Always include first point
        downsampled.append(points.first!)
        
        // Bereken cumulatieve afstanden voor alle punten
        var cumulativeDistances: [Double] = [0.0]
        var totalDistance: Double = 0.0
        
        for i in 1..<points.count {
            let segmentDistance = calculateDistance(
                from: CLLocationCoordinate2D(latitude: points[i-1].latitude, longitude: points[i-1].longitude),
                to: CLLocationCoordinate2D(latitude: points[i].latitude, longitude: points[i].longitude)
            )
            totalDistance += segmentDistance
            cumulativeDistances.append(totalDistance)
        }
        
        // Bereken hoeveel tussenliggende routepunten we nodig hebben
        let numberOfIntermediatePoints = Int(floor(totalDistance / distanceBetweenPoints))
        
        print("🔄 downsamplePointsByDistance: Total distance: \(totalDistance) km, distance between points: \(distanceBetweenPoints) km, calculated intermediate points: \(numberOfIntermediatePoints)")
        
        // Genereer tussenliggende routepunten op exacte afstanden
        for i in 1...numberOfIntermediatePoints {
            let targetDistance = Double(i) * distanceBetweenPoints
            
            // Zoek het punt dat het dichtst bij de target afstand ligt
            var bestIndex = 1
            var bestDistanceDiff = abs(cumulativeDistances[1] - targetDistance)
            
            for j in 1..<cumulativeDistances.count - 1 {
                let distanceDiff = abs(cumulativeDistances[j] - targetDistance)
                if distanceDiff < bestDistanceDiff {
                    bestDistanceDiff = distanceDiff
                    bestIndex = j
                }
            }
            
            // Voeg het beste punt toe (alleen als het niet al bestaat)
            let candidatePoint = points[bestIndex]
            if !downsampled.contains(where: { $0.latitude == candidatePoint.latitude && $0.longitude == candidatePoint.longitude }) {
                downsampled.append(candidatePoint)
            }
        }
        
        // Always include last point (eindpunt van de route)
        if points.count > 1 {
            let lastPoint = points.last!
            if !downsampled.contains(where: { $0.latitude == lastPoint.latitude && $0.longitude == lastPoint.longitude }) {
                downsampled.append(lastPoint)
            }
        }
        
        print("✅ downsamplePointsByDistance: Generated \(downsampled.count) route points")
        print("   - First point at 0.0 km")
        print("   - Last point at \(totalDistance) km (full route coverage)")
        return downsampled
    }
    
    private func calculateSegmentDistances(from points: [GPXWaypoint]) -> [Double] {
        guard points.count > 1 else { return [] }
        
        var distances: [Double] = []
        
        for i in 0..<(points.count - 1) {
            let point1 = points[i]
            let point2 = points[i + 1]
            
            let distance = self.calculateDistance(
                from: CLLocationCoordinate2D(latitude: point1.latitude, longitude: point1.longitude),
                to: CLLocationCoordinate2D(latitude: point2.latitude, longitude: point2.longitude)
            )
            
            distances.append(distance)
        }
        
        return distances
    }
    
    private func parseGPXTime(_ timeString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: timeString)
    }
}

// MARK: - GPX Data Models

struct GPXFile {
    let fileName: String
    let distance: Double // in kilometers
    let pointCount: Int
    let routePoints: [GPXWaypoint]
    let segmentDistances: [Double] // Afstanden tussen opeenvolgende punten
    let distanceBetweenPoints: Double // Afstand tussen opeenvolgende routepunten in kilometers
    let originalPoints: [GPXWaypoint] // Originele GPX punten voor herverwerking
}

struct GPXTrack {
    var segments: [GPXTrackSegment] = []
}

struct GPXTrackSegment {
    var points: [GPXWaypoint] = []
}

struct GPXRoute {
    var points: [GPXWaypoint] = []
}

struct GPXWaypoint {
    var latitude: Double = 0.0
    var longitude: Double = 0.0
    var elevation: Double?
    var time: Date?
    var name: String = ""
}

// MARK: - Errors

enum GPXParseError: Error, LocalizedError {
    case parsingFailed
    case noRouteData
    case accessDenied
    
    var errorDescription: String? {
        switch self {
        case .parsingFailed:
            return "Failed to parse GPX file"
        case .noRouteData:
            return "No route data found in GPX file"
        case .accessDenied:
            return "Access to file denied"
        }
    }
}
