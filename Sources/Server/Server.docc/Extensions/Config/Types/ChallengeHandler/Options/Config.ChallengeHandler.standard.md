# ``Server/Server/Config/ChallengeHandler/standard``

Standard authentication challenge response.

## Overview

This option instructs session delegate to call

```swift
completion(.performDefaultHandling, nil)
```

from its [urlSession(_:didReceive:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession) and [urlSession(_:task:didReceive:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession) methods.
