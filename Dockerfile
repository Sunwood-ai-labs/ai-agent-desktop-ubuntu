FROM lscr.io/linuxserver/webtop:ubuntu-xfce

# Install dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    ca-certificates \
    ffmpeg \
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

# Configure Google Chrome Policies (Homepage/Startup)
RUN mkdir -p /etc/opt/chrome/policies/managed \
    && echo '{ \
    "HomepageLocation": "https://antigravity.google/", \
    "HomepageIsNewTabPage": false, \
    "RestoreOnStartup": 4, \
    "RestoreOnStartupURLs": ["https://antigravity.google/"] \
    }' > /etc/opt/chrome/policies/managed/antigravity_policy.json

# Prepare Desktop Shortcuts templates
RUN mkdir -p /defaults/Desktop \
    && echo '[Desktop Entry]\nVersion=1.0\nType=Application\nName=Antigravity\nComment=Google Antigravity\nExec=antigravity\nIcon=antigravity\nCategories=Development;IDE;' > /defaults/Desktop/antigravity.desktop

# Finalize labels
LABEL maintainer="Antigravity"
