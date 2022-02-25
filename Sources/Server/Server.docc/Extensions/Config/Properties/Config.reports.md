# ``Server/Server/Config/reports``

Optional local file system `URL` for response data dumps on decoding failures.

## Overview

Specify something like

```swift
URL(fileURLWithPath: "/Users/<your username>/Downloads")
```

Dumped files will be named in `<timestamp>-<url>.<mime type extension>` pattern and will contain response data. 

> Warning: This property available only in DEBUG mode.
