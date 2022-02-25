# ``Server/Server/Config/SessionConfiguration/custom(_:)``

Provides custom `URLSessionConfiguration`.

## Overview

Allows for full customization of `URLSessionConfiguration`:

```swift
Config(
    ...
    session: .custom({
        var config = URLSessionConfiguration.ephemeral
        config.allowsCellularAccess = false
        return config
    }),
    ...
)
```
