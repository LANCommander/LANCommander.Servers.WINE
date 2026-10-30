# syntax=docker/dockerfile:1.7

FROM lancommander/base:latest

ARG WINETRICKS_VERSION=20260125

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------
# Wine runtime defaults
#   - WINEPREFIX lives in /config so it persists and is chowned to the run user by the entrypoint
#   - mscoree/mshtml are disabled so Wine never stalls headless on the Mono/Gecko install prompts
#   - WINE_XVFB: auto (use Xvfb when no DISPLAY is set), true, or false; see Scripts/wine-run
#   - WINE_WORKDIR: directory wine-run starts the program from (empty = $SERVER_ROOT)
# ----------------------------
ENV WINEPREFIX=/config/wineprefix \
    WINEDEBUG=-all \
    WINEDLLOVERRIDES="mscoree,mshtml=" \
    WINE_XVFB=auto \
    WINE_XVFB_SCREEN=1024x768x24 \
    WINE_WORKDIR="" \
    XDG_RUNTIME_DIR=/tmp

# ----------------------------
# Dependencies + WineHQ
# ----------------------------
RUN set -eux; \
    dpkg --add-architecture i386; \
    \
    apt-get update; \
    apt-get install --no-install-recommends -y \
        ca-certificates \
        curl \
        gnupg; \
    \
    # Add WineHQ signing key (keyring style, no apt-key)
    install -m 0755 -d /etc/apt/keyrings; \
    curl -fsSL https://dl.winehq.org/wine-builds/winehq.key \
      | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key; \
    chmod 0644 /etc/apt/keyrings/winehq-archive.key; \
    \
    # Add WineHQ Debian Bookworm repository
    echo "deb [signed-by=/etc/apt/keyrings/winehq-archive.key] https://dl.winehq.org/wine-builds/debian bookworm main" \
      > /etc/apt/sources.list.d/winehq.list; \
    \
    apt-get update; \
    apt-get install -y \
        winehq-stable; \
    \
    # Headless display: many Windows dedicated servers are GUI-subsystem programs (e.g. srcds -console
    # allocates a console window) and exit immediately without an X server
    apt-get install --no-install-recommends -y \
        xvfb \
        xauth; \
    \
    # Winetricks dependencies
    apt-get install --no-install-recommends -y \
        cabextract \
        unzip; \
    \
    # Cleanup
    apt-get purge -y --auto-remove gnupg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ----------------------------
# Winetricks (pinned release)
# ----------------------------
RUN set -eux; \
    curl -fsSL "https://raw.githubusercontent.com/Winetricks/winetricks/${WINETRICKS_VERSION}/src/winetricks" \
      -o /usr/bin/winetricks; \
    chmod +x /usr/bin/winetricks

# ----------------------------
# Launcher + LANCommander hooks
# ----------------------------
COPY Scripts/wine-run /usr/local/bin/wine-run
RUN chmod +x /usr/local/bin/wine-run

COPY Hooks/ "${BASE_HOOKS}/"

VOLUME ["/config"]

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]
