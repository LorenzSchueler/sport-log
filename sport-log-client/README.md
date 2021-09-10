
# Sport Log Client

## Next Steps
* [ ] add github action checks
* [ ] remove unique constraints and use unique partial indices
* [ ] implement syncing and fix bugs in api/db
* [x] create action provider as a thin service layer between ui and api/db
* [ ] adapt metcon pages and strength pages to new business logics (description classes instead of ui classes)

## Bugs
* [ ] create movement on the fly does not work
* [x] usernames/passwords with ':' do not work
* [x] app start without internet connection

## Ui Improvements
* [ ] main drawer tabs don't restart scaffold
* [ ] add actual content to landing screen
* [ ] keep fabs from covering/blocking content
* [ ] int picker: same baseline as other form inputs
* [ ] create double picker
* [ ] create duration picker
* [ ] OutlinedButtons bigger (all of those '+ Select/Add ...' buttons)
* [ ] movements: show description and category in list
* [ ] show last sync time in side drawer

## Localization
* [ ] i18n
* [ ] date format localization
* [ ] local units (metric vs imperial system)
* [ ] handle time zone in all time fields

## Business Logic/State
* [x] runtime id state accessible for whole app (inherited model?)
* [ ] length restrictions for string inputs
* [ ] restrict int numbers coming from user input
* [ ] push changes in user object to server on up sync

## Debugging/Testing/Code Quality
* [ ] add to string methods to types for debugging
* [x] log json requests/responses
* [ ] write tests for database
* [ ] isValid methods: print reason if false
* [ ] use Keys for everything (especially in table creation sql)
* [x] use one string for last_modified, is_new, deleted in every table
* [x] clean unified logging strategy
* [x] similar structure (like in database) in api with subobjects for actual routes
* [x] tidy up helpers directory
* [ ] use mixins on api accessor objects to be more flexible with routes (get/post/put/delete)

## Ideas
* [ ] use hive instead of shared preferences
* [ ] page showing recent activity
* [ ] syncing in different thread / background service
* [ ] simplify error handling (no result type anymore?)

## Database
* [ ] shouldn't be possible to delete e. g. movement when it is referenced by other resource
* [ ] delete database on logout/user deletion


# Syncing Strategy
**making changes**
* every object has the field `sync_status` (0 - no changes, synchronized with server, 1 - dirty flag, update not on server, 2 - created flag, not created on server)
* when an object is created or updated (including deleted), it will be written to the database with `sync_status` = 1 (update) or `sync_status` = 2 (creation); directly afterwards it will be pushed to the server; if and only if the request was successful (connected to Internet), the `sync_status` is set to 0
* as soon as a change (update or creation) occurs, that could not be pushed to server, a global flag (`sync_needed`) in local storage is set to indicate that an up sync is necessary

**syncing up**
* as soon as Internet connection is available (see connectivity package with event stream) and `sync_needed` == true, all objects with `sync_status` == 1 will be put on server and all objects with `sync_status` == 2 will be posted to server

**syncing down**
* on user request or every couple of minutes the syncing endpoint will be used to fetch changes; for every object from server:
    * if id exists in database and `sync_status` = 0, database record is updated
    * if id doesn't exist in database, database record is created
* after successfully syncing down, the global `last_sync` date time will be updated

**problems**
* if syncing down is done with `sync_needed` == true (so not every change is pushed to server first), this can lead to an update anomaly