# Privacy Policy - RideWeather App

## Overzicht

Deze documentatie beschrijft de implementatie van de privacy policy voor de RideWeather app, die voldoet aan EU GDPR vereisten en App Store goedkeuring.

## Bestanden

### 1. PrivacyPolicy.md
- **Locatie:** `RideWeather/PrivacyPolicy.md`
- **Doel:** Volledige privacy policy tekst in Markdown formaat
- **Gebruik:** Referentie document voor ontwikkelaars en juridische review

### 2. PrivacyPolicyView.swift
- **Locatie:** `RideWeather/PrivacyPolicyView.swift`
- **Doel:** SwiftUI view die de privacy policy weergeeft in de app
- **Functies:**
  - Scrollbare privacy policy weergave
  - Ondersteuning voor Nederlands en Engels
  - Integratie met app navigatie

### 3. Lokalisatie
- **Engels:** `RideWeather/en.lproj/Localizable.strings`
  - `"Privacy Policy" = "Privacy Policy";`
- **Nederlands:** `RideWeather/nl.lproj/Localizable.strings`
  - `"Privacy Policy" = "Privacybeleid";`

### 4. Integratie in SettingsView
- **Locatie:** `RideWeather/SettingsView.swift`
- **Implementatie:** NavigationLink naar PrivacyPolicyView in APP INFORMATION sectie

## App Store Vereisten

### ✅ Voldaan aan:
- **Privacy Policy Link:** Beschikbaar in app instellingen
- **GDPR Compliance:** Volledige EU privacy wetgeving ondersteuning
- **Data Transparantie:** Duidelijke uitleg van dataverzameling en gebruik
- **Gebruikersrechten:** Alle GDPR rechten gedocumenteerd
- **Contact Informatie:** Duidelijke contactgegevens voor privacy vragen

### 📱 App Store Metadata:
- **Privacy Policy URL:** Moet worden toegevoegd aan App Store Connect
- **Data Gebruik:** App Store privacy labels zijn correct geconfigureerd
- **Tracking:** Geen tracking functionaliteit (NSPrivacyTracking = false)

## Juridische Compliance

### EU GDPR Artikel 13 & 14:
- ✅ **Identiteit van de verwerkingsverantwoordelijke**
- ✅ **Doel en rechtsgrond van de verwerking**
- ✅ **Gerechtvaardigde belangen**
- ✅ **Ontvangers van persoonsgegevens**
- ✅ **Bewaartermijn**
- ✅ **Rechten van betrokkenen**
- ✅ **Klachtenrecht**
- ✅ **Toestemming mechanismen**

### Belgische Wetgeving:
- ✅ **APD/GBA compliance**
- ✅ **Lokale jurisdictie specificatie**
- ✅ **Nederlandse taal ondersteuning**

## Implementatie Details

### Data Verzameling:
- **Lokale Opslag:** Alle data wordt lokaal opgeslagen (Core Data)
- **Geen Cloud:** Geen externe servers of cloud opslag
- **Geen Analytics:** Geen tracking of analytics tools
- **API Gebruik:** Alleen OpenWeatherMap voor weerdata

### Gebruikersrechten:
- **Toegang:** Via app instellingen
- **Rectificatie:** Via app instellingen
- **Verwijdering:** Via app instellingen en app verwijdering
- **Portabiliteit:** GPX export functionaliteit
- **Beperking:** App functies kunnen worden uitgeschakeld

### Beveiliging:
- **Lokale Encryptie:** Core Data encryptie
- **HTTPS API:** Veilige communicatie met OpenWeatherMap
- **Geen Externe Toegang:** Geen data wordt gedeeld

## Onderhoud

### Updates:
1. **Tekst Wijzigingen:** Bewerk `PrivacyPolicy.md`
2. **View Updates:** Bewerk `PrivacyPolicyView.swift` indien nodig
3. **Lokalisatie:** Update beide taalbestanden
4. **Versie Update:** Verhoog versienummer en datum

### Review Cyclus:
- **Kwartaal:** Technische review van implementatie
- **Halfjaar:** Juridische review van inhoud
- **Jaarlijks:** Volledige compliance audit

## Contact

Voor vragen over deze privacy policy implementatie:
- **E-mail:** info@castle14.be
- **Onderwerp:** Privacy Policy Implementatie

---

**Laatste Update:** 26 augustus 2025  
**Versie:** 1.0  
**Status:** ✅ Implementatie Voltooid
