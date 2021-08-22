
# Sport Log Client

## Next Steps
* [ ] add github action checks
* [ ] remove unique constraints and use unique partial indices
* [ ] implement syncing and fix bugs in api/db
* [ ] create action provider as a thin service layer between ui and api/db
* [ ] adapt metcon pages and strength pages to new business logics (description classes instead of ui classes)

## Bugs
* [ ] create movement on the fly does not work

## Ui Improvements
* [ ] main drawer tabs don't restart scaffold
* [ ] add actual content to landing screen
* [ ] keep fabs from covering/blocking content
* [ ] int picker: same baseline as other form inputs
* [ ] create double picker
* [ ] create duration picker
* [ ] OutlinedButtons bigger (all of those '+ Select/Add ...' buttons)
* [ ] movements: show description and category in list

## Localization
* [ ] i18n
* [ ] date format localization
* [ ] local units (metric vs imperial system)
* [ ] handle time zone in all time fields

## Business Logic/State
* [ ] runtime id state accessible for whole app (inherited model?)
* [ ] length restrictions for string inputs
* [ ] restrict int numbers coming from user input

## Debugging/Testing
* [ ] add to string methods to types for debugging
* [ ] log json requests/responses
* [ ] write tests for database
* [ ] isValid methods: print reason if false

## Ideas
* [ ] use hive instead of shared preferences
* [ ] page showing recent activity
* [ ] tidy up helpers directory

## Database
* [ ] shouldn't be possible to delete e. g. movement when it is referenced by other resource
* [ ] delete database on logout/user deletion