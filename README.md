# SwiftLogger

A simple logger system for Swift.

## Usage

```Swift
import Logging

let logger = Logger()
logger.add(handler: ConsoleLogHandler())
logger.info("Log anything you want.")
```

## Using Log Levels

```Swift
logger.trace("This is a log message.")
logger.info("This is a log message.")
logger.debug("This is a log message.")
logger.warning("This is a log message.")
logger.error("This is a log message.")
logger.fatal("This is a log message.")
```
