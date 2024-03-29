# Server

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

## ReactiveSwift version

ReactiveSwift-flavored Server package is archived in the [reactiveswift](https://github.com/bteapot/Server/tree/reactiveswift) branch and can be referenced by version tags 1.0.x.

## Documentation

Complete Xcode documentation is included with code and its archived version attached to GitHub release page.

Documentation is also available [online](https://swiftpackageindex.com/bteapot/Server/master/documentation/server).
