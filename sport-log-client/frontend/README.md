
# Sport Log Client

## Todo

### General
* [ ] drawer tabs don't restart scaffold
* [ ] improve landing screen
* [ ] i18n
* [ ] local units (metric vs imperial system)
* [ ] maybe put initial resource loading into resource bloc
* [ ] keep fabs from covering/blocking content
* [ ] refresh on pull down
* [ ] remove naive time
* [ ] runtime id state accessible for whole app
* [ ] use hive instead of shared preferences
* [ ] handle time zone in all time fields
* [ ] add to string methods for debugging
* [ ] length restrictions for string inputs
* [ ] restrict int numbers coming from user input
* [ ] fetch full account data on login
* [ ] page showing recent activity

### New Metcon Screen
* [ ] movement picker with possibility to create new movements (we'll need movement creation screen first)
* [ ] double picker widget for metcon movement weight
* [ ] int picker: same baseline as other form inputs
* [ ] OutlinedButtons bigger

### Movements
* [ ] show description and category in list

### Database
* [ ] shouldn't be possible to delete e. g. movement when it is referenced by other resource
* [ ] check unique constraints
* [ ] delete database on logout/user deletion

# Sync
* new flag, wenn vom server zurück auf false; nur in DB
* last modified nur in DB
