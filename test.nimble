# Package

version = "0.1.0"
author = "Richard Ramos"
description = "A new awesome nimble package"
license = "MIT"
srcDir = "src"
bin = @["test"]

# Dependencies

requires "nim >= 1.6.0",
  "https://github.com/vacp2p/nim-libp2p#e49d8854789ee4a41e88e94dee55756fd3dd8cb4"
