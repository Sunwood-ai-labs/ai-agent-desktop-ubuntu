# ai-agent-desktop-ubuntu

Ubuntu based Webtop for AI Agents.

## Custom Initialization
- `webtop-config/custom-cont-init.d/01-touch-pid.sh`: Ensures the `selkies` backend starts correctly by creating `/defaults/pid`.

## SSL Configuration
- `webtop-config/ssl/`: Contains certificates for Secure WebSockets (WSS). 
  > [!IMPORTANT]
  > These files are ignored by git because they contain private keys. If missing, the container will automatically generate self-signed certificates on startup.

## Data Persistence
This project uses bind mounts to ensure your data survives container restarts (`docker-compose down`).
- `webtop-config/`: **Internal User Data**. This is mapped to the container's home directory (`/config`). All your desktop files, browser profiles, and app settings are saved here automatically.
- `data/`: **Work Data**. A dedicated directory for external files, outputs, and artifacts.

> [!NOTE]
> Everything you do within the Webtop UI (creating files on the Desktop, changing wallpapers, etc.) is physically stored in your local `webtop-config/` folder.