import XCTest
@testable import Core

final class NetworkClientTests: XCTestCase {

    override func tearDown() {
        StubURLProtocol.stub = nil
        super.tearDown()
    }

    private func makeSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSession(configuration: config)
    }

    func test_fetch_decodesSuccessfulResponse() async throws {
        StubURLProtocol.stub = .success(statusCode: 200, data: #"{"name":"Bedroom"}"#.data(using: .utf8)!)
        let sut = URLSessionNetworkClient(session: makeSession())

        let result: Fixture = try await sut.fetch(URL(string: "https://example.com/devices.json")!)

        XCTAssertEqual(result, Fixture(name: "Bedroom"))
    }

    func test_fetch_throwsNetworkErrorForNon2xxStatus() async {
        StubURLProtocol.stub = .success(statusCode: 500, data: Data())
        let sut = URLSessionNetworkClient(session: makeSession())

        do {
            let _: EmptyFixture = try await sut.fetch(URL(string: "https://example.com/devices.json")!)
            XCTFail("Expected a network error for a 500 response")
        } catch let error as RoomsError {
            guard case .network = error else {
                return XCTFail("Expected RoomsError.network, got \(error)")
            }
        } catch {
            XCTFail("Expected RoomsError, got \(error)")
        }
    }

    func test_fetch_throwsDecodingErrorForMalformedJSON() async {
        StubURLProtocol.stub = .success(statusCode: 200, data: "not json".data(using: .utf8)!)
        let sut = URLSessionNetworkClient(session: makeSession())

        do {
            let _: EmptyFixture = try await sut.fetch(URL(string: "https://example.com/devices.json")!)
            XCTFail("Expected a decoding error for malformed JSON")
        } catch {
            XCTAssertEqual(error as? RoomsError, .decoding)
        }
    }
}

private struct Fixture: Decodable, Equatable {
    let name: String
}

private struct EmptyFixture: Decodable {}

/// Minimal URLProtocol stub — intercepts requests and returns canned
/// responses so these tests never touch the real network.
private final class StubURLProtocol: URLProtocol {
    enum Stub {
        case success(statusCode: Int, data: Data)
    }

    // URLProtocol callbacks run synchronously on whatever thread URLSession
    // schedules them on; each test sets this before calling fetch and
    // tearDown() clears it after, so there's no real concurrent access —
    // nonisolated(unsafe) tells the compiler that instead of restructuring
    // this into an actor, which startLoading()'s non-async signature can't
    // easily accommodate anyway.
    nonisolated(unsafe) static var stub: Stub?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard case let .success(statusCode, data)? = Self.stub, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
