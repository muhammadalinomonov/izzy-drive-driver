1. Task
Implement a top `TabBar` with two tabs:

* **Trips**
* **Masters**

The UI should match the design shown in **`1.png`**.

### Requirements

1. Create a top `TabBar` with icons from the **`docs/icons`** folder.
2. Use a `TabBarView` (or `PageView`) to switch between pages.
3. **Do not modify the existing `Masters` page.** Keep it exactly as it is.
4. Add a new **Trips** page as the first tab.

### Trips Page

* Display the user's complete trip history.
* Load the data from the following API:

```
GET https://toll.quadrix.ai/api/v1/mobile/toll-routes
```

* Follow the API specification in:

```
docs/mobile-api.md
```

### Implementation Notes

* Reuse the existing networking architecture (API client, repository, state management, models, etc.).
* Create models for the trip response if they do not already exist.
* Implement proper loading, empty, and error states.
* Support pull-to-refresh.
* Use pagination if it is described in `docs/mobile-api.md`.
* Match the spacing, typography, icons, and colors from `1.png`.
* Keep the implementation clean, modular, and consistent with the existing project architecture.


WARNING: the api is new, create new constants for this api at the base or code

-----------------------------------------------------------------------------------------------------

2. Task

Add a search bar to the Trips section on the Home page. The search bar should be read-only and act 
as an entry point to the trip planning flow. When the user taps the search bar, navigate to the Trip 
Map Page, which should match the design shown in docs/ui/2.png.

The Trip Map Page should consist of a full-screen MapBox map with a draggable modal bottom sheet 
overlaid on top. The bottom sheet should support collapsed, half-expanded, and fully expanded states, 
opening in the half-expanded position by default.

At the top of the bottom sheet, display the title "Locations" followed by two search fields:

Current Location (start location)
Destination (finish location)

The Current Location field should be prefilled with the user's current GPS location when the page 
opens, while the Destination field should initially be empty with the placeholder "Write address..." 
or "Where to?". Both fields are editable and use different icons (current location pin and destination flag).

Only one text field can be active at a time. When the user taps either field, it becomes focused, 
the keyboard appears, and that field is highlighted as the active search target. As the user types, 
search requests should be sent to:

GET https://toll-api.quadrix.ai/api/v1/mobile/places

Implement request debouncing (approximately 300–500 ms) and cancel any previous pending requests 
when new input is entered.

While the user is typing, the lower portion of the bottom sheet should automatically switch from 
displaying recent location history to displaying live search suggestions returned by the Places API. 
Each suggestion should include a location icon, the place name, and an optional secondary address. 
This search suggestion list replaces the history until the search is completed or canceled.

When the user selects a suggestion, populate the currently active text field with the selected location, 
dismiss the keyboard, hide the suggestions, and restore the recent history list. The MapBox camera should 
animate to the selected location, and the appropriate marker should be updated. If the active field was 
Current Location, update the start marker. If the active field was Destination, update the destination marker.

When no text field is focused or no search is in progress, the bottom sheet should display the user's 
recent searched locations exactly as shown in docs/ui/2.png. Each history item should contain a 
location icon, the place title, an optional subtitle, and an estimated travel time aligned to the 
right if available. Tapping a history item should populate whichever text field is currently active.

The interaction should follow this flow:

The user taps the search bar on the Home page.
The Trip Map Page opens.
The Current Location field is automatically populated with the user's current location.
The Destination field is empty.
The user taps the Destination field.
The keyboard opens and the Destination field becomes active.
As the user types, the recent history list is replaced with live search suggestions from the Places 
API.
The user selects one of the suggestions.
The Destination field is filled with the selected location.
The destination marker is placed on the map and the camera moves to it.
The search suggestions disappear and the recent history list is shown again.
The same behavior should work identically when editing the Current Location field.

Implement proper loading, empty, and error states for search requests. Reuse the existing networking 
architecture, repositories, API client, models, and state management already used in the project. 
Keep the implementation modular, maintainable, and consistent with the existing codebase. Match the 
UI, animations, spacing, typography, icons, and overall behavior shown in docs/ui/2.png and 
docs/ui/3.png exactly.

write clean code

WARNING: We will continue after searching drawing route and other features NOTE

----------------------------------------------------------------------------------------------------

3. Task

After selecting current and finish points, 