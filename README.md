# ApocalipseBR Anti-Cheat

This project was built using https://github.com/escapepz/project-zomboid-studio

Project Zomboid Build 42 multiplayer anti-cheat for dedicated servers, focused on repeated client liveness challenges and server-side enforcement signals.

This mod is used on the ApocalipseBR dedicated server to support automated enforcement and ban workflows:

https://apocalipse.cloud

## Core Idea

The real value is not "the client can never lie." A compromised client can always try to lie. The value is that cheat engines now have to keep a much larger system coherent over time.

To avoid detection, a modified client has to:

- Keep the anti-cheat files compiling.
- Preserve the mod's event handlers.
- Answer every liveness challenge correctly and on time.
- Track request ids.
- Track nonces.
- Pack valid acknowledgement strings.
- Avoid protected cheat flags, or make larger structural monkey-patches to hide them.
- Hide injected globals, classes, and functions outside the common Lua environment.
- Avoid changing watched vanilla Lua hot-spot functions.
- Avoid suspicious command traffic.
- Survive repeated checks consistently, not just once.

That is a much harder target than simply toggling god mode or injecting a UI panel. The system is designed to catch obvious cheat usage and raise the cost of more advanced Lua-side hacking techniques currently used against the game.

A small server-side update to the signature structure, distributed secret, file names, variable names, watched signatures, or code obfuscation can break a mimic of the challenge algorithm while still forcing cheat authors to know exactly what not to manipulate.

## Features

- Repeated server-to-client liveness challenge using compact hexadecimal payloads.
- Per-player request id and nonce tracking.
- Signature validation for challenges and acknowledgements.
- Protected cheat flag mask reporting.
- Suspicious Lua surface reporting for known cheat globals/classes/functions.
- Canary checks for watched vanilla Lua functions commonly touched by cheat UIs or world interaction patches.
- Suspicious command detection for unexpected `EtherDebug` traffic.
- Server-side clearing of protected sandbox/admin cheat flags from non-privileged players.
- Client cleanup acknowledgement logging.
- Missing, invalid, unexpected, late, and mismatched liveness acknowledgement tracking.
- Configurable liveness failure threshold.
- Threshold ticket creation when server APIs allow it.
- Threshold CSV output for external automation.
- Optional kick after the threshold is reached.

The sandbox cheat clearing is useful, but it is the lesser part of the mod. The main feature is the liveness challenge and the server-side evidence it produces for enforcement automation.

## Threshold File

When a non-privileged player reaches the configured liveness failure threshold, the server appends a row to:

```text
ApocBRAntiCheat_threshold_failures.csv
```

The format is intentionally simple:

```csv
username,reason
```

The values are cleaned to remove commas and newlines before writing. This file is meant to be consumed by external server tooling. On ApocalipseBR, it is used as part of the dedicated server auto-ban workflow.

## Sandbox Options

The mod exposes:

- `ApocBRAntiCheatFailureTicketThreshold`: number of liveness failures required before the threshold action runs. The sandbox file default is `100`.
- `ApocBRAntiCheatKickOnFailureThreshold`: whether the server should also kick after the threshold is reached. Default is `false`.

The server code clamps the threshold between `1` and `1000`.

## Privileged Players

These access levels are exempt:

- `admin`
- `moderator`

All other access levels are treated as non-privileged for this mod.

## Protected Cheat Flags

The protected flag mask is a 16-bit value. Each bit represents one local player flag:

| Hex | Decimal | Flag |
| --- | ---: | --- |
| `0x0001` | 1 | God Mode |
| `0x0002` | 2 | Invisibility |
| `0x0004` | 4 | Ghost Mode |
| `0x0008` | 8 | Noclip |
| `0x0010` | 16 | Fast Move |
| `0x0020` | 32 | Unlimited Carry |
| `0x0040` | 64 | Unlimited Endurance |
| `0x0080` | 128 | Unlimited Ammo |
| `0x0100` | 256 | Instant Timed Actions |
| `0x0200` | 512 | Zombies Don't Attack |
| `0x0400` | 1024 | Invincible |
| `0x0800` | 2048 | Build Cheat |
| `0x1000` | 4096 | Farming Cheat |
| `0x2000` | 8192 | Health Cheat |
| `0x4000` | 16384 | Mechanics Cheat |
| `0x8000` | 32768 | Movables Cheat |

Any non-zero protected flag mask in a liveness acknowledgement is counted as a liveness failure.

## Lua Surface Mask

The suspicious Lua surface mask is also encoded as a 16-bit value:

| Hex | Decimal | Meaning |
| --- | ---: | --- |
| `0x0001` | 1 | Known suspicious global function exists. |
| `0x0002` | 2 | Known suspicious global class/table exists. |
| `0x0004` | 4 | At least three generated-looking global function names are visible. |
| `0x0008` | 8 | A watched Lua canary function changed after the client baseline was captured. |

Any non-zero Lua surface mask is counted as a liveness failure.

## Access Codes

The acknowledgement packs the client's visible access level into one hexadecimal nibble:

| Hex | Access level |
| --- | --- |
| `0x0` | none/normal |
| `0x1` | admin |
| `0x2` | moderator |
| `0x3` | overseer |
| `0x4` | gm |
| `0x5` | observer |

## Hex Challenge Format

The server sends command `L1` with field `p`.

The challenge payload is 17 hexadecimal characters:

```text
VRRRRNNNNBBBBSSSS
```

| Field | Width | Meaning |
| --- | ---: | --- |
| `V` | 1 hex digit | Protocol version. Current value: `1`. |
| `RRRR` | 4 hex digits | Request id, modulo `0x10000`. |
| `NNNN` | 4 hex digits | Server nonce, modulo `0x10000`. |
| `BBBB` | 4 hex digits | Minute bucket, modulo `0x10000`. |
| `SSSS` | 4 hex digits | Challenge signature. |

The challenge signature is:

```lua
mix16(version, requestId, nonce, bucket, 0, 0)
```

The client rejects the challenge if the payload is not exactly 17 characters, the version is not `1`, or the signature does not match.

## Hex Acknowledgement Format

The client answers command `L2` with field `p`.

The acknowledgement payload is 26 hexadecimal characters:

```text
VRRRRNNNNBBBBFFFFUUUUSAAAA
```

| Field | Width | Meaning |
| --- | ---: | --- |
| `V` | 1 hex digit | Protocol version. Current value: `1`. |
| `RRRR` | 4 hex digits | Request id copied from the challenge. |
| `NNNN` | 4 hex digits | Nonce copied from the challenge. |
| `BBBB` | 4 hex digits | Client's current minute bucket. |
| `FFFF` | 4 hex digits | Protected cheat flag mask. |
| `UUUU` | 4 hex digits | Suspicious Lua surface mask. |
| `S` | 1 hex digit | Access level code. |
| `AAAA` | 4 hex digits | Acknowledgement signature. |

The acknowledgement signature is:

```lua
mix16(version, requestId, nonce, bucket, flags + surface, access)
```

The server rejects the acknowledgement if the payload is not exactly 26 characters, the version is not `1`, or the signature does not match.

After unpacking, the server also checks that the request id is pending or still inside the late grace window, the username matches the player that received the challenge, and the nonce matches the stored nonce for that request.

## `mix16` Signature Function

The signature is not meant to be cryptographic. It is a compact consistency check that forces a mimic to know the current structure, secret, fields, and packing rules.

Current implementation:

```lua
ACK_SECRET = 7139

value = ACK_SECRET
value = (value + a * 131) % 65536
value = (value + b * 257) % 65536
value = (value + c * 521) % 65536
value = (value + d * 1031) % 65536
value = (value + e * 2053) % 65536
value = (value + f * 4099) % 65536
```

All fields are packed uppercase with `string.format`:

```lua
challenge = "%01X%04X%04X%04X%04X"
ack       = "%01X%04X%04X%04X%04X%04X%01X%04X"
```

Because values are modulo `65536`, 16-bit fields wrap at `0xFFFF`. The request id intentionally wraps and skips `0`, keeping active ids in `0x0001` through `0xFFFF`.

## Timing And Failure Handling

Every in-game minute, the server:

1. Audits pending cleanup and liveness requests.
2. Scans online players.
3. Clears protected flags from non-privileged players.
4. Sends a fresh liveness challenge.

Liveness challenges stay active for `2` audit ticks. After that, they move to a grace window for `3` more audit ticks. If no valid acknowledgement arrives by the end of the grace window, the server records a `missing_ack` failure.

Failures are counted for reasons such as:

- `missing_ack`
- `invalid_ack`
- `unexpected_ack`
- `mismatched_ack`
- `protected_flags`
- `suspicious_lua_surface`
- `unexpected_debug_command`

Ten clean liveness acknowledgements reset an existing failure streak.

## Recommended Server Setting

Keep Project Zomboid's Lua checksum enabled:

```ini
DoLuaChecksum=true
```

The liveness system is designed to make cheating harder and easier to detect, not to make client Lua infallible. Disabling Lua checksum makes it much easier for attackers to remove or replace the client-side anti-cheat behavior.

## Compatibility

- Built for Project Zomboid Build 42.
- Intended for multiplayer dedicated servers.
- Tested on Build 42.19 or newer.
- Adds no items, maps, recipes, vehicles, or world data.

## Source Layout

- `ApocalipseBR-anti-cheat/common/media/lua/shared/ApocBRAntiCheat/ApocBRAntiCheatShared.lua`: shared masks, packing, signatures, protected flags, canaries, and cleanup helpers.
- `ApocalipseBR-anti-cheat/common/media/lua/server/anticheat-server.lua`: server enforcement loop, liveness request tracking, failure thresholds, tickets, kicks, and logs.
- `ApocalipseBR-anti-cheat/common/media/lua/server/ApocBRAntiCheat/ApocBRAntiCheatThresholdFile.lua`: threshold CSV writer.
- `ApocalipseBR-anti-cheat/common/media/lua/client/anticheat-client.lua`: client liveness acknowledgement, local cleanup, and disconnect fallback.
