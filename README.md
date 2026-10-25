# FreeDesk

**Free, open-source remote desktop. Unlimited sessions, no per-seat fees, no subscription.**

FreeDesk is a self-hostable remote support and remote access tool for everyone who is tired of
paying per-minute or per-seat fees for tools like AnyDesk, TeamViewer or BeyondTrust. Connect to
any machine, control it, transfer files — for as long as you want, for as many people as you want,
on infrastructure you own.

> **Status:** v0.1.0 — macOS client (x86_64), verified end-to-end against a self-hosted
> rendezvous/relay stack. Protocol-compatible with RustDesk 1.5.1 peers and servers.

## Features

- **Screen viewing** — hardware-accelerated AV1/VP9 streaming, adaptive quality up to 30 fps
- **Remote control** — full keyboard/mouse control of the remote machine
- **Unattended access** — permanent passwords for machines you manage
- **File transfer** — browse and copy files both directions during a session
- **Self-hosted by default** — talks to *your* rendezvous/relay server out of the box; no
  third-party servers, no telemetry, no cloud dependency, no STUN probes to public services
- **End-to-end encrypted** — NaCl-based encryption with a per-server Ed25519 identity

## How it works

FreeDesk uses the classic two-server architecture:

```
  Controller ──┐                    ┌── Controlled
  (viewer)     ├──►  hbbs (ID / rendezvous server, UDP+TCP 21115-21116, WS 21118)
               └──►  hbbr (relay server, TCP 21117, WS 21119)
```

Peers find each other through `hbbs`, punch a direct connection when possible (verified 1 ms
loopback on LAN), and fall back to `hbbr` relaying when the network blocks peer-to-peer.

## Quick start (macOS, using the release build)

1. Download `FreeDesk-0.1.0-macos-x86_64.zip` from [Releases](../../releases) and unzip.
2. Run the server stack (any machine you control with Rust 1.75+ installed):

   ```sh
   git clone https://github.com/rustdesk/rustdesk-server && cd rustdesk-server
   cargo build --release
   ./target/release/hbbs -r YOUR.SERVER.IP:21117     # ID/rendezvous server
   ./target/release/hbbr                             # relay server
   ```

3. Open `FreeDesk.app`. By default it expects a server at `127.0.0.1` — point it at yours:
   Settings → ID Server = `your.server.ip`, Key = the contents of `id_ed25519.pub` printed
   next to hbbs, Relay = `your.server.ip`.
4. Share the ID, connect from another machine. Done.

## Build from source

Requirements: macOS with Xcode command-line tools, Rust (1.75+), Python 3.

```sh
# 1. Native codec dependencies (libvpx, libyuv, aom, opus) — built into a local tree
bash scripts/build-codec-deps.sh

# 2. Build the client
cd vendor/rustdesk
VCPKG_ROOT="$PWD/../../vendor/vcpkg" cargo build --release
# → target/release/freedesk
```

The bundle layout used by the release zip:

```
FreeDesk.app/
  Contents/
    Info.plist
    MacOS/            freedesk + libsciter.dylib + src/ui/ (sciter UI)
```

## Repository layout

| Path | What it is |
|---|---|
| `vendor/rustdesk/` | The FreeDesk client (fork of RustDesk, rebranded + self-host-only defaults) |
| `vendor/rustdesk-server/` | The `hbbs`/`hbbr` server stack (stock, unmodified) |
| `scripts/build-codec-deps.sh` | Builds libvpx/libyuv/aom/opus into `vendor/vcpkg/` |
| `docs/` | Project website (GitHub Pages) |
| `dist/` | Assembled app bundle (built locally, release zips attach to Releases) |

## Configuration

Client settings live in `~/Library/Preferences/com.freedesk.FreeDesk/`:

- `FreeDesk.toml` — device ID, keypair, `key_confirmed`
- `FreeDesk2.toml` — `[options]`: `relay-server`, `key` (your hbbs public key),
  optional `custom-rendezvous-server` (defaults to `127.0.0.1` when unset)

Server state and the Ed25519 identity (`id_ed25519[.pub]`) live in the server's working
directory. **Never commit those keys.**

## Roadmap

- [ ] macOS `.app` code signing + notarization
- [ ] Permanent-password setup flow + two-factor
- [ ] Linux and Windows client builds
- [ ] App bundle icon and polish
- [ ] Optional, unobtrusive monetization to fund continued development (never gating features)

## License & attribution

GNU Affero General Public License v3.0 (see [`vendor/rustdesk/LICENCE`](vendor/rustdesk/LICENCE)).

FreeDesk is a fork of [RustDesk](https://github.com/rustdesk/rustdesk) — credit where it's due;
their architecture made this possible. Not affiliated with or endorsed by AnyDesk, TeamViewer,
or RustDesk BV. AnyDesk is a trademark of its respective owner; FreeDesk is an independent
project inspired by the *need* for affordable remote access, not by Anyone's code.
