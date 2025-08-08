# ``Server/Server/request(type:base:path:cache:timeout:headers:query:send:take:catcher:)``

## Overview

This function prepares and asynchronously executes `URLRequest`, checks response and decodes received data.

Execution will be automatically terminated on ``Server``'s configuration change.

So upon starting will do one of the following:

* Return value defined by ``Take`` parameter.
* Throw execution error.
* Throw `CancellationError` on configuration change.

### Assembling request

`URLRequest` will be constructed from parameters specified in current ``Server/Server/config-swift.property``'s ``Config-swift.struct`` and from function call parameters. Most of the call parameters have a default values, so shortest call form will be:

```swift
.request(
    type: .get,
    path: "/ping"
)
```

Parameters `base` and `timeout` if specified and non-`nil`, will override ``Config-swift.struct`` values.

Current config's ``Config-swift.struct/headers`` and ``Config-swift.struct/query`` will be merged with corresponding function call parameters, with call parameters pairs taking precedence.

```swift
.request(
    type: .delete,
    path: "/user",
    query: [
        "id": "42",
    ]
)
```

Outgoing payload is defined by the ``Send`` parameter will be processed and encoded to request's `Data`. It will also provide appropriate request header values.

```swift
.request(
    type: .post,
    path: "/user",
    send: .json(user)
)
```

Expected response is defined by ``Take`` parameter. It will set a value of request header `"Accept"`. In case of ``Take/json(_:)`` it will be `"application/json"`:

```swift
.request(
    type: .get,
    path: "/items",
    take: .json([Item].self)
)
```

### Executing request

Assembled `URLRequest` will be executed with current `URLSession`.

### Checking response

Received `URLResponse` and `Data` will be checked by config's ``Config-swift.struct/response`` or by `check` parameter of  ``Take/custom(mimeType:check:decode:)`` method if such method was used.

Standard procedure checks for correct HTTP response code and terminates with ``Errors/BadHTTPResponse`` if response code fails to be in `200..<300` range.

### Decoding

Received `Data` will be processed by the ``Take`` structure specified on function call.

```swift
.request(
    type: .get,
    path: "/users",
    take: .json([User].self)
)
```

Will throw ``Errors/DecodingError`` on decoding failure. 

### Error handling

Any encountered errors will be handled by the type specified by the `catcher` parameter or by config's ``Config-swift.struct/catcher-swift.property``.
