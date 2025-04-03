{.used.}

# Nim-Libp2p
# Copyright (c) 2023 Status Research & Development GmbH
# Licensed under either of
#  * Apache License, version 2.0, ([LICENSE-APACHE](LICENSE-APACHE))
#  * MIT license ([LICENSE-MIT](LICENSE-MIT))
# at your option.
# This file may not be copied, modified, or distributed except according to
# those terms.

import options, sequtils
import chronos
import os
import chronicles
import
  libp2p/[
    errors,
    dial,
    switch,
    protocols/ping,
    multistream,
    builders,
    stream/bufferstream,
    stream/connection,
    multicodec,
    multiaddress,
    peerinfo,
    crypto/crypto,
    protocols/protocol,
    protocols/secure/secure,
    muxers/muxer,
    muxers/mplex/lpchannel,
    utils/semaphore,
    transports/tcptransport,
    transports/wstransport,
    transports/quictransport,
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
      pingProto = Ping.new(rng = rng)

    await srcSwitch.start()

    await pingProto.start()

    srcSwitch.mount(pingProto)

    let addr1 = getEnv("connect_to")
    if addr1 != "":
      let quicV1 = MultiAddress.init("/quic-v1").tryGet()
      let addrs = resolveTAddress(addr1).mapIt(MultiAddress.init(it, IPPROTO_UDP).tryGet().concat(quicV1).tryGet())
      let start = cpuTime()
      let peerId = await srcSwitch.connect(addrs[0], allowUnknownPeerId = true)
      let duration = cpuTime() - start
      info "CONNECTED!!!!!!!!!!!", duration
      
      let shouldPing = getEnv("should_ping")
      if shouldPing != "":
        while true:
          await sleepAsync(2.seconds)
          try:
            let conn = await srcSwitch.dial(peerId, PingCodec)
            let pingDelay = await pingProto.ping(conn)
            info "PING !!!!!!!!!!!!!!!!"
          except CatchableError as exc:
            error "ERROR!!!!", error=exc.msg

    await sleepAsync(10.minutes)

when isMainModule:
  info "running client"
  waitFor main() 