# ``Server/Server/Send``

Composition of request's payload. 

## Overview

This structure provides body's `Data` and appropriate headers for ``request(type:base:path:timeout:headers:query:send:take:catch:)``.

## Topics

### Simple

- ``void()``
- ``data(_:_:)``

### JSON

- ``json(_:)``

### Forms

- ``form(_:)``
- ``multipart(_:)``
- ``Part``

### Custom

- ``custom(_:)``
- ``Encode``
