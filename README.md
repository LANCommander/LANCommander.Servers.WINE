# LANCommander WINE Base Image

This repository builds a **LANCommander-compatible Docker image with Wine + Winetricks** installed on top of `lancommander/base:latest`.

It’s intended for **headless / command-line Windows executables** (dedicated servers, CLI tools, installers scripted via Wine, etc.) and integrates with the LANCommander hook/module conventions by copying `Modules/` and `Hooks/` into the base image locations.

## What’s in the image

- Base: `lancommander/base:latest`
- Wine: from **WineHQ official repository** (Debian *bookworm*)
- Winetricks: installed to `/usr/bin/winetricks`
- LANCommander:
  - `Modules/` → `${BASE_MODULES}/`
  - `Hooks/` → `${BASE_HOOKS}/`
- Default working directory: `/config`
- Declares a volume at: `/config`
- Entrypoint: `/usr/local/bin/entrypoint.ps1`

## Runtime expectations

Wine generally wants a user-writable prefix (Wine “C: drive”) and a writable home directory.

Common defaults:
- `WINEPREFIX=/config/wineprefix`
- `HOME=/config`

If you’re running this container as a non-root user (recommended), ensure `/config` is writable.

## Quick start

### Run an interactive shell

```bash
docker run --rm -it   -v "$(pwd)/config:/config"   -e WINEPREFIX=/config/wineprefix   -e HOME=/config   <your-image>:<tag>   bash
```

### Run a Windows CLI executable (example)

```bash
docker run --rm   -v "$(pwd)/config:/config"   -e WINEPREFIX=/config/wineprefix   -e HOME=/config   <your-image>:<tag>   wine /config/mytool.exe --help
```

## Winetricks

Winetricks is included for installing common dependencies into the Wine prefix (fonts, VC runtimes, etc.).

Example:

```bash
docker run --rm -it   -v "$(pwd)/config:/config"   -e WINEPREFIX=/config/wineprefix   -e HOME=/config   <your-image>:<tag>   winetricks -q vcrun2019 corefonts
```

> Tip: Many Winetricks verbs will download installers; if you’re in a restricted network environment, plan for that (proxy, allowlists, or pre-staging downloads).

## Docker Compose example

```yaml
services:
  wine:
    image: <your-image>:<tag>
    volumes:
      - ./config:/config
    environment:
      WINEPREFIX: /config/wineprefix
      HOME: /config
    command: ["bash", "-lc", "wine /config/mytool.exe --help"]
```

## Notes and caveats

- **First-run initialization:** Wine may populate the prefix on first execution. Persist `/config` if you want that to survive container restarts.
- **Locale/timezone:** Defaults come from the base image. Set env vars if your workload is sensitive to locale.
- **Security:** Don’t run untrusted Windows binaries. Wine is not a sandbox. Consider running as a non-root user, a read-only root filesystem, and with a restricted seccomp/apparmor profile if appropriate.

## Repository layout

```
.
├─ Dockerfile
├─ Modules/
│  └─ (PowerShell modules copied into ${BASE_MODULES})
└─ Hooks/
   └─ (LANCommander hooks copied into ${BASE_HOOKS})
```

## License
This repository contains a Dockerfile and supporting scripts/modules/hooks. License it according to your project needs.

Wine and Winetricks are distributed under their respective licenses; consult their upstream projects for details.
