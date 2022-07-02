<p align="center">
  <img src="../icon.png" height="100" align="center">
</p>

<h1 align="center">Sport Log Client</h1>

![](https://img.shields.io/github/workflow/status/LorenzSchueler/sport-log/Flutter/master?label=Pipeline)
![](https://img.shields.io/github/license/LorenzSchueler/sport-log)

## Config

* `cp sport-log-client/sport-log-client.yaml.template sport-log-client/sport-log-client.yaml` and insert your mapbox access token
* to compile the project `SDK_REGISTRY_TOKEN` must be set as an env var

### Config Options
* `access_token` (String) maxbox access token needed to create map instances
* `server_address` (String) `<protocol>://<ip>:<port>` address where the server is running
* `min_log_level` (String; default: `nothing`) set log level (values are `verbose`, `debug`, `info`, `warning`, `error`, `wtf`, `nothing`)
* `delete_database` (bool; default: `false`) make a clean start – removes and recreates database and removes last sync datetime (default: `false`)
* `output_request_json` (boo; default: `false`l) log request json
* `output_request_headers` (bool; default: `false`) log request headers
* `output_response_json` (bool; default: `false`) log response json
* `output_db_statement` (bool; default: `false`) log executed db statements

### VS Code

* `cp .vscode/launch.json.template .vscode/launch.json` (in root folder) and insert you mapbox registry token

## Build & Run 

### Run on real Android device

1. enable Developer Options on your Android phone (Settings &#8594; About phone &#8594; tap Build number 7 times)
2. enable USB debugging (Settings &#8594; System &#8594; Developer options)
3. connect your phone with your computer via USB
4. set `server_address=<address:port>` with the IP address of your machine (where the server is running on; must be in same Wifi network as your phone)
5. remember to bind the IP address of the server to `0.0.0.0` (in `sport-log-server/sport-log-server-config`, see [Server Setup instructions](../sport-log-server/README.md))

### Run on Android Emulator

* server address `10.0.2.2:8000` will be used which will be mapped to localhost
* to copy the database to your computer, use
```bash
adb root  # restart adb daemon as root
adb pull /data/user/0/org.sport_log.sport_log_client/databases/database.sqlite <folder> # pull file to local storage
```

### Build Flatpak

* install `flatpak` and `flatpak-builder` and freedesktop platform and SDK
```bash
sudo apt-get install -y flatpak flatpak-builder
flatpak remote-add --user --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install --user -y flathub org.freedesktop.Platform//21.08 org.freedesktop.Sdk//21.08
```
* set `SDK_REGISTRY_TOKEN` as env var
* build linux app and install it using flatpak
```bash
flutter build linux --release
flatpak-builder --user --install --force-clean --state-dir ../.flatpak-builder ../flatpak-build flatpak/org.sport-log.sport-log-client.yml
```
* run flatpak
```bash
flatpak run org.sport_log.sport_log_client
```
* build bundle (build in repo -> build bundle)
```bash
flatpak-builder --user --force-clean --repo ../flatpak-repo ../flatpak-build flatpak/org.sport-log.sport-log-client.yml
flatpak build-bundle ../flatpak-repo ~/Downloads/sport-log-client.flatpak org.sport_log.sport_log_client
```
* install from bundle
```bash
flatpak install --user ~/Downloads/sport-log-client.flatpak
```

## Client Server Synchronization

refer to [synchronization](../SYNCHRONIZATION.md)
