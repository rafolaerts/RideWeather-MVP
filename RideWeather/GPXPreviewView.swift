//
//  GPXPreviewView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct GPXPreviewView: View {
    let gpxFile: GPXFile
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        NavigationView {
            List {
                Section("Route Information".localized) {
                    HStack {
                        Text("Filename".localized)
                        Spacer()
                        Text(gpxFile.fileName)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Total distance".localized)
                        Spacer()
                        
                        let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                        let distanceUnit = useMetricUnits ? "km" : "mi"
                        let distanceValue = useMetricUnits ? gpxFile.distance : gpxFile.distance * 0.621371
                        
                        Text("\(String(format: "%.1f", distanceValue)) \(distanceUnit)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Waypoints".localized)
                        Spacer()
                        Text("\(gpxFile.pointCount)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Route points".localized)
                        Spacer()
                        Text("\(gpxFile.routePoints.count)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section("Route Points".localized) {
                    ForEach(Array(gpxFile.routePoints.enumerated()), id: \.offset) { index, point in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(index + 1).")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 20, alignment: .leading)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("\(String(format: "%.4f", point.latitude)), \(String(format: "%.4f", point.longitude))")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let elevation = point.elevation {
                                        Text("Elevation: \(Int(elevation))m".localized)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                
                                Spacer()
                                
                                if index < gpxFile.segmentDistances.count {
                                    let useMetricUnits = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
                                    let distanceUnit = useMetricUnits ? "km" : "mi"
                                    let distanceValue = useMetricUnits ? gpxFile.segmentDistances[index] : gpxFile.segmentDistances[index] * 0.621371
                                    
                                    Text("\(String(format: "%.1f", distanceValue)) \(distanceUnit)")
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .navigationTitle("GPX Preview".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let testGPXFile = GPXFile(
        fileName: "test.gpx",
        distance: 50.0,
        pointCount: 100,
        routePoints: [],
        segmentDistances: [],
        distanceBetweenPoints: 1,
        originalPoints: []
    )
    
    GPXPreviewView(gpxFile: testGPXFile)
        .environmentObject(LanguageManager.shared)
}
