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
    crypto/crypto,
  ]
from times import cpuTime

proc main() {.async.} =
  let
    quicAddress1 = MultiAddress.init("/ip4/0.0.0.0/udp/5000/quic-v1").tryGet()
    rng = crypto.newRng()
    srcSwitch = SwitchBuilder
      .new()
      .withAddress(quicAddress1)
      .withRng(rng)
      .withQuicTransport()
      .withNoise()
      .build()

  await srcSwitch.start()

  let tAddress = getEnv("connect_to")
  if tAddress != "":
    let quicV1 = MultiAddress.init("/quic-v1").tryGet()
    let addrs = tAddress.split(",").mapIt(resolveTAddress(it)).concat().mapIt(
        MultiAddress.init(it, IPPROTO_UDP).tryGet().concat(quicV1).tryGet()
      )

    await sleepAsync(1.minutes)

    for i, addr in addrs.pairs:
      try:
        let start = cpuTime()
        let peerId = await srcSwitch.connect(addr, allowUnknownPeerId = true)
        let duration = cpuTime() - start
        info "Connected", peerId = peerId, duration, address = addr
      except CatchableError as exc:
        error "Failed to dial", index = i, errorMsg = exc.msg

    await sleepAsync(10.minutes)

when isMainModule:
  info "running client"
  waitFor main()
