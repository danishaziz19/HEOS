import Foundation
import Core

enum RoomsViewState: Equatable {
    case loading
    case loaded
    case failed(RoomsError)
}
