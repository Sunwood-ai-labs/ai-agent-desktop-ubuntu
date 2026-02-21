FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    ffmpeg \
    openssh-server \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

# Install Antigravity Desktop App
RUN mkdir -p /etc/apt/keyrings \
    && wget -q -O - https://us-central1-apt.pkg.dev/doc/repo-signing-key.gpg | gpg --dearmor --yes -o /etc/apt/keyrings/antigravity-repo-key.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/antigravity-repo-key.gpg] https://us-central1-apt.pkg.dev/projects/antigravity-auto-updater-dev/ antigravity-debian main" > /etc/apt/sources.list.d/antigravity.list

RUN apt-get update && apt-get install -y \
    google-chrome-stable \
    antigravity \
    && rm -rf /var/lib/apt/lists/*

# Launcher for container environments where Chromium sandbox namespaces are restricted.
RUN printf '#!/usr/bin/env bash\nexec antigravity --no-sandbox "$@"\n' > /usr/local/bin/antigravity-launch \
    && chmod +x /usr/local/bin/antigravity-launch

# Chrome launcher with --no-sandbox for container environments
RUN printf '#!/usr/bin/env bash\nexec /usr/bin/google-chrome-stable --no-sandbox --disable-gpu "$@"\n' > /usr/local/bin/google-chrome-launch \
    && chmod +x /usr/local/bin/google-chrome-launch

# Override system google-chrome.desktop to use --no-sandbox (for xdg-open/Antigravity)
RUN sed -i 's|Exec=/usr/bin/google-chrome-stable|Exec=/usr/local/bin/google-chrome-launch|g' /usr/share/applications/google-chrome.desktop

# Override XFCE helper to use the launcher wrapper (exo-open uses this)
RUN sed -i 's|X-XFCE-Binaries=google-chrome;google-chrome-stable;com.google.Chrome;|X-XFCE-Binaries=google-chrome-launch;|g' /usr/share/xfce4/helpers/google-chrome.desktop \
    && sed -i 's|X-XFCE-Commands=%B;|X-XFCE-Commands=/usr/local/bin/google-chrome-launch;|g' /usr/share/xfce4/helpers/google-chrome.desktop \
    && sed -i 's|X-XFCE-CommandsWithParameter=%B "%s";|X-XFCE-CommandsWithParameter=/usr/local/bin/google-chrome-launch "%s";|g' /usr/share/xfce4/helpers/google-chrome.desktop

# Ensure desktop shortcuts appear for existing /config volumes as well.
RUN mkdir -p /custom-cont-init.d \
    && cat <<'EOF' > /custom-cont-init.d/30-desktop-shortcuts.sh
#!/usr/bin/with-contenv bash
set -e
DESKTOP_DIR=/config/Desktop
mkdir -p "$DESKTOP_DIR"

if [ ! -f "$DESKTOP_DIR/antigravity.desktop" ]; then
  cp /defaults/Desktop/antigravity.desktop "$DESKTOP_DIR/antigravity.desktop"
fi

if [ ! -f "$DESKTOP_DIR/google-chrome.desktop" ]; then
  cp /defaults/Desktop/google-chrome.desktop "$DESKTOP_DIR/google-chrome.desktop"
fi

for launcher in "$DESKTOP_DIR/antigravity.desktop" "$DESKTOP_DIR/google-chrome.desktop"; do
  if [ -f "$launcher" ]; then
    chown abc:abc "$launcher"
    chmod 755 "$launcher"
    if command -v s6-setuidgid >/dev/null 2>&1 && command -v gio >/dev/null 2>&1; then
      s6-setuidgid abc gio set "$launcher" metadata::trusted true >/dev/null 2>&1 || true
    fi
  fi
done
EOF
RUN chmod +x /custom-cont-init.d/30-desktop-shortcuts.sh

# Set Google Chrome as default browser for abc user in the persisted /config profile.
RUN cat <<'EOF' > /custom-cont-init.d/40-default-browser-chrome.sh
#!/usr/bin/with-contenv bash
set -e

if ! command -v s6-setuidgid >/dev/null 2>&1; then
  exit 0
fi

s6-setuidgid abc sh -lc '
  export HOME=/config
  xdg-settings set default-web-browser google-chrome.desktop
  xdg-mime default google-chrome.desktop x-scheme-handler/http
  xdg-mime default google-chrome.desktop x-scheme-handler/https
  xdg-mime default google-chrome.desktop text/html
'
EOF
RUN chmod +x /custom-cont-init.d/40-default-browser-chrome.sh

# Prepare Desktop Shortcuts templates
RUN mkdir -p /defaults/Desktop \
    && echo '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Antigravity\nComment=Google Antigravity\nExec=/usr/local/bin/antigravity-launch\nIcon=antigravity\nCategories=Development;IDE;' > /defaults/Desktop/antigravity.desktop \
    && echo '[Desktop Entry]\nVersion=1.0\nName=Google Chrome\nGenericName=Web Browser\nComment=Access the Internet\nExec=/usr/local/bin/google-chrome-launch %U\nStartupNotify=true\nTerminal=false\nIcon=google-chrome\nType=Application\nCategories=Network;WebBrowser;\nMimeType=application/pdf;application/rdf+xml;application/rss+xml;application/xhtml+xml;application/xhtml_xml;application/xml;image/gif;image/jpeg;image/png;image/webp;text/html;text/xml;x-scheme-handler/http;x-scheme-handler/https;' > /defaults/Desktop/google-chrome.desktop

# SSH server setup
RUN mkdir -p /var/run/sshd \
    && sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config \
    && sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config \
    && sed -i 's/#PubkeyAuthentication yes/PubkeyAuthentication yes/' /etc/ssh/sshd_config

# SSH init script for s6-overlay
RUN cat <<'EOF' > /custom-cont-init.d/10-sshd-setup.sh
#!/usr/bin/with-contenv bash
set -e

SSH_DIR="/config/ssh"
USER_SSH_DIR="/config/.ssh"

# Setup persistent host keys
mkdir -p "$SSH_DIR"
if [ ! -f "$SSH_DIR/ssh_host_rsa_key" ]; then
  ssh-keygen -A
  cp /etc/ssh/ssh_host_* "$SSH_DIR/"
  echo "Generated new SSH host keys in $SSH_DIR"
else
  cp "$SSH_DIR"/ssh_host_* /etc/ssh/
  echo "Restored SSH host keys from $SSH_DIR"
fi

# Ensure SSH run directory exists
mkdir -p /var/run/sshd

# Set password for abc user (same as CUSTOM_USER password)
if [ -n "$PASSWORD" ]; then
  echo "abc:$PASSWORD" | chpasswd
fi

# Setup user authorized_keys
mkdir -p "$USER_SSH_DIR"
if [ -f "$USER_SSH_DIR/authorized_keys" ]; then
  chmod 600 "$USER_SSH_DIR/authorized_keys"
  chown -R abc:abc "$USER_SSH_DIR"
  echo "Loaded authorized_keys from $USER_SSH_DIR"
fi

echo "SSH server configured successfully"
echo "Put your public key in: $USER_SSH_DIR/authorized_keys"
EOF
RUN chmod +x /custom-cont-init.d/10-sshd-setup.sh

# SSH service definition for s6-overlay
RUN mkdir -p /etc/s6-overlay/s6-rc.d/sshd \
    && echo "longrun" > /etc/s6-overlay/s6-rc.d/sshd/type \
    && cat <<'EOF' > /etc/s6-overlay/s6-rc.d/sshd/run
#!/usr/bin/with-contenv bash
exec /usr/sbin/sshd -D -e
EOF
RUN chmod +x /etc/s6-overlay/s6-rc.d/sshd/run \
    && mkdir -p /etc/s6-overlay/s6-rc.d/user/contents.d \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/sshd

# Finalize labels
LABEL maintainer="FUTODAMA"
LABEL description="Fully Unified Tooling and Orchestration for Desktop Agent Machine Architecture"
