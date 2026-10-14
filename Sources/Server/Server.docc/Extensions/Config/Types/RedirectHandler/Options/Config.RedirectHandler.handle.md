# ``Server/Server/Config-swift.struct/RedirectHandler/handle(_:)``

Custom redirect handling.

## Overview

Takes input parameters:

* `URLSessionTask` that received server redirect.
* `HTTPURLResponse` server response.
* Proposed `URLRequest`.
* Completion callback `(URLRequest?) -> Void`.


For the redirects to the same host it could be:

```swift
Config(
    ...
    redirect: .handle({ task, response, request, completion in
        if task.originalRequest?.url?.host() == request.url?.host() {
            var request = request
            let authorization = task.originalRequest?.value(forHTTPHeaderField: "Authorization")
            request.setValue(authorization, forHTTPHeaderField: "Authorization")
            completion(request)
        } else {
            completion(request)
        }
    }),
    ...
)
```
