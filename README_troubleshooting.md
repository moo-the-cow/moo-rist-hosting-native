## Troubleshooting
### I cannot reach those ports, because of my firewall, how to allow those required ports 2030/udp and 5556/udp?
you can use the port opening tools for [Linux](https://raw.githubusercontent.com/moo-the-cow/moo-rist-hosting-native/refs/heads/main/tools/linux_open_firewall_ports.bat) or [Windows](https://raw.githubusercontent.com/moo-the-cow/moo-rist-hosting-native/refs/heads/main/tools/windows_open_firewall_ports.bat)
### The http port 8080 is already used, what am I gonna do?
just set an environment variable `env_http_port=8888` before the startup of the script or put it inside the script
### The websocket port 8081 is already used, what am I gonna do?
just set an environment variable `env_ws_port=8888` before the startup of the script or put it inside the script
