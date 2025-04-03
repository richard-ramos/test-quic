# Package

version = "0.1.0"
author = "Richard Ramos"
description = "A new awesome nimble package"
license = "MIT"
srcDir = "src"
bin = @["test"]

# Dependencies

requires "nim >= 1.6.0",
  "https://github.com/vacp2p/nim-libp2p#e82bb5ec6b342a059d640130997c169cd92bf148"
