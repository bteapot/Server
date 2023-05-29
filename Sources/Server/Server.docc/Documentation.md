# ``Server``

Asynchronous Swift dynamically configurable network layer.

## Overview

This small library provides solution for most modern Swift application's networking needs. It designed to be dependable on application user's state, dynamically changing it's configuration and request parameters on user authorization or other environment changes. Information exchange – encoding of outgoing data, setting of corresponding request headers, checking response code, decoding received data – is done through single method.

Making a request would be as simple as:

```swift
try await Server.back
    .request(
        type: .post,
        path: "/ping"
    )
```

Or as complex as:

```swift
let userCard =
    try await Server.back
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
            ]),
            take: .json(UserCard.self)
        )
```

## Topics

### Usage

- <doc:Designing>
- <doc:Localization>

### Configuring server

- ``Server/Server``
- ``Server/Server/Config-swift.struct``

### Making requests

- ``Server/Server/raw(with:)``
- ``Server/Server/request(type:base:path:timeout:headers:query:send:take:catch:)``
- ``Server/Server/Send``
- ``Server/Server/Take``

### Tools

- ``Server/Server/Tools``
- ``Server/Server/Reachable``

### Errors

- ``Server/Server/Errors``
