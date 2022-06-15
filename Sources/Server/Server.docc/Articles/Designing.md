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
    enum Identity {
        case unauthorized
        case authorized(Info)
    }
}

extension AppUser.Identity {
    struct Info: Codable {
        let username: String
        let token: String
    }
}
```

Application's authorization handling in that case may be incapsulated in the following container that essentially holds current user authorization state and provides means to change it:

```swift
import Foundation
import ReactiveSwift
import Server

final class AppUser {
    static let shared = AppUser()
    
    lazy var identity =
        Property<Identity>(
            initial: .unauthorized,
            then: self.pipe.output.observe(on: QueueScheduler.main)
        )
    
    lazy var authorize =
        Action<Credentials, Void, Error> { [input = self.pipe.input] credentials in
            Server.back
                .request(
                    type: .post,
                    path: "/authorize",
                    send: .json(credentials),
                    take: .json(AuthorizationResponse.self)
                )
                .map { response in
                    input.send(value: .authorized(
                        .init(
                            username: credentials.username,
                            token: response.token
                        )
                    ))
                }
        }
    
    lazy var deauthorize =
        Action<Void, Void, Error> { [input = self.pipe.input] in
            Server.back
                .request(
                    type: .post,
                    path: "/deauthorize",
                    send: .void(),
                    take: .void()
                )
                .map {
                    input.send(value: .unauthorized)
                }
        }
    
    private let pipe =
        Signal<Identity, Never>.pipe()
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
extension Server {
    static let backend =
        Server(AppUser.shared.identity.map({ identity in
            Config(
                base: URL(string: "https://backend.example.com")!,
                headers: {
                    switch identity {
                        case .unauthorized:
                            return [:]
                        case .authorized(let info):
                            return ["Authorization": "Bearer \(info.token)"]
                    }
                }()
            )
        }))
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
extension Server {
    static let back = Back()
}

final class Back: Server {
    fileprivate init() {
        super.init(
            AppUser.shared.identity
                .map { identity in
                    switch identity {
                        case .unauthorized:
                            return Config(
                                base:    URL(string: "https://backend.example.com")!,
                                decoder: Self.decoder()
                            )
                        case .authorized(let info): 
                            return Config(
                                base:    info.url,
                                headers: ["Authorization": "Bearer \(info.token)"],
                                decoder: Self.decoder()
                            )
                    }
                }
        )
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
extension Back {
    func circular<R: Decodable>(
        path:  String,
        query: [String: String] = [:],
        take:  R.Type,
        batch: Int = 1000
    ) -> SignalProducer<[R], Error> {
        SignalProducer { observer, lifetime in
            // pager
            let pager =
                MutableProperty<Int>(0)
            
            // scheduler
            let scheduler =
                QueueScheduler(
                    qos: .default,
                    name: "server.back.circular"
                )
            
            // loading cycle
            pager.producer
                .observe(on: scheduler)
                .flatMap(.concat) { index in
                    self.request(
                        type: .get,
                        path: path,
                        query: query.merging([
                            "offset": String(index * batch), 
                            "limit":  String(batch),
                        ], uniquingKeysWith: { $1 }),
                        take: .json(Response<R>.self)
                    )
                }
                .map { response in
                    scheduler.schedule {
                        // last page?
                        if response.offset + response.records.count >= response.total {
                            // last page
                            observer.sendCompleted()
                        } else {
                            // next cycle
                            pager.value += 1
                        }
                    }
                    
                    // send payload to subscribers
                    return response.records
                }
                .take(during: lifetime)
                .start(observer)
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

This method returns `SignalProducer` that issues multiple values before termination, each value is an array representing one page of requested items.

```swift
Server.back
    .circular(
        path: "/items",
        take: Item.self
    )

```

To receive all items one by one:

```swift
Server.back
    .circular(...)
    .flatten()
```

To receive only one value with array of all items of all pages (may be memory-dangerous):

```swift
Server.back
    .circular(...)
    .flatten()
    .collect()
```


### Limited API

``Server/Server`` subclassing can be a reasonable choice when the reflected API is extremely limited.

For example, image hosting service that vends only one method.

```swift
import Foundation
import UIKit
import ReactiveSwift
import Server

extension Server {
    static let pravatar = Pravatar()
}

final class Pravatar: Server {
    fileprivate init() {
        super.init(
            Property(
                value: Config(
                    base: URL(string: "https://i.pravatar.cc")!
                )
            )
        )
    }
    
    @available(*, unavailable)
    override func raw(with request: URLRequest) -> SignalProducer<(Data, URLResponse), Error> {
        fatalError()
    }
    
    @available(*, unavailable)
    override func request<R>(type: Server.Method, base: URL?, path: String, timeout: TimeInterval?, headers: [String : String], query: [String : String], send: Server.Send, take: Server.Take<R>, catch: Server.Config.Catcher?) -> SignalProducer<R, Error> {
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
    ) -> SignalProducer<(UIImage, String?), Error> {
        super.request(
            type: .get,
            path: "/\(String(format: "%d", size))",
            query: ["img": String(format: "%d", id)],
            take: .response(with: .data())
        )
        .attemptMap { response, data in
            if let image = UIImage(data: data) {
                return (image, (response as? HTTPURLResponse)?.suggestedFilename)
            } else {
                throw PravatarError.invalidData
            }
        }
        .observe(on: QueueScheduler.main)
    }
}
```

## Error handling

Error handling can be seamlessly paired with your application-wide notification system.

```swift
import Foundation
import ReactiveSwift

extension SignalProducer where Error: Swift.Error {
    public func reportError(
        title: String,
        text:  @escaping (Error) -> String = { $0.localizedDescription }
    ) -> SignalProducer<Value, Never> {
        return self.flatMapError { error in
            /* pass texts to your application-wide notification system
            Toast.show(
                error: title,
                text:  text(error)
            )
            */
            return .empty
        }
    }
}
```

With this simple extension making requests becomes as clean as:

```swift
Server.back
    .request(
        type: .get,
        path: "/items",
        take: .json([Item].self)
    )
    .reportError(title: "Can't get items")
    .startWithValues { items in
        // process items
    }
```
