import XCTest

/// UI tests run against the actual app, launched with "--uitesting" so
/// DIContainer.live() forces Mock Data mode (see DIContainer.swift) —
/// deterministic, known content ("Office (Mock)" etc.), no dependency on
/// the live S3 endpoint being reachable during a test run. This mirrors
/// the same reasoning as a real HEOS test suite not wanting to depend on
/// live hardware/network being available and correct at test time.
///
/// I don't have a simulator available to actually run these, so treat
/// this suite as a strong first draft — the element-query strategy
/// (matching on visible text/accessibility identifiers rather than
/// container types like `.tables` vs `.collectionViews`) was chosen
/// specifically to be robust to exactly the kind of runtime detail I
/// can't verify without a simulator, but confirm these actually pass
/// before submitting.
final class HeosUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["--uitesting"]
        app.launch()
    }

    // MARK: - Rooms tab

    func test_roomsTab_showsMockRoomsListOnLaunch() throws {
        // Rooms is the first tab, selected by default on launch.
        XCTAssertTrue(app.staticTexts["Office (Mock)"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Garage (Mock)"].exists)
        XCTAssertTrue(app.staticTexts["Studio (Mock)"].exists)
    }

    // MARK: - Cross-tab selection sync

    func test_selectingRoom_updatesNowPlayingTab() throws {
        XCTAssertTrue(app.staticTexts["Garage (Mock)"].waitForExistence(timeout: 5))

        // Using .any matching rather than assuming a specific element
        // type (.cells vs .otherElements) — SwiftUI's List can surface
        // rows as either depending on iOS version/rendering, and I
        // can't confirm which without a simulator. If this doesn't
        // resolve the element, tapping the static text label directly
        // ("Garage (Mock)") is the fallback.
        let garageRow = app.descendants(matching: .any)["room_row_102"] // Garage (Mock) = device ID 102
        if garageRow.exists {
            garageRow.tap()
        } else {
            app.staticTexts["Garage (Mock)"].tap()
        }

        app.tabBars.buttons["Now Playing"].tap()

        XCTAssertTrue(app.staticTexts["nowPlayingRoomName"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["nowPlayingRoomName"].label, "Garage (Mock)")
        XCTAssertEqual(app.staticTexts["nowPlayingTrackTitle"].label, "Mock Track Two")
    }

    // MARK: - Play/Pause cross-tab sync (the requirement Mustafa's team specifically cares about)

    func test_togglingPlayPause_updatesRoomsListPlaybackIndicator() throws {
        // Default selection on first load is the first room (Office (Mock), ID 101).
        app.tabBars.buttons["Now Playing"].tap()
        XCTAssertTrue(app.buttons["playPauseButton"].waitForExistence(timeout: 5))

        // Rooms default to isPlaying = true on first fetch (see Room.swift
        // doc comment for why) — so the button should initially read "Pause".
        XCTAssertEqual(app.buttons["playPauseButton"].label, "Pause")

        app.buttons["playPauseButton"].tap()

        app.tabBars.buttons["Rooms"].tap()

        let officeIndicator = app.images["room_101_playbackIndicator"]
        XCTAssertTrue(officeIndicator.waitForExistence(timeout: 5))

        // The indicator element already exists before the toggle lands
        // (it just shows "Playing" initially), so waitForExistence alone
        // wouldn't catch the async label change — wait on the actual
        // label value instead, since togglePlayback() involves a hop
        // through the actor-isolated repository before the shared
        // ViewModel reflects the new state back to the view.
        let becamePaused = NSPredicate(format: "label == %@", "Paused")
        expectation(for: becamePaused, evaluatedWith: officeIndicator, handler: nil)
        waitForExpectations(timeout: 5)
    }

    // MARK: - Settings

    func test_settingsTab_mockDataToggleReflectsLaunchState() throws {
        app.tabBars.buttons["Settings"].tap()

        let toggle = app.switches["mockDataToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        // Launched with --uitesting, which forces mock mode — the toggle
        // should reflect that actual state, not just its hardcoded
        // default. This is specifically testing the sync fix described
        // in HeosViewModel.refresh().
        XCTAssertEqual(toggle.value as? String, "1", "Toggle should show ON since the app was launched in mock mode")
    }
}
