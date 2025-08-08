# ``Server/Server/Take``

Processing of expected response data.

## Overview

This structure defines value type returned by ``request(type:base:path:cache:timeout:headers:query:send:take:catcher:)``.

When `URLRequest` is created, this structure may provide appropriate value for `"Accept"` header.

When `URLResponse` with `Data` is received, they can be optionally checked by that structure, and thereafter decoded.

## Topics

### Simple

- ``void()``
- ``data(mimeType:)``

### JSON

- ``json(_:)``

### Custom

- ``custom(mimeType:check:decode:)``
- ``Decode``

### Combined

- ``response(with:)``

### Mapping

- ``map(codes:to:with:)``
- ``Mapper``
