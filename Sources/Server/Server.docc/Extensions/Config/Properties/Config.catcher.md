# ``Server/Server/Config-swift.struct/catcher-swift.property``

Optional closure for mapping or canceling errors.

## Overview

Closure that takes error produced by request. Can return the same error, other error or `nil`. Returning `nil` will cancel request.

This parameter can be overriden by any ``Server/Server/request(type:base:path:timeout:headers:query:send:take:catch:)``.
