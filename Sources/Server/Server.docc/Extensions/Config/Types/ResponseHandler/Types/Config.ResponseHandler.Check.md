# ``Server/Server/Config/ResponseHandler/Check``

Custom response check closure.

## Overview

Takes current ``Server/Server/Config``, `URLRequest`, it's `URLResponse` and response `Data`.

Returns nothing if everything is in order or throws an error if something is wrong.
