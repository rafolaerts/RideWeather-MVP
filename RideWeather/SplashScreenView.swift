import SwiftUI

struct SplashScreenView: View {
    @State private var showSplash = true
    @State private var dontShowAgain = false
    @AppStorage("hasSeenSplashScreen") private var hasSeenSplashScreen = false
    
    var body: some View {
        if showSplash && !hasSeenSplashScreen {
            ZStack {
                // Gradient achtergrond van wit naar blauw (geen transparantie)
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white,
                        Color.white,
                        Color.white,
                        Color.blue.opacity(0.9),
                        Color.blue
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Logo - nu groter
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 150, height: 150)
                        .shadow(radius: 10)
                    
                    // App naam
                    Text("RideWeather")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                        .shadow(radius: 5)
                    
                    // Uitleg over weersvoorspelling betrouwbaarheid
                    VStack(spacing: 20) {
                        Text("Weersvoorspelling Betrouwbaarheid")
                            .font(.headline)
                            .foregroundColor(.blue)
                            .shadow(radius: 3)
                            .multilineTextAlignment(.center)
                        
                        VStack(spacing: 15) {
                            ReliabilityRow(
                                icon: "checkmark.circle.fill",
                                color: .green,
                                text: "Tot 24 uur: Betrouwbaar"
                            )
                            
                            ReliabilityRow(
                                icon: "exclamationmark.circle.fill",
                                color: .orange,
                                text: "Tot 48 uur: Redelijk betrouwbaar"
                            )
                            
                            ReliabilityRow(
                                icon: "exclamationmark.triangle.fill",
                                color: .red,
                                text: "Meer dan 3 dagen: Onbetrouwbaar"
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                    
                    // Checkbox "niet meer tonen" - zonder box, wit van kleur
                    Button(action: {
                        dontShowAgain.toggle()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: dontShowAgain ? "checkmark.square.fill" : "square")
                                .foregroundColor(.white)
                                .font(.title2)
                                .frame(width: 24, height: 24)
                            
                            Text("Niet meer tonen")
                                .foregroundColor(.white)
                                .font(.body)
                                .fontWeight(.medium)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.bottom, 40)
                }
                
                // Onzichtbare tap area over het hele scherm
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        closeSplashScreen()
                    }
            }
        }
    }
    
    private func closeSplashScreen() {
        withAnimation(.easeInOut(duration: 0.5)) {
            showSplash = false
        }
        
        if dontShowAgain {
            hasSeenSplashScreen = true
        }
    }
}

struct ReliabilityRow: View {
    let icon: String
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
                .frame(width: 25)
            
            Text(text)
                .foregroundColor(.blue)
                .font(.body)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
            
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 15)
        .background(Color.white)
        .cornerRadius(10)
    }
}

#Preview {
    SplashScreenView()
}
