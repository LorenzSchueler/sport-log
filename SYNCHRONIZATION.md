# Synchronization Strategy

## Server DB
All tables (which can be modified by users) have the fields `last_change timestamptz` and `deleted boolean`.

## Client DB
All tables (which can be modified by users) have the fields `sync_status integer` (0, 1 or 2) and `deleted integer` (0 or 1).
* `sync_status` = 0 means no changes (synchronized with server)
* `sync_status` = 1 means dirty (update not on server)
* `sync_status` = 2 means created (created not on server)

## Deletes
* In general objects are only created and updated but not deleted.
* Deletions are implemented as soft deletes and can therefore be treated as updates.
* The exception to this is that if a user account gets deleted all data from this user is hard-deleted, thus making sure the user can erase all of its data from the server permanently.
* Soft and hard deletes are cascading (with few exceptions where they are set null).
* In order to get cascading soft deletes on the server, every (modifiable) table has a corresponding archive table which inherits all fields from this table. Every entry that gets soft deleted is moved into the archive table using triggers. Because soft deleted entries are moved to the inherited archive table, they are technically hard deleted from the normal table causing cascading deletes. This idea was taken from [this stackoverflow aswer](https://stackoverflow.com/questions/506432/cascading-soft-delete). All unique indices are only implemented on the normal table, in order to make it possible to create entries that would otherwise clash with deleted entries. 
* On the client side there are no hard deletes at all since the only reason for hard deletes is deleting a user account in which case the whole database gets dropped anyway. Soft deletes are not cascading, but the data providers delete all related entries.

## General synchronization logic
* The server has to be able to provide clients with all changes since their last synchronization without sending everything. In order to be able to do so it saves the timestamp of the last change of every entry in the field `last_change` and can then send all entries that have changed since a given point in time.
* Clients save the timestamp of their last synchronization and can thus request all changes from the server since this point in time.
* Clients only use one server. This means they only have to keep track of what the server already knows and what was created or updated. Every modifiable entry has therefore the field `sync_status`.

## Client synchronization logic
* When an object is created or updated (including deleted), it will be written to the database with `sync_status` = 1 (update) or `sync_status` = 2 (creation).
* On user request or every couple of minutes (according to `sync interval` set in settings) the syncing endpoint of the server will be used to fetch changes. Every object from server will be upserted into the database.
* After successfully fetching the latest changes from the server, the client will push its changes to the server and set `sync_status` of the corresponding entries to 0.
* After successfully synchronizing with the server, the timestamp is saved in the settings variable `last_sync`.

## Which change wins?
The system supports multiple clients for the same user account. 
It is unlikely that entries are created or changed simultaneously on multiple devices but since it is possible it must be dealt with.

Creations should in general not influence each other as long as they do not clash on unique indices.
If they do clash the entry that reaches the server first wins, regardless of the order in which they are made.
Changes of different entries should also not influence each other as log as they do not clash on unique indices.
If they do clash the same logic as for creations applies.
For both conflicts on creations and changes of different entries the client will show a dialog in which the user can choose to fix the conflict by hand or let all conflicting entries be hard deleted automatically.

TODO: Currently this only works for upsync; during downsync incoming changes that clash with local ones currently fail instead of overriding the local ones.

If the user changes the same entry on different devices, the change which reaches the server first wins and the entry on the other device will silently be overridden during the next down sync.
