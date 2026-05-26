# Fixes for OBS having a high CPU load and crashes

Feel free to create a ticket at OBS https://github.com/obsproject/obs-studio and tell them to **permanently fix it updating the library** (simple enough)

Steps:
1. Download the [zip file](https://github.com/moo-the-cow/moo-rist-hosting-native/raw/refs/heads/main/obs/librist-windows-x64-dll.zip)
2. Stop OBS
3. Create a copy of your original librist.dll (just in case - see screenshot)
4. Replace the `librist.dll` with the one from the zip
5. Start OBS and enjoy

<img width="940" height="610" alt="image" src="https://github.com/user-attachments/assets/cab4c3b0-76fe-41b3-bd23-813a530c5021" />

There is a chance that this dll might get overwritten on updates, so you will have to do that probably every time you perform an update.

Also new librist risturl arguments that would usually work like `&username=moo&password=xxx` need to be implemented by the OBS team. For unknown reason they don't just take the whole url but seem to parse and process it
