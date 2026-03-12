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
## Fix for OBS not refreshing the media source (OBS BUG please report on their github) on stream end (static html)

It also shows a nice overlay showing the bitrate and rtt

HTML Polling version

https://raw.githubusercontent.com/moo-the-cow/streaming-tools/refs/heads/main/obs_RIST_media_source_refresh/index_rist_template.html

Websocket version

https://raw.githubusercontent.com/moo-the-cow/streaming-tools/refs/heads/main/obs_RIST_media_source_refresh/index_rist_websocket_template.html

Configuration File (shared)

https://raw.githubusercontent.com/moo-the-cow/streaming-tools/refs/heads/main/obs_RIST_media_source_refresh/config.js
