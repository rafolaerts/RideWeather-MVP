//
//  FileImportHandler.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import Foundation
import SwiftUI

// MARK: - File Import Handler

struct FileImportHandler {
    
    /// Verwerk het resultaat van een file picker
    static func handleFileImport(_ result: Result<[URL], Error>, gpxParser: GPXParser) -> (GPXFile?, String?) {
        do {
            let urls = try result.get()
            guard let url = urls.first else {
                return (nil, "Geen bestand geselecteerd")
            }
            
            guard url.pathExtension.lowercased() == "gpx" else {
                return (nil, "Selecteer een GPX bestand (.gpx)")
            }
            
            let gpxFile = try gpxParser.parseGPXFile(from: url)
            
            if gpxFile.routePoints.isEmpty {
                return (nil, "Geen route data gevonden in GPX bestand")
            }
            
            return (gpxFile, nil)
            
        } catch let gpxError as GPXParseError {
            let errorMessage: String
            switch gpxError {
            case .accessDenied:
                errorMessage = "Toegang geweigerd tot bestand. Probeer het bestand opnieuw te selecteren of controleer of het bestand toegankelijk is in de Bestanden app."
            case .noRouteData:
                errorMessage = "Geen route data gevonden in GPX bestand"
            case .parsingFailed:
                errorMessage = "Kon GPX bestand niet lezen. Controleer of het bestand niet beschadigd is."
            }
            return (nil, errorMessage)
        } catch {
            return (nil, "Fout bij het importeren: \(error.localizedDescription)")
        }
    }
    
    /// Valideer of een bestand een geldig GPX bestand is
    static func validateGPXFile(_ url: URL) -> Bool {
        return url.pathExtension.lowercased() == "gpx"
    }
    
    /// Haal de bestandsnaam op uit een URL
    static func getFileName(from url: URL) -> String {
        return url.lastPathComponent
    }
}
