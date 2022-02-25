# ``Server/Server/Config/ResponseHandler/Describe``

HTTP response error message generation.

## Overview

Called when standard check detects invalid `HTTPURLResponse` code.

Takes current ``Server/Server/Config``, `URLRequest`, it's `HTTPURLResponse` and response `Data`.

Returns string describing occured error.
