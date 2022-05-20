# ``Server/Server``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

An object that represents specific backend service.

## Overview

`Server` class provides coordination between changes in application environment state such as user's identity and session- and request-level nuances of specific backend service.

## Creating a Server object

`Server`'s initialization takes one parameter: reactive property with ``Config`` values. Each value of this property will be used to configure a new `URLSession` and all further requests it processes. Subsequent changes to the value of this property will cancel all ongoing requests and invalidate current `URLSession`. 

For simple cases this property can be immutable, resulting in a single `Server`'s lifecycle:

```swift
extension Server {
    static let imageHosting =
        Server(
            Property(value: Config(
                base: URL(string: "https://imagehosting.example.org")!,
                headers: [
                    "X-API-Key": "<your app's image hosting API key>"
                ]
            ))
        )
}
```

More common usage scenarios takes into account application user's identity changes such as authorization state and discussed in <doc:Designing> article.

## Making requests

Call ``Server/Server/request(type:base:path:timeout:headers:query:send:take:catcher:)`` to get a `SignalProducer` that will:

1. Assemble an `URLRequest` from current configuration and specified method parameters.
2. Start that request with underlying `URLSession`.
3. Check received `HTTPURLResponse`.
4. Decode received data.

```swift
Server.back
    .request(
        type: .get,
        path: "/item",
        query: ["id": itemID],
        take: .json(Item.self)
    )
    .startWithResult { result in
        switch result {
            case .success(let item):
                // process item
            case .failure(let error):
                // handle error
        }
    }
```

> Note: Most events of this producer will be vended on background `URLSession`'s queue. Use `.observe(on: QueueScheduler.main)` or `DispatchQueue.main.async` when accessing UI.

## Topics

### Initializing

- ``init(_:)``

### Requests

- ``Server/Server/request(type:base:path:timeout:headers:query:send:take:catcher:)``
- ``Method``
- ``Send``
- ``Take``

### Raw requests

- ``raw(with:)``

### Assets

- ``assets-swift.property``
- ``Assets-swift.typealias``
