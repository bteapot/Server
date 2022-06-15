# ``Server/Server/Config-swift.struct/ResponseHandler/standard(_:)``

Standard response check.

## Overview

Checks response code if received response is of `HTTPURLResponse` type.

Throws ``Server/Server/Errors/BadHTTPResponse`` if response code is not within `200 ..< 300` range.

Uses failure description generator from provided ``Describe`` parameter. If none is provided, error description will be constructed from string returned by `HTTPURLResponse.localizedString(forStatusCode:)` and any `UTF8` string that can be retreived from response data.
