# ``Server/Server/Config-swift.struct/RedirectHandler/standard``

Standard redirect handling.

## Overview

This option instructs session delegate to call

```swift
completion(request)
```

with unmodified new request from its [urlSession(_:task:willPerformHTTPRedirection:newRequest:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/urlsession(_:task:willperformhttpredirection:newrequest:completionhandler:)) method.
