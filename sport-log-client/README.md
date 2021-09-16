
# Sport Log Client

## Good to know
* to make a clean start (delete the local database) set `doCleanStart` in [Config](lib/config.dart) to `true` (but don't forget to change it back afterwards!)
* to generate test data set `generateTestData` in [Config](lib/config.dart) to `true` (but don't forget to change it back afterwards!); this works best if `doCleanStart` is true also
* to re-run code generate run `flutter pub run build_runner build` (mere build) or `flutter pub run build_runner watch` (build every time, the relevant code changes)

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