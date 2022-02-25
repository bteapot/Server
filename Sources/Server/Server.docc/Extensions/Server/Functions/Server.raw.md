# ``Server/Server/raw(with:)``

## Overview

This function takes custom `URLRequest` and returns `SignalProducer` that upon staring will execute that request with current `URLSession` and produce result with value of `Data` and `URLResponse`.

> Important: Events will be propagated on background thread.
