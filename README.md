# Logger

A simple logger system for iOS & macOS.

## Usage

```Swift
let logger = Logger()
logger.add(hanlder: ConsoleLogHanlder())
logger.info("Log anything you want.")
```

## Using Log Levels

```Swift
logger.trace("This is a log messsage.")
logger.info("This is a log messsage.")
logger.debug("This is a log messsage.")
logger.warning("This is a log messsage.")
logger.error("This is a log messsage.")
logger.fatal("This is a log messsage.")
```
