## OBS Setup

Create a MediaSource Item and uncheck "local"

### HOME NETWORK
RELAY_PORT is by default 5556

put `rist://[RELAY_IP]:[RELAY_PORT]?cname=irlbox` into Input

put `mpegts` into Input Format

### REMOTE RELAY
put `rist://[RELAY_IP]:[RELAY_PORT]?cname=irlbox&aes-type=128&secret=[YOUR_VERY_LOG_SECRET_HASH]` into Input

put `mpegts` into Input Format

---
## Fix for OBS not refreshing the media source (OBS BUG please report on their github) on stream end

https://github.com/sniffingpickles/BitrateSceneSwitch

