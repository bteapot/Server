# ``Server/Server/request(type:base:path:timeout:headers:query:send:take:catch:)``

## Overview

This function returns `SignalProducer` that prepares and executes `URLRequest`, checks response and decodes received data.

Execution will be automatically terminated on ``Server``'s configuration change.

So upon starting producer will do one of the following:

* Emit one value defined by ``Take`` parameter.
* Emit error.
* Terminate silently on configuration change.

> Important: Most errors and values will be propagated on background thread.

### Assembling request

`URLRequest` will be constructed from parameters specified in current ``Server/Server/assets-swift.property``'s ``Config`` and from function call parameters. Most of the call parameters have a default values, so shortest call form will be:

```swift
.request(
    type: .get,
    path: "/ping"
)
```

Parameters `base` and `timeout` if specified and non-`nil`, will override ``Config`` values.

Current config's ``Config/headers`` and ``Config/query`` will be merged with corresponding function call parameters, with call parameters pairs taking precedence.

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

> Note: Request will be assembled on the thread from which `SignalProducer` was started.

### Executing request

Assembled `URLRequest` will be executed with current `URLSession`.

### Checking response

Received `URLResponse` and `Data` will be checked by config's ``Config/response`` or by ``Take/check`` method of ``Take`` parameter, if such method exists.

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

Will terminate with ``Errors/DecodingError`` on decoding failure. 

### Error handling

Any encountered errors will be handled by the closure specified by the `catch` parameter or by config's ``Config/catcher-swift.property``. If none of the above specified, errors will be passed as is, with exception of `URLError.cancelled`, in which case signal will be silently terminated.
