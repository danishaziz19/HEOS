HEOS App Developer Coding Challenge

Last updated by Jamie on 26 May 2023 at 9:44 pm

Using Swift and SwiftUI for iOS, or Kotlin and Compose for Android, and any other preferred libraries or frameworks, create an app that works as described below.  Return the App project to Sound United for review and testing.  There are no tablet specific requirements.  Dark mode support is not required.

Note that this coding project will be assessed on the quality of the code, the architecture, and the functional user experience.  The way the views and controls look is not important.

Please contact jamie.cooper@soundunited.com if you have any questions.

The app will have 3 tabs, Rooms, Now Playing and Settings.

Rooms
Show a list of HEOS devices (see Cloud Data below)
For each device show
Device name
Artwork
Track name
Artist name
Playback state (playing/paused)
When a device is selected in the Rooms view the Now Playing view will update to show what is playing on that device
Now Playing
For the selected player on the Rooms view show
Selected device name
Artwork
Track title
Album title
Artist name
Play / Pause button (Pause button when playing, Play button when paused))
When the Play / Pause button is tapped the Rooms view will update the playing state for the selected device
Settings
Show a switch control with the label “Mock Data” which is off by default
When the “Mock Data” setting is enabled the app should fetch local dummy data.
When the “Mock Data” setting is disabled the app should fetch its data from the cloud.




Cloud Data
Device and Now Playing data should be dynamically fetched by the app after launch from
https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/devices.json
https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/nowplaying.json
Assets
Assets should be downloaded from this link and integrated into the project.
https://skyegloup-eula.s3.amazonaws.com/heos_app/code_test/Assets.zip
Example Screens
These screens are provided only as a style and layout guide.  They are not specifications and do NOT need to be replicated in the app as they appear here.
  


