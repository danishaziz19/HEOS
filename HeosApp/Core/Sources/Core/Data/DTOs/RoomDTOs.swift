import Foundation

// These match the ACTUAL response shape from the two provided endpoints
// exactly, including the inconsistent key naming (PascalCase on one
// endpoint, a key containing a literal space on the other). That's a
// real quirk of this API, not a typo on my part — see the CodingKeys
// below. Kept as two independent DTO trees mirroring the two
// independent endpoints; joining them into one cohesive `Room` only
// happens in `RoomMapper`, never here.

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
        // Yes, the actual key from the API is "Now Playing" with a
        // literal space in it.
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
