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
* The only exception is that when a user account gets deleted, all data from this user is hard-deleted, ensuring users can erase all of their data from the server permanently.
* Soft and hard deletes are cascading (with few exceptions where they are set null).
* In order to get cascading soft deletes on the server, every (modifiable) table has a corresponding archive table which inherits all fields from this table. Every entry that gets soft deleted is moved into the archive table using triggers. Because soft deleted entries are moved to the inherited archive table, they are technically hard deleted from the normal table causing cascading deletes. This idea was taken from [this stackoverflow answer](https://stackoverflow.com/questions/506432/cascading-soft-delete). All unique indices are only implemented on the normal table, in order to make it possible to create entries that would otherwise clash with deleted entries. 
* On the client side there are no hard deletes at all since the only reason for hard deletes is deleting a user account in which case the whole database gets dropped anyway. Soft deletes are not cascading, but the data providers delete all related entries.

## General synchronization logic
* The server saves the timestamp of the last modification of every entry in the field `last_change`. 
* Clients save the timestamp of their last synchronization and can thus request all changes from the server since this point in time.
* When the client request all changes since its last synchronization, the server returns all entries which have been modified after the given timestamp.
* Clients only use one server. Therefore, they only need to keep track of which entries already exist on the server and which are newly created or updated. The field `sync_status` is used to store this information.

## Client synchronization logic
* When an object is created or updated (including deleted), its `sync_status` is set to 1 (update) or 2 (creation).
* On user request or every couple of minutes (set by `sync interval` in settings) the changes since the last synchronization are fetched from the server and upserted into the database.
* After successfully fetching the latest changes from the server, the client pushes its changes to the server and sets `sync_status` of the corresponding entries to 0.
* After successfully synchronizing with the server, the timestamp is saved in the settings variable `last_sync`.
* *Changes from another device that are sent to the server after the changes are fetched but before the synchronization finishes and `last_sync` is set will never be synchronized with the device. If `last_sync` would be set to the time when the synchronization starts, changes that are made to entries which were modified and synchronized during the last synchronization, would be overridden.*
* *The user can trigger an **Init Sync** in the settings. This drops the database and fetches all data from the server. It resolves all conflicts, but entries that were not synchronized will be lost.*

## Which change wins?
The system supports multiple clients for the same user account. 
It is unlikely that entries are created or changed simultaneously on multiple devices but since it is possible it must be dealt with.

Creations should in general not influence each other as long as they do not clash on unique indices.
If they do clash the entry that reaches the server first wins, regardless of the order in which they are made.
Changes of different entries should also not influence each other as log as they do not clash on unique indices.
If they do clash the same logic as for creations applies.
For conflicts when creating new entries and modifying different entries the client shows a dialog in which the user can choose to fix the conflict by hand or let all conflicting entries be hard deleted automatically.

If the user changes the same entry on different devices, the change which reaches the server first wins and the entry on the other device will silently be overridden during the next down sync.
