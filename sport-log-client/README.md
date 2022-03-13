# Sport Log Client

## Config

* `cp sport-log-client/.env.template sport-log-client/.env` and insert your mapbox access token
* in order to compile to project `SDK_REGISTRY_TOKEN` must be in your path. you can set it directly or use `.vscode/launch.json` (see below)

### Config Options
* `ACCESS_TOKEN` (String) maxbox access token needed to create map instances
* `LOG_LEVEL` (String) set log level (values are `VERBOSE`, `DEBUG`, `INFO`, `WARNING`, `ERROR`, `WTF`, `NOTHING`)
* `DELETE_DATABASE` (bool) make a clean start – removes and recreates database and removes last sync datetime (default: `false`)
* `OUTPUT_REQUEST_JSON` (bool) log request json
* `OUTPUT_REQUEST_HEADERS` (bool) log request headers
* `OUTPUT_RESPONSE_JSON` (bool) log response json
* `OUTPUT_DB_STATEMENT` (bool) log executed db statements
* `SERVER_ADDRESS` (String) `<protocol>://<ip>:<port>` address where the server is running

**VS Code**

* `cp .vscode/launch.json.template .vscode/launch.json` (in root folder) and insert you mapbox registry token

**Run on real Android device**

1. enable Developer Options on your Android phone (Settings &#8594; About phone &#8594; tap Build number 7 times)
2. enable USB debugging (Settings &#8594; System &#8594; Developer options)
3. connect your phone with your computer via USB
4. set `SERVER_ADDRESS=<address:port>` with the IP address of your machine (where the server is running on; must be in same Wifi network as your phone)
5. remember to bind the IP address of the server to `0.0.0.0` (in `sport-log-server/sport-log-server-config`, see [Server Setup instructions](../sport-log-server/README.md))

**Run on Android Emulator**

* server address `10.0.2.2:8000` will be used which will be mapped to localhost
* to copy the database to your computer, use
```bash
adb root  # restart adb daemon as root
adb pull /data/user/0/org.sport_log.sport_log_client/databases/database.sqlite <folder> # pull file to local storage
```

## Client Server Synchronization

refer to [synchronization](SYNCHRONIZATION.md)

## Code generation

**changing model types**

* json serialization methods are generated with package `json_serializable`
* to re-run code generation use `flutter pub run build_runner build --delete-conflicting-outputs`
