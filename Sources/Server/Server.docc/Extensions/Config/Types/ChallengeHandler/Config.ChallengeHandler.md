# ``Server/Server/Config-swift.struct/ChallengeHandler``

`URLSession`'s authentication challenge handling type.

## Overview

Used in two `URLSession` delegate methods:

* Session level authentication challenges. `URLSessionDelegate`'s [urlSession(_:didReceive:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiondelegate/1409308-urlsession).
* Task level authentication challenges. `URLSessionTaskDelegate`'s [urlSession(_:task:didReceive:completionHandler:)](https://developer.apple.com/documentation/foundation/urlsessiontaskdelegate/1411595-urlsession).

## Topics

### Standard

- ``standard``

### Custom

- ``handle(_:)``
