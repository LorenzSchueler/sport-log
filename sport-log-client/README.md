# Sport Log Client

## Good to know

**VS Code**

* `cp .vscode/launch.json.template .vscode/launch.json` to use the launch.json template
* in `.vscode/launch.json` you can find all command line arguments ready to use

**Android Studio/Intellij**

* you can set command line arguments in Edit Configurations &#8594; Additional arguments

**Running on real Android device**

1. enable Developer Options on your Android phone (Settings &#8594; About phone &#8594; tap Build number 7 times)
2. enable USB debugging (Settings &#8594; System &#8594; Developer options)
3. connect your phone with your computer via USB
4. use command line option `--dart-define PHONE_SERVER_ADDRESS=<address:port>` with the IP address of your machine (where the server is running on; must be in same Wifi network as your phone)
5. remember to bind the IP address of the server to `0.0.0.0` (in `sport-log-server/sport-log-server-config`, see [Server Setup instructions](../sport-log-server/README.md))

**Running on Android Emulator**

* server address `10.0.2.2:8000` will be used which will be mapped to localhost

**Making changes to database schema**

* use command line option `--dart-define DELETE_DATABASE=true` to make a clean start – removes and recreates database and removes last sync datetime (default: `false`)

**Making changes to model types**

* json serialization methods are generated with package `json_serializable`
* to re-run code generation use `flutter pub run build_runner build --delete-conflicting-outputs` (mere build) or `flutter pub run build_runner watch --delete-conflicting-outputs` (build every time the relevant code changes)

**Wanting to have test data**

* use `--dart-define GENERATE_TEST_DATA=true` to generate test data
* see `test_data` directory for implementation

**Additional Parameters**

* use `--dart-define LOCAL_SERVER_ADDRESS=<address:port>` to set the server address for Web and Linux (default: `127.0.0.1:8000`, so running your server locally there shouldn't be any need to configure this)
* use `--dart-define LOG_LEVEL=<level>` to set the log level (values are `verbose`, `debug`, `info`, `warning`, `error`, `wtf`, `nothing`)
* use `--dart-define OUTPUT_REQUEST_JSON=true` to output all http requests and reponses

## Syncing Strategy

**making changes**

* every object has the field `sync_status` (0 - no changes, synchronized with server, 1 - dirty flag, update not on server, 2 - created flag, not created on server)
* when an object is created or updated (including deleted), it will be written to the database with `sync_status` = 1 (update) or `sync_status` = 2 (creation); directly afterwards it will be pushed to the server; if and only if the request was successful (connected to Internet), the `sync_status` is set to 0
* optional: as soon as a change (update or creation) occurs that could not be pushed to server a global flag (`sync_needed`) in local storage is set to indicate that an up sync is necessary

**syncing up**

* as soon as Internet connection is available (see connectivity package with event stream) and `sync_needed` == true, all objects with `sync_status` == 1 will be put on server and all objects with `sync_status` == 2 will be posted to server

**syncing down**

* on user request or every couple of minutes the syncing endpoint will be used to fetch changes; every object from server will be upserted into the database
* after successfully syncing down, the global `last_sync` date time will be updated

**problems**

* if syncing down is done with `sync_needed` == true (so not every change is pushed to server first), this can lead to an update anomaly
