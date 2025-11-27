# moo-rist-hosting-native

Check out the zip files for each Operating System

+ [Windows](windows/README.md)

+ [Linux (x86_64)](linux/README.md)

+ [Linux (arm64)](linux_arm64/README.md)

+ [Mac](mac/README.md)

## For all Platforms:
Create a folder `rist-selfhosting` Copy both Zip files into that folder and extract both so it looks like
For Windows
```
rist-selfhosting/
├── librist.zip
├── StatsServer.zip
├── banner.txt
├── stats.json
├── librist
|   ├── tools
|   │   ├── ristreceiver.exe
|   │   └── ristsender.exe
│   └── librist.a
└── StatsServer.exe
```
**EZ mode:**

Download the bad file into your `rist-selfhosting` folder and double click the `RIST_Selfhosting.bat`


For linux, linux_arm64, macos
```
rist-selfhosting/
├── librist.zip
├── StatsServer.zip
├── banner.txt
├── stats.json
├── librist
|   ├── tools
|   │   ├── ristreceiver
|   │   └── ristsender
│   └── librist.a
└── StatsServer
```
**EZ mode:**

Download the shell script into your `rist-selfhosting` folder and execute it

```
bash RIST_Selfhosting.sh
```
