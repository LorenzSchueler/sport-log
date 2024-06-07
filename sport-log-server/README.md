<p align="center">
  <img src="../icon.png" height="100" align="center">
</p>

<h1 align="center">Sport Log Server</h1>

## Setup

1. install postgresql, argon2 and pwgen: 
    ```bash
    apt install libpq-dev postgresql-client-common postgresql argon2 pwgen
    ```
1. create db user: 
    ```bash
    sudo -u postgres createuser --createdb --pwprompt sport_admin
    ```
1. install diesel cli: 
    ```bash
    cargo install diesel_cli --no-default-features --features postgres
    ```
1. create `.env` file in [sport-log-types](sport-log-types) with the following content:
    ```
    DATABASE_URL=postgres://sport_admin:<password>@localhost/sport_log
    ```
1. set up database: 
    ```bash
    cd ../sport-log-types && diesel database setup --locked-schema && cd ../sport-log-server
    ```
1. copy *sport-log-server.toml.template* to *sport-log-server.toml*: 
    ```bash
    cp sport-log-server.toml.template sport-log-server.toml
    ```
1. hash admin password
    ```bash
    argon2 $(pwgen 16 1) -id -e
    ```
1. edit *sport-log-server.toml* and set new admin password hash
1. (optional) enable password auth for Unix Domain Socket connections (for psql): 
    *   add entry 
        ```text
        local sport_log sport_admin md5
        ```
        as second entry (after entry for user postgres) to `/etc/postgresql/<pg_version>/main/pg_hba.conf`
    *   reload postgres config
        ```bash
        sudo systemctl reload postgresql
        ```

## Run server

```bash
cargo run --release
```

## Connect to database with psql

```bash
psql -U sport_admin -d sport_log
# or
sudo -u postgres psql -d sport_log
```

## Backup database

```bash
pg_dump --dbname=postgres://sport_admin:<password>@localhost/sport_log --data-only --inserts > sport-log_$(date +%Y-%m-%d).dump.sql
```

## Restore database

1. [Setup](README.md#setup-1) step 2 and 5 if necessary
2. delete all data from db (default data created by `diesel database setup`) so that there are no conflicts when dumped data is inserted. Each table must be deleted twice in order to hard delete the data.
    ```bash
    sudo -u postgres psql -d sport_log
    sport_log=# delete from movement;
    sport_log=# delete from movement;
    sport_log=# delete from metcon_movement;
    sport_log=# delete from metcon_movement;
    sport_log=# delete from metcon;
    sport_log=# delete from metcon;
    sport_log=# delete from eorm;
    sport_log=# delete from eorm;
    ```
3. disable trigger `check_strength_session_exists_trigger` (TODO)
    ```bash
    sudo -u postgres psql -d sport_log
    sport_log=# alter table strength_set_archive disable trigger check_strength_session_exists_trigger;
    ```
4. import database dump (but leave table `__diesel_schema_migrations` as is)
    ```bash
    cat sport-log.dump.sql | awk '!/public.__diesel_schema_migrations/' | sudo -u postgres psql -d sport_log --single-transaction --set=ON_ERROR_STOP=1
    ```
5. enable trigger `check_strength_session_exists_trigger` again (TODO)
    ```bash
    sudo -u postgres psql -d sport_log
    sport_log=# alter table strength_set_archive enable trigger check_strength_session_exists_trigger;
    ```

## Change database password

```bash
sudo -u postgres psql
postgres=# \password sport_admin
```

## Update DB Schema

```bash
# update database by hand and only update schema.rs
cd sport-log-types && diesel print-schema > src/schema.rs
# OR
# recreate database
cd sport-log-types && diesel database reset --locked-schema
```

## SystemD Setup for deployment
### Setup 
1. create new user `sport-admin`
    ```bash
    adduser --system --no-create-home sport-admin
    ```
2. install executable at: */usr/local/bin/sport-log-server*
    ```bash
    cargo build --release
    sudo cp ../target/release/sport-log-server /usr/local/bin/sport-log-server
    sudo chmod 740 /usr/local/bin/sport-log-server
    sudo chown sport-admin /usr/local/bin/sport-log-server
    ```
3. install config at: */etc/sport-log-server/sport-log-server.toml*
    ```bash
    sudo mkdir -p /etc/sport-log-server
    sudo cp sport-log-server.toml /etc/sport-log-server/sport-log-server.toml
    sudo chmod 600 /etc/sport-log-server/sport-log-server.toml
    sudo chown -R sport-admin /etc/sport-log-server
    ```
4. install systemd start script
    ```bash
    sudo cp sport-log-server.service /etc/systemd/system/sport-log-server.service
    ```

### On Update
1. [Setup](README.md#setup-1) step 2
2. restart systemd daemon

## SystemD service

- check status

    ```bash
    systemctl status sport-log-server
    ```

- start/ stop/ restart

    ```bash
    systemctl start sport-log-server
    ```

    ```bash
    systemctl stop sport-log-server
    ```

    ```bash
    systemctl restart sport-log-server
    ```

- enable/ disable start of service at startup

    ```bash
    systemctl enable sport-log-server
    ```

    ```bash
    systemctl disable sport-log-server
    ```

- show logging entries

    ```bash
    journalctl -o cat -e -u sport-log-server
    ```

## Client Server Synchronization

refer to [synchronization](../SYNCHRONIZATION.md)

## Reset User Password

```sh
# generate password hash - be careful not to add a newline at the end of the password
argon2 $(pwgen 16 1) -id -e
# log in to postgres
sudo -u postgres psql -d sport_log
# set new password
sport_log=> update "user" set password = '<password hash>' where username = '<username>';
```

## REST API Example

```sh
# get supported api versions
curl 'http://localhost:8001/version' | jq
# get movement with id 1
curl -u user:passwd 'http://localhost:8001/v0.3/movement?id=1' | jq
# get all movements
curl -u user:passwd 'http://localhost:8001/v0.3/movement' | jq
# create new movement
curl -u user:passwd -X POST 'http://localhost:8001/v0.3/movement' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '
    {
        "id":"1000",
        "user_id":"1",
        "name":"MyNewMovement",
        "description":null,
        "movement_dimension":"Distance",
        "cardio":true,
        "deleted":false
    }'
# change movement
curl -u user:passwd -X PUT 'http://localhost:8001/v0.3/movement' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '
    {
        "id":"1000",
        "user_id":"1",
        "name":"MyMovement",
        "description":null,
        "movement_dimension":"Distance",
        "cardio":true,
        "deleted":false
    }'
# (soft) delete movement (set deleted to true)
curl -u user:passwd -X PUT 'http://localhost:8001/v0.3/movement' \
    -H 'Accept: application/json' \
    -H 'Content-Type: application/json' \
    -d '
    {
        "id":"1000",
        "user_id":"1",
        "name":"MyMovement",
        "description":null,
        "movement_dimension":"Distance",
        "cardio":true,
        "deleted":true
    }'

```