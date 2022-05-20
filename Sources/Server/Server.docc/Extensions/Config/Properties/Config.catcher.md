# ``Server/Server/Config/catcher-swift.property``

Optional closure for mapping or canceling errors.

## Overview

Closure that takes error produced by request. Can return the same error, other error or `nil`. Returning `nil` will silently terminate request signal without producing value or error.

This parameter can be overriden by any ``Server/Server/request(type:base:path:timeout:headers:query:send:take:catcher:)``.
