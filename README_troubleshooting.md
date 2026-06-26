## Troubleshooting
### I cannot reach those ports, because of my firewall, how to allow those required ports 2030/udp and 5556/udp?
you can use the port opening tools for [Linux](https://raw.githubusercontent.com/moo-the-cow/moo-rist-hosting-native/refs/heads/main/tools/linux_open_firewall_ports.bat) or [Windows](https://raw.githubusercontent.com/moo-the-cow/moo-rist-hosting-native/refs/heads/main/tools/windows_open_firewall_ports.bat)
### The http port 8080 is already used, what am I gonna do?
just set an environment variable `env_http_port=8888` before the startup of the script or put it inside the script
### The websocket port 8081 is already used, what am I gonna do?
just set an environment variable `env_ws_port=8888` before the startup of the script or put it inside the script
### I use debian bookworm and my glibc is too old to run librist
have a look at [librist old glibc](https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/patches/librist.tar.gz)
and extract it to your folder and overwrite it

```rm -f librist.tar.gz && curl -L -O https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/patches/librist.tar.gz && tar xvfz librist.tar.gz --overwrite```

### I'm using an older librist version on my sender and it doesn't work anymore, whats the issue?
if you get an error like
```
librist 0.2.15 or earlier, the SRP wire format changed in 0.2.16 for RFC 5054 / TR-06-2 compliance. To interoperate with an older peer, add ?srp-compat=1 on BOTH URLs. Otherwise check the password.
```
then you will have to add `srp-compat=1` to the ristreceiver url arguments in the scripts manually
like
```
# Build receiver URL based on NOAUTH setting
if [ "$NOAUTH" = "true" ]; then
    RECEIVER_URL="rist://@0.0.0.0:$RIST_RECEIVER_PORT?rtt-min=100&srp-compat=1&aes-type=$ENCRYPTION&secret=$SECRET"
else
    RECEIVER_URL="rist://@0.0.0.0:$RIST_RECEIVER_PORT?rtt-min=100&srp-compat=1&username=$USERNAME&password=$PASSWORD"
fi```
