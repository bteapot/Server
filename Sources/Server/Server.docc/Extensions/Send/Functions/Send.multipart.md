# ``Server/Server/Send/multipart(_:)``

## Overview

```swift
.request(
    type: .post,
    path: "/userinfo",
    query: [
        "id": userID,
    ],
    send: .multipart([
        .png(avatarImage, name: "avatar", filename: "avatar.png"),
        .text(firstName, name: "first_name"),
        .text(lastName, name: "last_name"),
    ])
```
