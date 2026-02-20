# ai-agent-desktop-ubuntu

Ubuntu based Webtop for AI Agents.

## Custom Initialization
- `webtop-config/custom-cont-init.d/01-touch-pid.sh`: Ensures the `selkies` backend starts correctly by creating `/defaults/pid`.

## SSL Configuration
- `webtop-config/ssl/`: Contains certificates for Secure WebSockets (WSS). 
  > [!IMPORTANT]
  > These files are ignored by git because they contain private keys. If missing, the container will automatically generate self-signed certificates on startup.