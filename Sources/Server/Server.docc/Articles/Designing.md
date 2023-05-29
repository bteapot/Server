# Designing a backend representation

Some common situations that modern application's network layer can solve.

## Depending on user's identity

Consider a very common scenario in which application user needs to perform an authorization with backend service. The process of authorization (without error handling) would involve:

1. Application provides a username/password input form.
2. User provides their credentials and taps "Login" button.
3. Application presents those credentials to backend service by calling proper REST method.
4. Backend service responds with access token.
5. Application uses this token in all subsequent requests.

The user's authorization state can be expressed by two enumeration cases:

```swift
extension AppUser {
    enum Identity: Equatable {
        case unauthorized
        case authorized(Info)
    }
}

extension AppUser.Identity {
    struct Info: Codable, Equatable {
        let username: String
        let token: String
    }
}
```

Application's authorization handling in that case may be incapsulated in the following container that essentially holds current user authorization state and provides means to change it:

```swift
import SwiftUI
import Server

final class AppUser: ObservableObject {
    
    static let shared = AppUser()
    
    @MainActor
    @Published
    var identity: Identity = .unauthorized
    
    @MainActor
    func set(identity: Identity) {
        self.identity = identity
    }
    
    func authorize(with credentials: Credentials) async throws {
        let response =
            try await Server.back
                .request(
                    type: .post,
                    path: "/authorize",
                    send: .json(credentials),
                    take: .json(AuthorizationResponse.self)
                )
        
        await self.set(identity: .authorized(
            .init(
                username: credentials.username,
                token: response.token
            )
        ))
    }
    
    func deauthorize() async throws {
        try await Server.back
            .request(
                type: .post,
                path: "/deauthorize",
                send: .void(),
                take: .void()
            )
        
        await self.set(identity: .unauthorized)
    }
}

extension AppUser {
    struct Credentials: Encodable {
        let username: String
        let password: String
    }
}

private extension AppUser {
    struct AuthorizationResponse: Decodable {
        let token: String
    }
}
```

Backend representation would react to changes in `AppUser`'s `identity` property, making a new iteration in it's lifecycle:

1. Cancel ongoing requests belonging to previous user identity.
2. Invalidate it's underlying `URLSession`.
2. Construct a new ``Server/Server/Config-swift.struct`` containing appropriate parameters for conducting a future requests.

```swift
import Foundation
import Combine
import Server


extension Server {
    static let back = Back()
}

final class Back: Server {
    fileprivate init() {
        super.init(with: Self.config(for: nil))
        
        AppUser.shared.$identity
            .removeDuplicates()
            .sink { identity in
                Task {
                    await self.set(Self.config(for: identity))
                }
            }
            .store(in: &self.bag)
    }
    
    @available(*, unavailable)
    override init(with config: Server.Config) { fatalError() }
    
    private var bag: Set<AnyCancellable> = []
}

private extension Back {
    private static func config(
        for identity: AppUser.Identity?
    ) -> Server.Config {
        Config(
            base: URL(string: "https://backend.example.com")!,
            headers: {
                switch identity {
                    case .authorized(let info):
                        return ["Authorization": "Bearer \(info.token)"]
                    default:
                        return [:]
                }
            }()
        )
    }
}
```

## Subclassing

``Server/Server`` class meant to be subclassed in case of backend service that needs complex configuration or have a very specific or very limited API.

### Complex configuration

For complex configuration, when, for example, backend provides localized API at specific URL for authorized users and uses custom date formatting in JSON responses, it may be:

```swift
extension AppUser.Identity {
    struct Info: Codable {
        let username: String
        let token: String
        let url: URL
    }
}
```

```swift
private extension Back {
    private static func config(
        for identity: AppUser.Identity?
    ) -> Server.Config {
        switch identity {
            case .authorized(let info):
                return Config(
                    base:    info.url,
                    headers: ["Authorization": "Bearer \(info.token)"],
                    decoder: Self.decoder()
                )
            default:
                return Config(
                    base:    URL(string: "https://backend.example.com")!,
                    decoder: Self.decoder()
                )
        }
    }
}

private extension Back {
    static func decoder() -> Server.Config.Configure<JSONDecoder>? {
        return { decoder in
            decoder.dateDecodingStrategy = .formatted(self.dateFormatter)
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
}
```

### Specific API

Some backend APIs may provide methods that specific only for that particular service, like, for example, pagination. In that case ``Server/Server`` subclass can be used to incapsulate that functionality.

```swift
import Foundation
import Server

extension Back {
    func circular<R: Decodable>(
        path:  String,
        query: [String: String] = [:],
        take:  R.Type,
        batch: Int = 1000
    ) async throws -> [R] {
        // page index
        var index: Int = 0
        
        // collected elements
        var elements: [R] = []
        
        // loading cycle
        while true {
            let response =
                try await self.request(
                    type: .get,
                    path: path,
                    query: query.merging([
                        "offset": String(format: "%d", index * batch),
                        "limit":  String(format: "%d", batch),
                    ], uniquingKeysWith: { $1 }),
                    take: .json(Response<R>.self)
                )
            
            // add to previously collected
            elements += response.records
            
            // last page?
            if elements.count >= response.total {
                // last page
                return elements
            } else {
                // next cycle
                index += 1
            }
        }
    }
}

private extension Back {
    struct Response<R: Decodable>: Decodable {
        let offset:  Int
        let total:   Int
        let records: [R]
    }
}
```

This method returns an array with all items from all pages.

```swift
let items = 
    try await Server.back
        .circular(
            path: "/items",
            take: Item.self
        )
```

### Limited API

``Server/Server`` subclassing can be a reasonable choice when the reflected API is extremely limited.

For example, image hosting service that vends only one method.

```swift
import SwiftUI
import Server

extension Server {
    static let pravatar = Pravatar()
}

final class Pravatar: Server {
    fileprivate init() {
        super.init(with: Config(
            base: URL(string: "https://i.pravatar.cc")!)
        )
    }
    
    @available(*, unavailable)
    override func raw(
        with request: URLRequest
    ) async throws -> (Data, URLResponse) {
        fatalError()
    }
    
    @available(*, unavailable)
    override func request<R>(
        type: Server.Method, 
        base: URL?, 
        path: String, 
        timeout: TimeInterval?, 
        headers: [String: String], 
        query: [String: String], 
        send: Server.Send, 
        take: Server.Take<R>, 
        catch: Server.Catcher<R>?
    ) async throws -> R {
        fatalError()
    }
}

enum PravatarError: Error {
    case invalidData
}

extension Pravatar {
    func load(
        id:   Int,
        size: Int
    ) async throws -> (Image, String?) {
        let (response, data) =
            try await super.request(
                type: .get,
                path: "/\(String(format: "%d", size))",
                query: ["img": String(format: "%d", id)],
                take: .response(with: .data())
            )
        
        if let image = self.image(from: data) {
            return (
                image, 
                (response as? HTTPURLResponse)?.suggestedFilename
            )
        } else {
            throw PravatarError.invalidData
        }
    }
}

#if os(iOS)
import UIKit

private extension Pravatar {
    func image(from data: Data) -> Image? {
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        } else {
            return nil
        }
    }
}
#endif
    
#if os(macOS)
import AppKit

private extension Pravatar {
    func image(from data: Data) -> Image? {
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        } else {
            return nil
        }
    }
}
#endif
```
