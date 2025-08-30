# Motorcycle Trip Weather — Requirements Document  
*(Swift • SwiftUI • Xcode)*

---

## 1. App Context (AC-001)

We are a group of motor riders going on an 8-day trip in the Western Alps in September.  
While riding from about 09:00 to 18:00, we keep moving. The weather changes a lot along the way. We need to know: Will it be sunny? Hot or cold? Will it rain? Do we need our rain suit, and **when**?

The app should “know” where we will be at different times during the day.  
We will **upload a GPX route file**. From that file we get the **total distance**. The user gives a **start date/time** and an **arrival time** (same date). From distance and time, the app finds an **average speed**. Using this speed and the route path, the app can guess **where we will be at each time**. For those places and times, the app shows **weather** (chance of rain, rain amount, temperature).

GPX files can have **many waypoints**. Reading them all is slow. So we will **skip some points** to keep the app fast (for example, use every 10th point). The app should still give about **10–20 locations** spread along the route.

---

## 2. Main Goals (MG)

1. **MG-001:** Let the user upload a GPX file.  
2. **MG-002:** Let the user set a start date/time and an arrival time (same date).  
3. **MG-003:** Save all trip data so the user can view it later.  
4. **MG-004:** Allow the user to store **multiple trips**.  
5. **MG-005:** Pick **~10–20 route locations**, spread along the route, and estimate the **pass-by time** for each.  
6. **MG-006:** Show **weather** for each chosen location and time.  
7. **MG-007:** Let the user **refresh** the weather.

---

## 3. User Stories (US)

- **US-001:** As a user, I want to upload my route and get weather (especially rain) for the places and times I pass them, so I know when to wear my rain suit.  
- **US-002:** As a user, I want to upload the 8 routes for my 8-day trip so each morning I can check the day’s route weather and plan my gear.  
- **US-003:** As a user, I want to **replace** a GPX file for a planned route if plans change.
-**US-004:** As a user, I want to get notified while riding 5 or 10 minutes (settable by user, 5, 10, 15, 30min) before it starts to rain to put on my rain suit.

---

## 4. Features (F)

1. **F-001: Import GPX**  
   - **What it does:** Lets the user pick a `.gpx` file from Files or Share Sheet. (IOS files app)
   - **When it appears:** On the first screen and inside each trip.  
   - **If something goes wrong:** Show a clear message like “This file is not a valid GPX” or “We could not read the route.”

2. **F-002: Read Route & Downsample**  
   - **What it does:** Reads points from the GPX. Keeps the first and last points. Skips points (e.g., keep every 10th) to reduce the list to about **10–20** evenly spread points.  
   - **When it appears:** Right after import.  
   - **If something goes wrong:** Show “Route has no points” or “Too few points found.”

3. **F-003: Set Timing**  
   - **What it does:** User picks **Start Date & Time** and **Arrival Time** (same date). App computes **total duration** and **average speed** using the GPX distance.  
   - **When it appears:** During trip setup or edit.  
   - **If something goes wrong:** If times are the same or invalid, show “Please set a valid start and arrival time.”

4. **F-004: Time at Each Point**  
   - **What it does:** Using average speed and distance along the route, the app estimates the **pass time** for each chosen point.  
   - **When it appears:** After F-003.  
   - **If something goes wrong:** If math fails, show “We could not calculate times.”

5. **F-005: Weather Lookup**  
   - **What it does:** For each point and time, fetch **chance of rain**, **expected rain (mm)**, **temperature**, and **brief summary**.  
   - **When it appears:** On Trip Detail.  
   - **If something goes wrong:** Show “No internet” or “Weather service not available.” Allow **Retry**.
- **Weather data API:** Open weather API key: 58d9e3918af18c737fc466f593e87659

6. **F-006: Rain Focus View**  
   - **What it does:** Highlights points where rain is likely (e.g., chance ≥ 50% **and** rain ≥ 0.3 mm/h).  
   - **When it appears:** Toggle in Trip Detail.  
   - **If something goes wrong:** Show “Not enough data to highlight rain.”

7. **F-007: Refresh Weather**  
   - **What it does:** Pull to refresh or a Refresh button to update all weather.  
   - **When it appears:** Trip Detail.  
   - **If something goes wrong:** Keep old data; show “Could not refresh.”

8. **F-008: Save & Load Trips**  
   - **What it does:** Store trips on the device. User can add, view, rename, replace GPX, and delete trips.  
   - **When it appears:** Trip List and Trip Detail.  
   - **If something goes wrong:** Show “Could not save changes.” Never lose existing trips.

9. **F-009: Replace GPX for a Trip**  
   - **What it does:** Swap in a new GPX file for the same trip day; re-run distance, points, and times.  
   - **When it appears:** In Trip Detail (Edit).  
   - **If something goes wrong:** Keep the old GPX if the new one fails.

10. **F-010: Basic Settings**  
    - **What it does:** Choose point density (e.g., keep every 10th / 15th / 20th point), units (°C, mm), and default rain rule toggle.  
    - **When it appears:** Settings screen.  
    - **If something goes wrong:** Revert to defaults.

---

## 5. Screens (S)

1. **S-001: Trip List**  
   - **What’s on it:** App title, “Add Trip” button, list of saved trips (name, date, quick weather status if cached).  
   - **How to get here:** App launch, or Back from Trip Detail.

2. **S-002: Add Trip (Import GPX)**  
   - **What’s on it:** File picker button, basic instructions (“Pick your route GPX”), preview of route name and distance after import.  
   - **How to get here:** Tap “Add Trip” from S-001.

3. **S-003: Set Timing**  
   - **What’s on it:** Date & time pickers for **Start**, time picker for **Arrival** (same date), computed duration preview.  
   - **How to get here:** After a GPX is loaded (S-002 ➜ S-003) or Edit from Trip Detail.

4. **S-004: Trip Detail (Weather Along Route)**  
   - **What’s on it:**  
     - Summary card (trip name, date, start–arrival, distance, average speed).  
     - List (or simple map + list) of **~10–20 points** with **ETA** and **weather** (rain chance, rain mm, temp).  
     - “Highlight Rain” toggle.  
     - **Refresh** button.  
     - **Edit** (replace GPX, change timing).  
   - **How to get here:** Tap a trip in S-001.

5. **S-005: Settings**  
   - **What’s on it:** Point density selector, units, rain rule toggle (AND rule).  
   - **How to get here:** Settings icon from S-001.

---

## 6. Data (D)

- **D-001: Trip**  
  - A saved trip with: **id**, **name**, **date**, **start datetime**, **arrival time**, **total distance**, **average speed**, **created/updated timestamps**.

- **D-002: Route File Info**  
  - Original GPX file name, storage link/path (or stored content), and a short summary (first and last waypoint, total points).

- **D-003: Route Points (Downsampled)**  
  - List of **~10–20 points** with **latitude**, **longitude**, **distance from start**, and **estimated pass time**.

- **D-004: Weather Snapshot per Point**  
  - For each point/time: **fetch time**, **chance of rain (%)**, **rain amount (mm)**, **temperature (°C)**, **short text** (e.g., “Light rain”), and **data source tag**. Keep the **last good result**.

- **D-005: App Settings**  
  - Point density choice (e.g., every 10th), units, rain highlight rule.

---

## 7. Extra Details (X)

- **X-001: Internet:** Needed to fetch weather. App should work offline with **last saved data**.  
- **X-002: Storage:** Data saved **on the device** (no account needed).  
- **X-003: Permissions:**  
  - **Files/Document Picker** to import GPX.  
  - **Internet** access.  
  - **Location** not required for v1 (we use planned route).  
- **X-004: Timezone:** Use the phone’s timezone; show times clearly (e.g., 09:15).  
- **X-005: Dark Mode:** Support light and dark.  
- **X-006: Safety:** If the user is riding, keep screens simple, large text, and minimal taps.  
- **X-007: Limits:** GPX can be big. We downsample to stay fast.  
- **X-008: Non-Goals (v1):** No live tracking, no push alerts, no sharing.

---

## 8. Build Steps (B)

1. **B-001:** Set up project (SwiftUI app). Add **S-001 Trip List** (links MG-004).  
2. **B-002:** Build **F-001 Import GPX** on **S-002** and connect from S-001 (“Add Trip”). (MG-001)  
3. **B-003:** Parse GPX distance and raw points. Show a simple preview on S-002. (supports **D-002**)  
4. **B-004:** Implement **F-002 Downsample** to ~10–20 points. Store as **D-003**.  
5. **B-005:** Add **S-003 Set Timing** with pickers. Compute duration and **average speed**. Save to **D-001**. (MG-002)  
6. **B-006:** Implement **F-004 Time at Each Point** (compute pass times). Update **D-003**. (MG-005)  
7. **B-007:** Build **S-004 Trip Detail** list UI (points with ETA rows).  
8. **B-008:** Add **F-005 Weather Lookup** for each point/time. Save results to **D-004**. (MG-006)  
9. **B-009:** Add **F-007 Refresh Weather** (button + pull to refresh). Keep last good data. (MG-007)  
10. **B-010:** Add **F-006 Rain Focus View** (toggle highlight) on **S-004**.  
11. **B-011:** Implement **F-008 Save & Load Trips** (persist **D-001–D-005**). Make sure **S-001** shows all saved trips.
12. **B-012:** Add **F-009 Replace GPX** functionality in Trip Detail edit mode.
13. **B-013:** Build **S-005 Settings** screen with **F-010 Basic Settings**.
14. **B-014:** Add **F-006 Rain Focus View** toggle and highlighting logic.
15. **B-015:** Final testing and polish - ensure all user stories are met.

---

## 9. Testing (T)

1. **T-001: GPX Import Testing**
   - Test with various GPX file sizes and formats
   - Verify error handling for invalid files
   - Test file picker integration

2. **T-002: Route Processing Testing**
   - Verify downsampling produces 10-20 points
   - Test distance calculations accuracy
   - Verify timing calculations

3. **T-003: Weather API Testing**
   - Test weather fetching for different locations
   - Verify offline fallback behavior
   - Test refresh functionality

4. **T-004: Data Persistence Testing**
   - Verify trips are saved and loaded correctly
   - Test GPX replacement functionality
   - Ensure no data loss during app updates

5. **T-005: UI/UX Testing**
   - Test on different device sizes
   - Verify dark/light mode support
   - Test accessibility features

---

## 10. Security & Privacy (SP)

1. **SP-001: API Key Management**
   - Store OpenWeather API key securely (not in plain text)
   - Consider environment variables or secure storage
   - Monitor API usage to prevent abuse

2. **SP-002: Data Privacy**
   - All data stored locally on device
   - No user data transmitted to external services except weather API
   - GPX files remain private to user

3. **SP-003: Permissions**
   - Only request necessary permissions
   - Clear explanation of why each permission is needed
   - Graceful handling of permission denials

---

## 11. Performance Considerations (PC)

1. **PC-001: GPX Processing**
   - Target: Parse large GPX files in <2 seconds
   - Efficient downsampling algorithm
   - Memory management for large files

2. **PC-002: Weather Updates**
   - Batch weather API calls where possible
   - Cache weather data appropriately
   - Background refresh to minimize user wait time

3. **PC-003: UI Responsiveness**
   - Smooth scrolling with large trip lists
   - Fast navigation between screens
   - Minimal loading states

---

## 12. Enhancements (v2)

1. **FE-001: Live Weather Alerts**
   
   - Real-time weather updates during trips

2. **FE-004: Offline Maps**
   - Basic route visualization
   - Offline map tiles for remote areas

3. **FE-005: Trip Statistics**
   - Historical weather patterns
   - Best/worst weather times for routes
   - Weather trend analysis

## 13. Future Enhancements (v3)

1. **FE-002: Route Sharing**
   - Share trip routes with other riders
   - Collaborative trip planning

2. **FE-003: Advanced Weather Data**
   - Wind speed and direction
   - UV index and sun position
   - Air quality information

## 14. iOS File Permissions & Troubleshooting (IFP)

1. **IFP-001: Security-Scoped URLs**
   - iOS requires proper handling of security-scoped URLs for file access
   - Use `startAccessingSecurityScopedResource()` and `stopAccessingSecurityScopedResource()`
   - Always handle file access errors gracefully

2. **IFP-002: Common Permission Issues**
   - **"Permission denied" errors:** Usually caused by security restrictions
   - **File not accessible:** Check if file is in a protected location
   - **iCloud Drive restrictions:** Some folders may have limited access

3. **IFP-003: User Troubleshooting Steps**
   - Ensure GPX file is accessible in iOS Files app
   - Try opening the file first in Files app before importing
   - Check if file is not in a protected system folder
   - Verify file has .gpx extension
   - Try moving file to "On My iPhone" or "On My iPad" folder

4. **IFP-004: Developer Best Practices**
   - Implement proper error handling for all file operations
   - Provide clear, actionable error messages to users
   - Test with various file locations (iCloud, local, Downloads)
   - Handle both successful and failed file access gracefully

5. **IFP-005: Testing File Permissions**
   - Test with files in different locations (local, iCloud, Downloads)
   - Test with various file sizes and formats
   - Verify error messages are user-friendly and actionable
   - Test file replacement functionality
