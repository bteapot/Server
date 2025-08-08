# ``Server/Server/Config-swift.struct/catcher-swift.property``

Type that provides handler for request error.

## Overview

Can throw the same error, other error, `CancellationError`, or retry request. Default value just throws incoming error.

This parameter can be overriden by any ``Server/Server/request(type:base:path:cache:timeout:headers:query:send:take:catcher:)``.
