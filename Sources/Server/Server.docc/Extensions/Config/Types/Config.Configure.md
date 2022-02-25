# ``Server/Server/Config/Configure``

Generic closure typealias that allows configuration of instances of it's specialized type. 

## Overview

It has very simple usage. That's how, for example, ``Server/Server/Config`` creates and configures it's encoder:

```swift
public init(
    ...
    encoder:  Configure<JSONEncoder>? = nil,
    ...
) {
    ...
    self.encoder = {
        var e = JSONEncoder()
        encoder?(&e)
        return e
    }()
    ...
}
```
