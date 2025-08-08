# ``Server/Server``

@Metadata {
    @DocumentationExtension(mergeBehavior: override)
}

An object that represents specific backend service.

## Overview

`Server` class provides coordination between changes in application environment state such as user's identity and session- and request-level nuances of specific backend service.

## Creating a Server object

`Server`'s initialization takes single ``Config-swift.struct`` parameter. Value of this parameter will be used to configure a new `URLSession` and all further requests it processes. Current ``Config-swift.struct`` can be accessed via ``Server/Server/config-swift.property`` property and changed with ``Server/Server/set(_:)`` function. Changes to the current ``Config-swift.struct`` will cancel all ongoing requests and invalidate current `URLSession`.

For simple cases config can be immutable, resulting in a single `Server`'s lifecycle:

```swift
extension Server {
    static let imageHosting =
        Server(with: Config(
            base: URL(string: "https://imagehosting.example.org")!,
            headers: [
                "X-API-Key": "<your app's image hosting API key>"
            ]
        ))
}
```

More common usage scenarios takes into account application user's identity changes such as authorization state and discussed in <doc:Designing> article.

## Making requests

Call ``Server/Server/request(type:base:path:cache:timeout:headers:query:send:take:catcher:)`` to asynchronously:

1. Assemble an `URLRequest` from current configuration and specified method parameters.
2. Start that request with underlying `URLSession`.
3. Check received `HTTPURLResponse`.
4. Decode received data.

```swift
let item: Item =
    try await Server.back
        .request(
            type: .get,
            path: "/item",
            query: ["id": itemID],
            take: .json(Item.self)
        )
}
```

## Topics

### Initialization

- ``init(with:)``

### Configuration

- ``config-swift.property``
- ``Config-swift.struct``

### Requests

- ``Server/Server/request(type:base:path:cache:timeout:headers:query:send:take:catcher:)``
- ``Method``
- ``Send``
- ``Take``

### Raw requests

- ``raw(with:)``
