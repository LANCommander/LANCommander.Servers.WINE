# LANCommander WINE Base Image

This repository builds a **LANCommander-compatible Docker image with Wine, Winetricks, and Xvfb** on top of `lancommander/base:latest`.

It's intended for running **headless Windows dedicated servers** (and other Windows CLI tools) with the usual LANCommander layout: `Server/` + `Overlay/` merged into `/config/Merged` via OverlayFS, hooks in `/config/Scripts/Hooks`, and the server started by the base entrypoint as the unprivileged `lancommander` user.

## What's in the image

- Base: `lancommander/base:latest` (entrypoint, OverlayFS, hooks, gosu)
- Wine: `winehq-stable` from the **WineHQ official repository** (Debian *bookworm*), with 32-bit support
- Xvfb + xauth: virtual X display for GUI-subsystem servers
- Winetricks: pinned release (`WINETRICKS_VERSION` build arg), installed to `/usr/bin/winetricks`, with `cabextract`/`unzip`
- `wine-run`: launcher for use as `START_EXE` (see below)
- `PostInitialization/10-InitializeWinePrefix.ps1`: creates the Wine prefix on first start

## Running a server

Set `START_EXE` to `wine-run` and put the Windows program and its arguments in `START_ARGS`:

```yaml
services:
  myserver:
    image: lancommander/wine:latest
    volumes:
      - "/data/Servers/My Game:/config"      # Server/ = game files, Overlay/ = your configs
    environment:
      START_EXE: wine-run
      START_ARGS: 'srcds.exe -console -game . -port 27015 +maxplayers 16 +map ctf_3'
    cap_add:
      - SYS_ADMIN                             # OverlayFS
    security_opt:
      - apparmor:unconfined
    restart: unless-stopped
```

`wine-run`:

- starts the program from `WINE_WORKDIR` (default: `$SERVER_ROOT`, i.e. `/config/Merged`), so relative paths resolve against the merged game directory;
- runs Wine under `xvfb-run` when `WINE_XVFB=true`, or when `WINE_XVFB=auto` (the default) and no `DISPLAY` is set.

Xvfb is on by default because many Windows dedicated servers are GUI-subsystem programs. Without a display they cannot create their window or console and **exit immediately without any error output**. For example, Source `srcds.exe -console` allocates a console window and quits when it can't read input from it. If your server is a plain console program, set `WINE_XVFB=false`.

If you replace the image entrypoint with your own, also set `init: true`. `xvfb-run` waits for a signal from Xvfb that never arrives when it runs as PID 1.

## Environment

| Variable | Default | Purpose |
|---|---|---|
| `WINEPREFIX` | `/config/wineprefix` | Wine prefix ("C: drive"). Lives in `/config` so it persists, and is chowned to the run user by the entrypoint. |
| `WINEDEBUG` | `-all` | Wine log channels. Use e.g. `+debugstr,err+all` when a server exits silently; it shows the server's own debug output. |
| `WINEDLLOVERRIDES` | `mscoree,mshtml=` | Disables Mono/Gecko so Wine never stalls on their install prompts. Remove `mscoree` if your server needs .NET via Mono. |
| `WINE_XVFB` | `auto` | `auto`, `true`, or `false`. See above. |
| `WINE_XVFB_SCREEN` | `1024x768x24` | Xvfb screen geometry. |
| `WINE_WORKDIR` | *(empty = `$SERVER_ROOT`)* | Directory `wine-run` starts in. |

## Wine prefix

On first start, the `PostInitialization/10-InitializeWinePrefix.ps1` hook runs `wineboot --init` as the run user (`UID`/`GID`). This keeps the first server launch from stalling, and makes sure the prefix is owned by the user Wine runs as (Wine refuses to use a prefix owned by someone else).

It runs before game hooks numbered `20-*`, so images built on this one can use the prefix in their install hooks. Use the `PreInitializeWinePrefix` / `PostInitializeWinePrefix` hooks to customize it, for example to add registry keys or winetricks verbs.

## Winetricks

Example (one-off, as the run user, against the persistent prefix):

```bash
docker run --rm -it -v "$(pwd)/config:/config" --entrypoint gosu \
  lancommander/wine:latest 1000:1000 winetricks -q vcrun2019 corefonts
```

> Tip: Many Winetricks verbs download installers. If you're in a restricted network environment, plan for that (proxy, allowlists, or pre-staging downloads).

## Tags

`latest` and `<version>` are the image. `latest-gui` and `<version>-gui` are aliases of the same image, kept for compatibility from when Xvfb was a separate build.

## Notes and caveats

- **Security:** Don't run untrusted Windows binaries. Wine is not a sandbox.
- **Locale/timezone:** Defaults come from the base image. Set env vars if your workload is sensitive to locale.

## Repository layout

```
.
├─ Dockerfile
├─ Scripts/
│  └─ wine-run                              (installed to /usr/local/bin/wine-run)
└─ Hooks/
   └─ PostInitialization/
      └─ 10-InitializeWinePrefix.ps1        (copied into ${BASE_HOOKS})
```

## License
This repository contains a Dockerfile and supporting scripts/hooks. License it according to your project needs.

Wine and Winetricks are distributed under their respective licenses; consult their upstream projects for details.
