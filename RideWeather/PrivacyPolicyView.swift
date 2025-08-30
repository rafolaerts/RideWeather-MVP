import SwiftUI

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Privacy Policy - RideWeather")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    HStack {
                        Text("Laatst bijgewerkt:")
                            .foregroundColor(.secondary)
                        Text("26 augustus 2025")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Versie:")
                            .foregroundColor(.secondary)
                        Text("1.0")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Contact:")
                            .foregroundColor(.secondary)
                        Text("info@castle14.be")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
                .padding(.bottom)
                
                // Privacy Policy Content
                Group {
                    sectionHeader("1. Inleiding")
                    Text("Welkom bij RideWeather. Deze privacy policy legt uit hoe wij omgaan met uw persoonlijke gegevens wanneer u onze mobiele applicatie gebruikt. RideWeather is ontwikkeld door Castle14 en respecteert uw privacy.")
                    
                    sectionHeader("2. Verantwoordelijke voor de Verwerking")
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Naam: Castle14")
                        Text("E-mail: info@castle14.be")
                        Text("Jurisdictie: Europese Unie (GDPR)")
                    }
                    
                    sectionHeader("3. Welke Gegevens Verzamelen Wij?")
                    
                    Text("3.1 Gegevens die u ons verstrekt:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• OpenWeatherMap API Sleutel: U kunt optioneel uw eigen API sleutel invoeren voor weerdata")
                        Text("• GPX Routebestanden: U kunt uw eigen motorroutes importeren")
                        Text("• App Instellingen: Uw voorkeuren voor eenheden (metrisch/imperiaal), regenregels en taal")
                    }
                    
                    Text("3.2 Gegevens die automatisch worden verzameld:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Locatiegegevens: Alleen wanneer u de app gebruikt voor routeplanning vanaf uw huidige positie")
                        Text("• App Gebruik: Lokale opslag van uw routes en weerdata voor app functionaliteit")
                    }
                    
                    Text("3.3 Gegevens die wij NIET verzamelen:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Persoonlijke identificatiegegevens (naam, e-mail, telefoonnummer)")
                        Text("• Financiële gegevens")
                        Text("• Biometrische gegevens")
                        Text("• Gezondheidsgegevens")
                    }
                    
                    sectionHeader("4. Hoe Gebruiken Wij Uw Gegevens?")
                    
                    Text("4.1 Doel van de Verwerking:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• App Functionaliteit: Uw routes en weerdata lokaal opslaan en weergeven")
                        Text("• Weer Informatie: Weerdata ophalen via OpenWeatherMap API op basis van uw routes")
                        Text("• Routeplanning: Locatiegegevens gebruiken voor routeplanning vanaf uw huidige positie")
                        Text("• Taal en Instellingen: Uw app voorkeuren onthouden")
                    }
                    
                    sectionHeader("5. Data Opslag en Beveiliging")
                    
                    Text("5.1 Opslag Locatie:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Alle gegevens worden lokaal op uw apparaat opgeslagen")
                        Text("• Geen cloud opslag of externe servers")
                        Text("• Geen gegevens worden naar Castle14 of derden verzonden")
                    }
                    
                    sectionHeader("6. Delen van Gegevens")
                    
                    Text("6.1 Wij delen uw gegevens NIET met:")
                        .fontWeight(.semibold)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Adverteerders")
                        Text("• Analytics bedrijven")
                        Text("• Sociale media platforms")
                        Text("• Andere derde partijen")
                    }
                    
                    sectionHeader("7. Uw Rechten onder GDPR")
                    
                    Text("Als EU-burger heeft u de volgende rechten:")
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Recht op Toegang: U kunt uw opgeslagen gegevens bekijken via de app")
                        Text("• Recht op Rectificatie: U kunt uw instellingen en voorkeuren wijzigen via de app")
                        Text("• Recht op Verwijdering: U kunt uw gegevens verwijderen via de app instellingen")
                        Text("• Recht op Gegevensportabiliteit: U kunt uw GPX bestanden exporteren naar andere apps")
                        Text("• Recht op Beperking: U kunt bepaalde app functies uitschakelen")
                        Text("• Recht op Bezwaar: U kunt bezwaar maken tegen verwerking van uw gegevens")
                    }
                    
                    sectionHeader("8. Locatie Services")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Alleen wanneer de app actief is")
                        Text("• Voor routeplanning vanaf uw huidige positie")
                        Text("• Geen achtergrond locatie tracking")
                        Text("• U kunt locatietoegang altijd intrekken via uw apparaat instellingen")
                    }
                    
                    sectionHeader("9. Cookies en Tracking")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Wij gebruiken geen cookies")
                        Text("• Wij doen geen gebruikers tracking")
                        Text("• Wij verzamelen geen analytics data")
                    }
                    
                    sectionHeader("10. Kinderen")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• RideWeather is niet bedoeld voor kinderen onder 13 jaar")
                        Text("• Wij verzamelen bewust geen gegevens van kinderen onder 13 jaar")
                        Text("• Als u een ouder bent en denkt dat uw kind gegevens heeft gedeeld, neem dan contact op")
                    }
                    
                    sectionHeader("11. Wijzigingen in deze Privacy Policy")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("• Wij kunnen deze privacy policy bijwerken")
                        Text("• Belangrijke wijzigingen worden via de app aangekondigd")
                        Text("• U wordt geadviseerd de policy regelmatig te controleren")
                    }
                    
                    sectionHeader("12. Contact")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Voor vragen over deze privacy policy of uw gegevens:")
                        Text("E-mail: info@castle14.be")
                            .fontWeight(.medium)
                        Text("Onderwerp: Privacy Policy Vraag")
                            .foregroundColor(.secondary)
                    }
                    
                    sectionHeader("13. Klachten")
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Als u een klacht heeft over onze verwerking van uw gegevens, kunt u:")
                        VStack(alignment: .leading, spacing: 4) {
                            Text("1. Contact opnemen met ons via info@castle14.be")
                            Text("2. Een klacht indienen bij de Belgische Gegevensbeschermingsautoriteit (APD/GBA)")
                        }
                    }
                    
                    sectionHeader("14. Toepasselijk Recht")
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Deze privacy policy wordt beheerst door en geïnterpreteerd in overeenstemming met:")
                        Text("• Belgische wetgeving")
                        Text("• EU General Data Protection Regulation (GDPR)")
                        Text("• Relevante privacy wetten")
                    }
                }
                
                // Footer
                VStack(spacing: 8) {
                    Divider()
                    HStack {
                        Text("Laatste bijwerking:")
                            .foregroundColor(.secondary)
                        Text("26 augustus 2025")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Versie:")
                            .foregroundColor(.secondary)
                        Text("1.0")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Contact:")
                            .foregroundColor(.secondary)
                        Text("info@castle14.be")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
                .padding(.top)
            }
            .padding()
        }
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.title2)
            .fontWeight(.bold)
            .padding(.top, 8)
    }
}

#Preview {
    NavigationView {
        PrivacyPolicyView()
            .environmentObject(LanguageManager.shared)
    }
}
