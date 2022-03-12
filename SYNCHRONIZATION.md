# Syncing Strategy

## Server DB
All tables (which can be modified by users) have the fields `last_change timestamptz` and `deleted boolean`.

## Client DB
All tables (which can be modified by users) have the fields `sync_status integer` (0, 1 or 2) and `deleted integer` (0 or 1).
* `sync_status` = 0 means no changes (synchronized with server)
* `sync_status` = 1 means dirty (update not on server)
* `sync_status` = 2 means created (created not on server)

## General synchronization logic
* Objects are only created and updated but not deleted.
* Deletions are implemented as soft deletes and can therefore be treated as updates.
* For every (modifiable) table there exists and corresponding archive table which inherits all fields from the normal table. Every entry that gets soft deleted is moved into the archive table using triggers. All unique indices are only implemented on the normal table. Thus, it is possible to create entries that would otherwise clash with deleted entries.
* The server has to be able to provide clients with all changes since their last synchronization without sending everything. In order to be able to do so it saves the timestamp of the last change of every entry in the field `last_change` and can then send all entries that have changed since a given point in time.
* Clients save the timestamp of their last synchronization and can thus request all changes from the server since this point in time.
* Clients only use one server. This means they only have to keep track of what the server already knows and what was created or updated. Every modifiable entry has therefore the field `sync_status`.

## Client synchronization logic
* When an object is created or updated (including deleted), it will be written to the database with `sync_status` = 1 (update) or `sync_status` = 2 (creation).
* On user request or every couple of minutes (according to `sync interval` set in settings) the syncing endpoint of the server will be used to fetch changes. Every object from server will be upserted into the database.
* After successfully fetching the latest changes from the server, the client will push its changes to the server and set `sync_status` of the corresponding entries to 0.
* After successfully synchronizing with the server, the timestamp is saved in the settings variable `last_sync`.

## Which update wins?
The system supports multiple clients for the same user account. 
It is unlikely that entries are created or changed simultaneously on multiple devices but since it is possible it must be dealt with.
Creations should in general not influence each other as long as they do not clash on unique indices.
If they do clash the entry that reaches the server first wins, regardless of the order in which they are made.
The same is true for changes.
This means that a later made changed of an entry will be overridden by an earlier one (w.r.t. arrival on the server).

Bug: During downsync incoming creations that clash with local ones currently fail instead of overriding the local ones.