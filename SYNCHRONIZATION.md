# Synchronization Strategy

## Server Database
All tables that can be modified by users have the fields `epoch` (a `bigint`) and `deleted` (a `boolean`).

## Client Database
All tables that can be modified by users have the fields `sync_status` (an `integer` with values 0, 1, or 2) and `deleted` (an `integer` with values 0 or 1).
- `sync_status = 0`: The entry is synchronized with the server (no changes).
- `sync_status = 1`: The entry is modified locally but not yet on the server (dirty).
- `sync_status = 2`: The entry is newly created but not yet on the server.

## Handling Deletions
- Generally, objects are only created and updated but never deleted.
- Deletions are implemented as soft deletes, meaning they are treated as updates rather than deletions.
- **Exception:** When a user account is deleted, all data associated with that user is hard-deleted to ensure that users can permanently erase their data from the server.
- Soft and hard deletes are cascading, with a few exceptions where references are set to `NULL`.
- On the server, each modifiable table has an associated archive table that inherits all fields from the original table.
  When an entry is soft-deleted, it is moved to the archive table via triggers.
  This effectively hard-deletes the entry from the original table, causing cascading deletes.
  All unique indices only exist for the original table, so that new entries cannot clash with deleted ones.
  This idea was taken from [stackoverflow](https://stackoverflow.com/questions/506432/cascading-soft-delete).
- On the client side, there are no hard deletes (since deleting a user account results in the entire database being dropped).
  Soft deletes are not cascading, but data providers ensure that all related entries are deleted.

## Synchronization Logic
Synchronization consists of two steps: **Down Sync** and **Up Sync**. Synchronization occurs at app startup, at regular intervals (defined by the `sync interval` setting), or upon user request.

### Down Sync
- The server saves the epoch of the last modification of every entry in the field `epoch`.
- Clients store the last synchronized `epoch` for each table in a `epoch_map` settings variable.
- During **Down Sync**, the client fetches all changes with `epoch` values greater than those stored in `epoch_map`.
  These changes are upserted into the client database, and `epoch_map` is updated with the highest `epoch` values for each table.

### Up Sync
- Clients only sync with one server. They track which entries exist on the server and which are newly created or updated using the `sync_status` field.
- When an entry is created, updated (including soft deleted), its `sync_status` is set to 1 (updated) or 2 (created).
- After **Down Sync** completes successfully, **Up Sync** starts.
  All entries with `sync_status` of 1 or 2 are pushed to the server.
  Then, `sync_status` is reset to 0, and the `epoch` of the table is updated in `epoch_map` with the `epoch` value returned by the server.

### Epoch
`epoch` is an integer which on every insert/ update to the server database gets set to `max(epoch) + 1`.
It serves as an abstract identifier for a point in time.

### Init Sync
Users can trigger an **Init Sync** in the settings. This operation drops the local database and fetches all data from the server, resolving all conflicts. However, any unsynchronized entries will be lost.

## Conflict Resolution: Which Change Wins?
The system supports multiple clients for the same user account.
Although it is unlikely that entries will be created or modified simultaneously on multiple devices, the system must handle this possibility.

- Creations generally do not affect each other unless they clash on unique indices.
  In the event of a clash, the entry that reaches the server first wins, regardless of the order in which they were created.
- Changes to different entries typically do not interfere with each other unless they clash on unique indices.
  In such cases, the same rule applies: the first entry to reach the server wins.
- For conflicts arising from simultaneous creation and modification of different entries, the client displays a dialog allowing the user to manually resolve the conflict or automatically delete all conflicting entries.
- If the same entry is modified on different devices, the change that reaches the server first wins.
  The corresponding entry on the other device will be silently overridden during the next **Down Sync**.