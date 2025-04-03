{.used.}

# Nim-Libp2p
# Copyright (c) 2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import strutils
import options, sequtils
import chronos
import os
import chronicles
import
  libp2p/[
    errors,
    dial,
    switch,
    builders,
    stream/bufferstream,
    stream/connection,
    multicodec,
    multiaddress,
    peerinfo,
    crypto/crypto
  ]
from times import cpuTime

proc main() {.async.} =
  let
    quicAddress1 = MultiAddress.init("/ip4/0.0.0.0/udp/12345/quic-v1").tryGet()
    rng = crypto.newRng()
    srcSwitch = SwitchBuilder
      .new()
      .withAddress(quicAddress1)
      .withRng(rng)
      .withQuicTransport()
      .withNoise()
      .build()

  await srcSwitch.start()

  let connectTo = getEnv("connect_to")
  if connectTo != "":
    let quicV1 = MultiAddress.init("/quic-v1").tryGet()

    let connectToSeq = connectTo.split(",")
    for ma in connectToSeq:
      let addrs = resolveTAddress(ma).mapIt(
          MultiAddress.init(it, IPPROTO_UDP).tryGet().concat(quicV1).tryGet()
        )
      let start = cpuTime()
      let peerId = await srcSwitch.connect(addrs[0], allowUnknownPeerId = true)
      let duration = cpuTime() - start
      info "CONNECTED!!!!!!!!!!!", duration, address=ma
  else:
    await sleepAsync(10.minutes)

when isMainModule:
  info "running client"
  waitFor main()
