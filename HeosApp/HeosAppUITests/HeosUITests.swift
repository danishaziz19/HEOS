import XCTest

/// Launched with "--uitesting" so DIContainer.make() forces Mock Data
/// mode — deterministic, known content, no dependency on the live endpoint.
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

        // .any since List rows can surface as .cells or .otherElements; falls back to the label.
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

        // isPlaying defaults to true on first fetch, so button starts as "Pause".
        XCTAssertEqual(app.buttons["playPauseButton"].label, "Pause")

        app.buttons["playPauseButton"].tap()

        app.tabBars.buttons["Rooms"].tap()

        let officeIndicator = app.images["room_101_playbackIndicator"]
        XCTAssertTrue(officeIndicator.waitForExistence(timeout: 5))

        // Wait on the label value, not just existence — the toggle is async.
        let becamePaused = NSPredicate(format: "label == %@", "Paused")
        expectation(for: becamePaused, evaluatedWith: officeIndicator, handler: nil)
        waitForExpectations(timeout: 5)
    }

    // MARK: - Settings

    func test_settingsTab_mockDataToggleReflectsLaunchState() throws {
        app.tabBars.buttons["Settings"].tap()

        let toggle = app.switches["mockDataToggle"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        // Tests the sync fix in HeosViewModel.refresh() — toggle reflects actual mode, not just default.
        XCTAssertEqual(toggle.value as? String, "1", "Toggle should show ON since the app was launched in mock mode")
    }
}
