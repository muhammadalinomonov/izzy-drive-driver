# 1. Task
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

# 2. Task

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

# 3. Task

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

# 5. Task

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

# 6. Task

## Task: Integrate New Profile APIs and Redesign the Profile Screen

Implement the following new profile-related APIs while keeping the existing API implementation intact for now. The old APIs should continue working since they will be removed in a future update.

### APIs to Implement

* `GET /api/v1/mobile/profile`
* `PATCH /api/v1/mobile/profile`
* `GET /api/v1/mobile/vehicles`

Refer to `docs/mobile-api.md` for the complete request and response specifications.

### Profile Screen

Update the existing Profile screen to use the new APIs while preserving compatibility with the current implementation.

* Load the user's profile using `GET /api/v1/mobile/profile`.
* Allow editing and updating the profile using `PATCH /api/v1/mobile/profile`.
* Load the user's vehicles using `GET /api/v1/mobile/vehicles` and display them in the existing Vehicles section.

### Premium User Support

The profile response contains a boolean field:

`is_paid_user`

This field is very important.

When `is_paid_user == true`:

* Store this value globally (using the project's existing global state management).
* Make it accessible throughout the application.
* The application should recognize the user as a **Premium** user.
* This global premium state will be used later to enable premium-only features, so design the implementation to be reusable and maintainable.

When `is_paid_user == false`, the user should be treated as a regular user.

### Profile UI Redesign

Redesign the existing Profile screen with a more modern and polished appearance while keeping all existing functionality.

The redesign should include:

* A cleaner profile header with avatar, name, and contact information.
* A visually appealing Premium badge or indicator when `is_paid_user` is `true`.
* Better spacing, typography, and card layouts.
* Improved Vehicles section.
* Modern list items and action buttons.
* Smooth animations where appropriate.
* Consistent styling with the rest of the application.

Do not remove any existing functionality unless it is being replaced by the new APIs.

Implement proper loading, empty, pull-to-refresh, and error states for all profile and vehicle requests.

Reuse the existing networking layer, repositories, models, and state management wherever possible. Keep the implementation modular, maintainable, and consistent with the existing project architecture. All request and response models should follow the specifications in `docs/mobile-api.md`.


----------------------------------------------------------------------------------------------------

# 7. Task

## Task: Add Premium Support Message Feature

Add a **Support Message** button to `trip_map_page.dart` matching the design shown in `docs/ui/10.png`.

This feature should only be available for **Premium** users. Use the globally stored `is_paid_user` value from the profile API to determine whether the button should be visible.

### Visibility

* If `is_paid_user == true`, display the Support Message button.
* If `is_paid_user == false`, do not display the button.

### Navigation

When the user taps the Support Message button, navigate to a new page:

`support_message_page.dart`

### Support Message Page

Implement the UI exactly as shown in `docs/ui/11.png`.

The page should match the provided design as closely as possible, At this stage, **implement only the UI**. Do **not** implement any business logic, networking, API integration, or message sending functionality yet.

Use placeholder callbacks for all actions so the page is ready for backend integration later.

Keep the implementation modular, reusable, and consistent with the existing project architecture and design system.

----------------------------------------------------------------------------------------------------

# 8. Task

## Task: Implement Nearby Fuel Stations UI (API Placeholder)

Implement the new **Nearby Fuel Stations** feature on `trip_map_page.dart`. The backend API is not yet available, so implement the complete UI, state management, navigation flow, and business logic with placeholder data and a clear repository/API placeholder for future integration.

Before implementation, review the entire Trip module (Trip Map, Route Overview, Driving Mode, and related components) and refactor where necessary to keep the structure clean, modular, and maintainable.

### UI Updates

Update the modal bottom sheet to match the new design shown in `docs/ui/3-1.png`.

Replace the existing layout with the new design while preserving the existing location search functionality.

Add a new **Gas Station** button using the icon:

`docs/icons/ic_gas_station.svg`

The button should be integrated into the new bottom sheet layout exactly as shown in the design.

### Gas Station Mode

When the user taps the **Gas Station** button:

* Enter "Nearby Fuel Stations" mode.
* Request nearby fuel stations through a repository method (placeholder implementation for now).
* Display nearby fuel stations within approximately a **20-mile radius** of the user's current location.
* Since the backend is not ready, use mock/placeholder data that can easily be replaced with the future API.
* Keep the repository interface and models ready for the future API implementation.

### Map Behavior

When Gas Station mode is enabled:

* Display gas station markers on the MapBox map.
* Use the existing gas station marker design.
* Allow the user to tap any gas station marker.

When a gas station is selected:

* Automatically set **Current Location** as the origin.
* Automatically set the selected gas station as the destination.
* Populate both location fields in the bottom sheet.
* Move the MapBox camera to show both locations.
* Highlight the selected gas station marker.
* Enable the **Continue** button immediately.

The user should not need to manually search for a destination after selecting a gas station.

### Continue Flow

After selecting a gas station and pressing **Continue**, the flow should behave exactly like the normal route planning flow:

* Calculate the route.
* Navigate to the existing Route Overview page.
* Continue into Driving Mode if the user presses Start.

No duplicate route logic should be created.

### Architecture

Although the API is not available yet, prepare the project for future integration by implementing:

* Repository interface
* Data source placeholder
* Models
* State management
* Events/actions
* Loading states
* Empty states
* Error states

The repository should expose a method similar to:

`getNearbyFuelStations(currentLocation, radius)`

For now, return mock data from the placeholder implementation.

When the backend becomes available, only the repository implementation should need to change without affecting the UI or business logic.

### Code Quality

Review and improve the overall Trip module structure where appropriate:

* Remove duplicated logic.
* Extract reusable widgets.
* Keep Trip Map, Route Overview, Driving Mode, and related components consistent.
* Ensure all navigation flows share common business logic.
* Follow the existing project architecture and coding standards.

The implementation should be production-ready, with the only missing piece being the actual backend API integration.

----------------------------------------------------------------------------------------------------

# 9. Task

## Task: Implement Marker Information Bottom Sheet

Implement a reusable **Marker Information Bottom Sheet** for all map screens in the Trips module. Whenever the user taps a **fuel station** or **toll station** marker on the map, display a modal bottom sheet showing detailed information about the selected marker.

The bottom sheet UI should match the design shown in `docs/ui/5-1.png`.

### Supported Screens

This bottom sheet should be reused across all map-based screens in the Trips module, including:

* `trip_map_page.dart`
* Route Overview page
* Driving Mode page
* Any other Trips-related page displaying fuel or toll markers

Do not duplicate the implementation. Create a reusable widget/component that can be shared across all map screens.

### Marker Selection

When the user taps a marker:

* Highlight the selected marker.
* Open the information bottom sheet.
* Populate it with the selected marker's data.
* Close the sheet when the user taps outside it or dismisses it.

### Bottom Sheet UI

The bottom sheet should display all available information for the selected fuel station or toll station, matching the design in `docs/ui/5-1.png`.

Use the following icons from the `icons` folder:

* `icons/ic_location.svg` — Location/address
* `icons/ic_mile.svg` — Distance from the user's current location
* `icons/ic_price.svg` — Fuel price, toll fee, or other pricing information

Display any additional information available for the selected marker, such as:

* Name
* Address
* Distance
* Fuel price or toll cost
* Additional details returned by the model

### "To Go There" Button

The bottom sheet behavior differs depending on the screen:

#### On `trip_map_page.dart`

Display a **"To Go There"** button at the bottom of the sheet.

When pressed:

* Automatically set the user's current location as the origin.
* Set the selected marker's location as the destination.
* Populate the location fields.
* Enable the **Continue** button.
* Close the bottom sheet.

This should work for both fuel station and toll station markers.

#### On All Other Map Screens

Display the same information bottom sheet **without** the **"To Go There"** button.

These screens are informational only and should not allow changing the current route.

### Architecture

Create the bottom sheet as a reusable component with configurable behavior, for example:

* `showActionButton: true` for `trip_map_page.dart`
* `showActionButton: false` for Route Overview and Driving Mode

Avoid creating separate implementations for each page.

### Implementation Notes

* Reuse the existing marker models.
* Animate the bottom sheet presentation smoothly.
* Ensure proper spacing, typography, icons, and styling matching `docs/ui/5-1.png`.
* Keep the implementation modular, reusable, and consistent with the existing project architecture.
* Design the component so it can easily support additional marker types in the future if needed.

----------------------------------------------------------------------------------------------------

# 10. Task

## Task: Implement Premium Route Support Features

Implement additional premium-only functionality on the **Route Overview** and **Driving Mode** screens. Use the globally stored `is_paid_user` value to determine whether these features should be available.

### Route Overview (`route_overview_page.dart`)

When `is_paid_user == true`, update the bottom action area to match the design shown in `docs/ui/8-1.png`.

Instead of displaying only the **Start** button, show two buttons:

* **Drive Yourself**
* **Send Request**

#### Drive Yourself

The **Drive Yourself** button should behave exactly like the current **Start** button. It should start the existing Driving Mode without any changes to the current navigation flow.

#### Send Request

When the user taps **Send Request**, navigate to a new page:

`route_support_page.dart`

Implement the UI exactly as shown in:

* `docs/ui/8-2.png`

This page is UI-only for now. Do **not** implement any API integration yet. Instead, create repository and API placeholders that can easily be connected later.

### Route Support Page

When opening the page, pass all information required for creating a support request, including:

* Selected `routeId`
* Origin
* Destination
* Route distance
* Estimated travel time
* Toll information
* Selected route details
* Any other route information needed by the UI

The page should display the route information exactly as shown in `docs/ui/8-2-1.png`.

Implement a chat-style interface where:

* User messages appear exactly like the design in `docs/ui/8-2-1.png`.
* Support replies appear exactly like the design in `docs/ui/8-2-2.png`.

At this stage:

* Use mock conversation data.
* Create placeholder models and repository methods for future API integration.
* Keep the chat UI fully functional using local mock data.

### Premium Support Button

Just like `trip_map_page.dart`, add the floating **Support Message** button for Premium users to the following pages:

* `route_overview_page.dart`
* `driving_mode_page.dart`

The button should only be visible when:

`is_paid_user == true`

When tapped, navigate to the existing:

`support_message_page.dart`

Do not implement any new business logic for this page yet. The backend APIs will be added later.

### Architecture

Prepare the Route Support feature for future backend integration by creating:

* Repository interface
* Data source placeholders
* Models
* State management
* Mock data provider

No real network requests should be implemented yet.

### Code Quality

* Reuse existing components wherever possible.
* Avoid duplicating button or floating action button implementations.
* Create reusable widgets for premium-only actions.
* Keep the implementation modular, maintainable, and consistent with the existing project architecture.
* Match the layouts, spacing, typography, colors, animations, and overall behavior shown in `docs/ui/8-1.png`, `docs/ui/8-2.png`, `docs/ui/8-2-1.png`, and `docs/ui/8-2-2.png` as closely as possible.

----------------------------------------------------------------------------------------------------

# Task 11: Implement Nearby Fuel Stations and Premium Fuel Information

Implement the Nearby Fuel Stations feature in the **Trips** module, specifically on `trip_map_page.dart`.

Refer to the API documentation in `docs/mobile-api.md` for the endpoint and request/response models.

## Fuel Button

On the modal bottom sheet in `trip_map_page.dart`, there is a **Fuel** button.

When the user taps this button:

* Load nearby fuel stations using the API described in `docs/mobile-api.md`.
* Display all nearby fuel stations on the MapBox map.
* Use the marker asset `fuel_station_marker.svg`.
* Move `docs/icons/fuel_station_marker.svg` into the project's `assets` folder and update all references accordingly.
* Review all existing map markers and icons, ensuring they are stored in the correct assets directory and remove obsolete copies from the `docs/icons` folder.

## Fuel Station Markers

Each nearby fuel station should appear as a clickable marker on the map.

When the user taps a fuel station marker:

* Highlight the selected marker.
* Open the Fuel Information Bottom Sheet.
* Populate it with the selected fuel station's information.

Reuse the existing marker selection logic wherever possible.

## Fuel Information Bottom Sheet

The bottom sheet should be reusable and behave similarly to the existing Toll Information bottom sheet used on `route_overview_page.dart`.

The UI depends on the user's subscription status.

### Premium Users

If `is_paid_user == true`, display the premium version of the bottom sheet exactly as shown in:

`docs/ui/5-2.svg`

### Regular Users

If `is_paid_user == false`, display the standard version exactly as shown in:

`docs/ui/5-1.svg`

The implementation should automatically switch between these two layouts based on the globally stored premium state.

## Route Planning

When the user presses the action button in the Fuel Information Bottom Sheet:

* Use the user's current location as the route origin.
* Use the selected fuel station as the destination.
* Generate the route using the existing route calculation flow.
* Navigate to the existing `route_overview_page.dart`.

Do not create a separate route calculation flow.

## Route Overview

The existing `route_overview_page.dart` should display the generated route exactly as it does for all other routes.

No duplicate implementation should be introduced.

## Driving Mode

On `route_overview_page.dart`, identify the primary navigation button (`Drive Yourself` or `Start`, depending on the user's subscription).

When the user presses this button:

* Navigate to the existing `driving_mode_page.dart`.
* Start navigation using the currently selected route.

Do not modify the existing Driving Mode flow beyond ensuring this navigation works correctly.

## Architecture

* Reuse the existing Trip module architecture.
* Share business logic between normal route planning and fuel station routing.
* Reuse repositories, models, state management, and map components.
* Avoid duplicated code.
* Create reusable components where appropriate.

## UI

Match the provided designs exactly:

* `docs/ui/5-1.svg`
* `docs/ui/5-2.svg`

Maintain consistent spacing, typography, animations, icons, colors, and interaction behavior with the rest of the application.

----------------------------------------------------------------------------------------------------

# Task 12: Implement Support Message APIs and Message Actions

Implement the complete support messaging functionality using the APIs described in `docs/mobile-api.md`.

There are two different support message flows in the application:

1. **Normal Support Messages**
2. **Route Review / Route Support Messages**

## 1. Normal Support Messages

Normal support messages can be opened from:

* `trip_map_page.dart`
* `route_overview_page.dart`
* `driving_mode_page.dart`

These pages use the existing `support_message_page.dart`.

Connect the existing Support Message UI to the support message APIs defined in `docs/mobile-api.md`.

Implement:

* Loading existing conversation/messages.
* Sending a new message.
* Displaying the user's sent messages.
* Displaying support responses.
* Loading states.
* Sending states.
* Empty conversation state.
* Error handling.
* Refresh/reload behavior where appropriate.

The conversation should be persisted through the API so that reopening `support_message_page.dart` loads the existing conversation instead of creating a new local conversation.

Only Premium users should have access to the normal support messaging functionality, using the globally stored `is_paid_user` value.

## 2. Route Review Messages

Route review messages are a separate support conversation created from:

`route_review_page.dart`

When the user presses the **Send Request** button, create/send a route support request using the corresponding APIs defined in `docs/mobile-api.md`.

The request should include the route information associated with the review, including the data already passed to the Route Review page, such as:

* Route ID
* Origin
* Destination
* Selected route
* Distance
* Duration
* Toll information
* Other route details required by the API

Follow the exact request/response structure defined in `docs/mobile-api.md`.

After successfully sending the request, display the conversation/message state using the existing Route Review support UI.

## Message Types

Keep the two message flows logically separated:

### Normal Support Conversation

Used from:

* `trip_map_page.dart`
* `route_overview_page.dart`
* `driving_mode_page.dart`

This is a general support conversation and should use the existing `support_message_page.dart`.

### Route Review Conversation

Used from:

* `route_review_page.dart`

This conversation is associated with a specific route and should use the route-specific support/review UI.

Do not mix normal support messages with route review messages.

## API Integration

Use only the endpoints and request/response structures documented in:

`docs/mobile-api.md`

Before implementing the API layer, review the documentation and identify all endpoints related to:

* Creating/sending support messages
* Loading support conversations
* Loading messages
* Sending replies
* Route review/support requests
* Any message status or conversation actions

Create the required:

* API methods
* DTO/models
* Repository methods
* Data sources
* State management
* Error handling

Reuse the existing networking architecture of the project instead of creating a separate HTTP implementation.

## Message UI

Keep the existing UI designs already implemented for:

* `support_message_page.dart`
* `route_review_page.dart`

Do not redesign these pages.

Connect the existing UI to the real APIs and replace mock/placeholder message data with API data.

Messages should clearly distinguish between:

* User messages
* Support messages

Preserve the visual behavior shown in the existing designs.

## Sending Messages

When the user sends a message:

1. Validate the message.
2. Show the sending/loading state.
3. Call the appropriate API.
4. Add/display the returned message from the server.
5. Clear the input field after successful submission.
6. Scroll the conversation to the newest message.
7. Handle API errors without losing the user's typed message.

Prevent duplicate submissions while a message is being sent.

## Route Review "Send Request"

When **Send Request** is pressed on `route_review_page.dart`:

1. Validate the required route information.
2. Create the route support/review request using the documented API.
3. Show a loading state while the request is being submitted.
4. Handle success and error responses.
5. Display the resulting message/request in the route review conversation.
6. Preserve the associated route information throughout the conversation.

## Architecture

Keep the implementation modular and avoid duplicating support-message logic.

Create shared components/services where appropriate, but keep **Normal Support** and **Route Review Support** as separate business flows.

Reuse:

* Existing API client
* Repository architecture
* Models
* State management
* Authentication
* Existing support-message widgets
* Existing route models

Do not modify unrelated Trip, Route Overview, or Driving Mode functionality.

All API behavior must follow the specifications in `docs/mobile-api.md`.
