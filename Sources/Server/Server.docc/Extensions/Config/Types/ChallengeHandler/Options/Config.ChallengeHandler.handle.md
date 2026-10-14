# ``Server/Server/Config-swift.struct/ChallengeHandler/handle(_:)``

Custom authentication challenge response.

## Overview

Takes input parameters:

* Optional `URLSessionTask` that will have value for task level authentication challenges and will be `nil` for session level authentication challenges.
* [URLAuthenticationChallenge](https://developer.apple.com/documentation/foundation/urlauthenticationchallenge).
* Completion callback with parameters ([URLSession.AuthChallengeDisposition](https://developer.apple.com/documentation/foundation/urlsession/authchallengedisposition), [URLCredential?](https://developer.apple.com/documentation/foundation/urlcredential))

For client certificates case it could be:

```swift
Config(
    ...
    challenge: .handle({ task, challenge, completion in
        if let certificate = identity.certificate {
            completion(.useCredential, certificate)
        } else {
            completion(.performDefaultHandling, nil)
        }
    }),
    ...
)
```
