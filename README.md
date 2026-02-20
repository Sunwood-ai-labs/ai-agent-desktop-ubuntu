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
- `webtop-config/`: Persistent user profile, desktop settings, and internal configs.
- `data/`: A dedicated directory for your work data, outputs, and artifacts.