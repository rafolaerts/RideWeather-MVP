//
//  AppIconView.swift
//  RideWeather
//
//  Created by Raf Olaerts on 26/08/2025.
//

import SwiftUI

struct AppIconView: View {
    var body: some View {
        ZStack {
            // Achtergrond gradient
            LinearGradient(
                colors: [Color.blue, Color.cyan],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Motorfiets icoon
            VStack(spacing: 8) {
                // Motorfiets body
                HStack(spacing: 2) {
                    // Voorwiel
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 3)
                        )
                    
                    // Motorfiets frame
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                        .frame(width: 60, height: 20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    
                    // Achterwiel
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 3)
                        )
                }
                
                // Weer icoon (wolk met zon)
                HStack(spacing: 4) {
                    Image(systemName: "cloud.sun.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                    
                    Image(systemName: "drop.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.cyan)
                }
            }
        }
        .frame(width: 1024, height: 1024)
        .clipped()
    }
}

#Preview {
    AppIconView()
        .frame(width: 200, height: 200)
        .clipShape(RoundedRectangle(cornerRadius: 40))
}
