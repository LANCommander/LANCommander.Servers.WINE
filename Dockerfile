# syntax=docker/dockerfile:1.7

ARG USE_GUI=false
FROM lancommander/base:latest

ARG USE_GUI

ENV DEBIAN_FRONTEND=noninteractive

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
    if [ "$USE_GUI" = "true" ] || [ "$USE_GUI" = "1" ] || [ "$USE_GUI" = "yes" ]; then \
        apt-get install --no-install-recommends -y \
            libx11-6 \
            libxext6 \
            libxrender1 \
            libxcb1 \
            xvfb \
            xauth; \
    fi; \
    \
    # Cleanup
    apt-get purge -y --auto-remove gnupg; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ----------------------------
# Winetricks
# ----------------------------
RUN set -eux; \
    curl -fsSL https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks \
      -o /usr/bin/winetricks; \
    chmod +x /usr/bin/winetricks

# ----------------------------
# LANCommander hooks/modules
# ----------------------------
# COPY Modules/ "${BASE_MODULES}/"
# COPY Hooks/ "${BASE_HOOKS}/"

VOLUME ["/config"]

WORKDIR /config
ENTRYPOINT ["/usr/local/bin/entrypoint.ps1"]