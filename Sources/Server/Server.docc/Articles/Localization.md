# Localization

Package text can be localized to support your project's languages.

## Overview

Add a file named `Server.strings` to your project and tell Xcode to localize it.

Paste the following text and correct localized values accordingly:

```swift
/* Server error description. */
"Incorrect URL." = "Некорректный URL.";

/* Server error description. */
"Server error: %@" = "Сервер сообщил об ошибке: %@";

/* Server error description. */
"Server provided incorrect data: %@" = "Сервер вернул некорректные данные: %@";
```
