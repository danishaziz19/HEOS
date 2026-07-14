import Foundation

/// Joins the two API responses into one Room list.
enum RoomMapper {

    /// Matches devices to now-playing entries by ID. Devices with no
    /// match are dropped (compactMap, not map).
    static func toDomain(devices: [DeviceDTO], nowPlaying: [NowPlayingDTO]) -> [Room] {
        let nowPlayingByDeviceID = Dictionary(
            nowPlaying.map { ($0.deviceID, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return devices.compactMap { device in
            guard let playing = nowPlayingByDeviceID[device.id] else { return nil }

            return Room(
                id: device.id,
                name: device.name,
                trackTitle: playing.trackName,
                artistName: playing.artistName,
                albumTitle: nil, // not in the API response
                artworkSmallURL: playing.artworkSmall.flatMap(URL.init(string:)),
                artworkLargeURL: playing.artworkLarge.flatMap(URL.init(string:)),
                isPlaying: true // not in the API response; see RoomsRepositoryImpl
            )
        }
    }
}
