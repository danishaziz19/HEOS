import Foundation

// Matches the actual API shape, including the space in "Now Playing"
// and inconsistent key casing between the two endpoints. Joined into
// one Room only in RoomMapper, not here.

struct DevicesResponseDTO: Decodable {
    let devices: [DeviceDTO]

    enum CodingKeys: String, CodingKey {
        case devices = "Devices"
    }
}

struct DeviceDTO: Decodable, Sendable {
    let id: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case id = "ID"
        case name = "Name"
    }
}

struct NowPlayingResponseDTO: Decodable {
    let nowPlaying: [NowPlayingDTO]

    enum CodingKeys: String, CodingKey {
        case nowPlaying = "Now Playing"
    }
}

struct NowPlayingDTO: Decodable, Sendable {
    let deviceID: Int
    let artworkSmall: String?
    let artworkLarge: String?
    let trackName: String
    let artistName: String

    enum CodingKeys: String, CodingKey {
        case deviceID = "Device ID"
        case artworkSmall = "Artwork Small"
        case artworkLarge = "Artwork Large"
        case trackName = "Track Name"
        case artistName = "Artist Name"
    }
}
