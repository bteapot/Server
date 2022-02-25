# ``Server/Server/Config/Catcher-swift.typealias``

Request's error mapping or canceling.

## Overview

Closure that takes error produced by request. Can return the same error, other error or `nil`. Returning `nil` will silently terminate request signal without producing value or error.
