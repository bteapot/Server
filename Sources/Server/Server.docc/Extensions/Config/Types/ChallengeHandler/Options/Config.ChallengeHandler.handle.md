# ``Server/Server/Config-swift.struct/ChallengeHandler/handle(_:)``

Custom authentication challenge response.

## Overview

Takes input parameters:

* Optional `URLSessionTask` that will have value for task level authentication challenges and will be `nil` for session level authentication challenges.
* [URLAuthenticationChallenge](https://developer.apple.com/documentation/foundation/urlauthenticationchallenge).

Returns:

`(URLSession.AuthChallengeDisposition, URLCredential?)` tuple, as described in [urlSession(_:didReceive:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession) or [urlSession(_:task:didReceive:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession).

For client certificates case it could be:

```swift
Config(
    ...
    challenge: .handle({ task, challenge in
        if let certificate = identity.certificate {
            return (.useCredential, certificate)
        } else {
            return (.performDefaultHandling, nil)
        }
    }),
    ...
)
```
