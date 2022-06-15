# ``Server/Server/Config-swift.struct/ResponseHandler/handle(_:)``

Custom response check.

## Overview

Takes current ``Server/Server/Config-swift.struct``, `URLRequest`, it's `URLResponse` and response `Data`. Returns nothing if everything is in order or throws an error if something is wrong.

For example:

```swift
struct ServerInfo: Decodable {
    let message: String
}

Config(
    ...
    response: .handle({ config, request, response, data in
        guard
            let response = response as? HTTPURLResponse,
            (200..<300).contains(response.statusCode)
        else {
            throw ServerError.badResponse(request, response, "Invalid response code.", data)
        }
    }),
    ...
)
```
