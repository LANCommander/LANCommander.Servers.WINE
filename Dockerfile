# syntax=docker/dockerfile:1.7

ARG TARGETARCH=amd64
ARG USE_GUI=false
FROM lancommander/base:latest

# Re-declare build args after FROM so they exist in this stage
ARG TARGETARCH
ARG USE_GUI

ENV DEBIAN_FRONTEND=noninteractive

# ----------------------------
# Dependencies + WineHQ
# ----------------------------
RUN set -eux; \
    # Enable i386 only when building the 32-bit image variant
    if [ "$TARGETARCH" = "i386" ] || [ "$TARGETARCH" = "x86_64" ]; then \
        dpkg --add-architecture i386; \
    fi; \
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
    \
    # Install Wine packages based on TARGETARCH
    if [ "$TARGETARCH" = "i386" ] || [ "$TARGETARCH" = "x86_64" ]; then \
        apt-get install --no-install-recommends -y \
            wine32 \
            libc6:i386 \
            libstdc++6:i386 \
            zlib1g:i386 \
            libglib2.0-0:i386 \
            libgnutls30:i386; \
        ln -s /usr/lib/wine/wine32 /usr/local/bin/wine32; \
    fi; \
    apt-get install --no-install-recommends -y \
        wine64 \
        libc6 \
        libstdc++6 \
        zlib1g \
        libglib2.0-0 \
        libgnutls30; \
    ln -s /usr/lib/wine/wine64 /usr/local/bin/wine64; \
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