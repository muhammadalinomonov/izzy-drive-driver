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

After the user has selected both the **Current Location** and **Destination**, enable the **Continue** button at the bottom of the screen. The button should remain disabled until both locations have been selected.

When the user presses **Continue**, send a request to calculate the route using:

`POST /api/v1/mobile/toll-routes`

Use the selected current location as the route origin and the destination as the route destination. Follow the request and response format described in `docs/mobile-api.md`.

Before entering navigation, manage the navigation session using the following APIs:

* `POST /api/v1/mobile/navigation-sessions` — Create or update the current navigation session using the selected route and navigation information.
* `GET /api/v1/mobile/navigation-sessions/current` — Retrieve the active navigation session whenever the navigation screen is opened or the app resumes, allowing the user to continue an existing navigation session.
* `POST /api/v1/mobile/navigation-sessions/{navigationSession}/cancel` — Cancel the active navigation session when the user exits navigation, cancels the trip, or finishes the route.

All request and response models for these endpoints are described in `docs/mobile-api.md`. Reuse the existing networking architecture, repositories, API client, models, and state management already used throughout the project.

While the route is being calculated, display a loading state over the map or inside the bottom sheet. Once the API responds, transition to the route overview screen matching the design shown in `docs/ui/8.png`.

Display all routes returned by the API, including the primary recommended route and any alternative routes. The selected route should be visually emphasized, while alternative routes should be displayed using a secondary style so users can easily distinguish them. The user should be able to switch between available routes, and selecting a different route should immediately update the highlighted route, route summary, toll information, fuel stations, and all related map data.

Display all toll stations and fuel stations returned by the API as markers on the map using the following assets:

* `gas_station_marker.svg` for fuel stations.
* `toll_marker.svg` for toll stations.

Automatically adjust the MapBox camera so the entire selected route is visible, including the origin and destination.

Display a draggable bottom sheet matching the design in `docs/ui/8.png`. The bottom sheet should present a complete summary of the selected route, including distance, estimated travel time, toll costs, and any additional route information returned by the API.

Below the route summary, display the route services using the following icons from the `docs/ui` folder:

* `ic_fuel.svg` for fuel stations.
* `ic_toll.svg` for toll stations.
* `ic_location.svg` for locations or route waypoints.

At the bottom of the sheet, display a prominent **Start** button.

When the user taps **Start**, begin **Driving Mode**.

The Driving Mode UI should match the design shown in `docs/ui/9.png`.

Before entering Driving Mode, create or update the navigation session using `POST /api/v1/mobile/navigation-sessions`. If an active navigation session already exists, synchronize it appropriately according to the API documentation.

Driving Mode should provide a real-time navigation experience:

* Continuously track the user's GPS location.
* Center the MapBox camera on the user's current position.
* Rotate and follow the user's heading while driving.
* Keep the selected route highlighted throughout navigation.
* Display remaining distance and estimated arrival time.
* Continue displaying toll stations and fuel stations along the route.
* Smoothly animate location updates as the user moves.
* Recalculate the route if supported by the existing architecture or API.

Whenever the navigation screen is opened, resumed, or restored after the application returns from the background, call:

`GET /api/v1/mobile/navigation-sessions/current`

If an active navigation session exists, restore the navigation state, selected route, current progress, and continue Driving Mode without requiring the user to start over.

When the user taps **Cancel Navigation**, leaves Driving Mode, or completes the trip, call:

`POST /api/v1/mobile/navigation-sessions/{navigationSession}/cancel`

After successfully canceling the session, clear all navigation-related state and return the user to the route planning screen.

Implement proper loading, empty, offline, and error states for all API requests. Handle network failures gracefully and preserve navigation state whenever possible.

Follow all request and response specifications defined in `docs/mobile-api.md`. Keep the implementation modular, maintainable, and consistent with the existing project architecture. Match the layouts, spacing, typography, animations, icons, and overall behavior shown in `docs/ui/8.png` for the route overview and `docs/ui/9.png` for Driving Mode as closely as possible.

----------------------------------------------------------------------------------------------------

4. Task

On the **Trips** page, display the user's route history. When the user taps a history item, navigate to the existing **Route Overview** screen.

Load the selected route details by calling:

`GET /api/v1/mobile/toll-routes/{routeRequest}`

where `{routeRequest}` is the selected history item's ID. Follow the API specification in `docs/mobile-api.md`.

While loading, show a loading state. Once the data is received, populate the existing Route Overview screen with the returned route information, including the map, selected route, alternative routes, toll stations, fuel stations, and route summary. Do not create a new Route Overview screen—reuse the existing implementation and shared business logic used for newly calculated routes.

Handle loading, empty, and error states appropriately, and keep the implementation consistent with the existing architecture.

----------------------------------------------------------------------------------------------------

5. Task

## Task 5: Resume Active Navigation Session and Driving Mode Enhancements

Implement support for resuming an active navigation session from the **Trips** page.

If the user has an active navigation session, display a **Continue Route** button (or card) at the top of the Trips page. When the user taps it, retrieve the current navigation session by calling:

`GET /api/v1/mobile/navigation-sessions/current`

Follow the request and response specification in `docs/mobile-api.md`.

If an active session exists, navigate directly to the existing **Driving Mode** page and restore the complete navigation state, including the selected route, current progress, route information, and map state. Do not recalculate the route.

If no active navigation session exists, hide the Continue Route button.

### Driving Mode

Reuse the existing Driving Mode screen and extend it with the following behavior.

#### Location Updates

While navigation is active, continuously upload the driver's current location and navigation data to the server by calling:

`POST /api/v1/mobile/locations`

Upload the required location information at the interval defined by the project or API documentation. Handle temporary network failures gracefully and continue uploading when connectivity is restored.

#### Rerouting

If the driver leaves the current route or rerouting is otherwise required, call:

`POST /api/v1/mobile/navigation-sessions/{navigationSession}/reroute`

Update the displayed route and continue navigation using the rerouted path returned by the API.

#### Cancel Navigation

When the user taps **Cancel Navigation**, display the existing confirmation dialog.

After the user confirms:

* Show a loading indicator.
* Call the cancel endpoint.
* Wait for the request to complete successfully.
* Close the Driving Mode screen.
* Clear the active navigation state and return the user to the previous screen.

Use:

`POST /api/v1/mobile/navigation-sessions/{navigationSession}/cancel`

#### Complete Navigation

When the driver reaches the destination, automatically detect arrival (or according to the API requirements) and display a **Trip Completed** screen or dialog matching the application's design.

The completion flow should:

* Display a success message indicating that the trip has been completed.
* Show any available trip summary information returned by the API.
* Provide a **Done** button to close the completion screen.

When completing the trip, call:

`POST /api/v1/mobile/navigation-sessions/{navigationSession}/complete`

After a successful completion:

* Clear the active navigation session.
* Stop uploading location updates.
* Exit Driving Mode.
* Return the user to the Trips page.

Implement proper loading, success, empty, offline, and error states for all API requests. Follow all request and response models defined in `docs/mobile-api.md`. Reuse the existing networking layer, repositories, models, state management, and Driving Mode implementation. Keep the implementation modular, maintainable, and fully consistent with the existing project architecture.

----------------------------------------------------------------------------------------------------

6. Task




