<p align="center">
  <img src="../icon.png" height="100" align="center">
</p>

<h1 align="center">Sport Log Server</h1>

## Setup

### General

1. install postgresql and argon2:
    ```bash
    sudo apt install libpq-dev postgresql argon2
    ```
2. create db user:
    ```bash
    sudo -u postgres createuser --createdb sport_admin
    ```
3. hash a new admin password for `admin_password` in *sport-log-server.toml*:
    ```bash
    # type the password and press Ctrl-D twice (Enter would add a newline to the password)
    argon2 $(head -c 16 /dev/urandom | base64) -id -e
    ```

Continue with [Development machine](README.md#development-machine) or [Server (systemd)](README.md#server-systemd).

### Development machine

4. let your own user log in as db user `sport_admin` via Unix socket without password (peer auth), so that diesel, `cargo run`, `cargo test` and psql can connect to the database:
    *   add entry to `/etc/postgresql/<pg_version>/main/pg_ident.conf` (map `sport-log` lets your user log in as db user `sport_admin`)
        ```text
        sport-log <your user> sport_admin
        ```
    *   add entry before `local all all peer` to `/etc/postgresql/<pg_version>/main/pg_hba.conf` (Unix socket logins as db user `sport_admin` use map `sport-log`; `all` databases because `diesel database setup/reset` connects to database `postgres`)
        ```text
        local all sport_admin peer map=sport-log
        ```
    *   reload postgres config
        ```bash
        sudo systemctl reload postgresql
        ```
5. install diesel cli and set up database:
    ```bash
    cargo install diesel_cli --no-default-features --features postgres
    cd ../sport-log-types && diesel database setup --locked-schema && cd ../sport-log-server
    ```
6. copy *sport-log-server.toml.template* to *sport-log-server.toml* and set the hash from step 3 as `admin_password`:
    ```bash
    cp sport-log-server.toml.template sport-log-server.toml
    ```
7. run server
    ```bash
    cargo run --release
    ```

### Server (systemd)

4. create new user `sport_admin` (same name as the db user, so it can connect via Unix socket without password)
    ```bash
    sudo useradd --system --home-dir /var/lib/sport-log-server --shell /usr/sbin/nologin sport_admin
    ```
5. create database (the server creates the tables on start)
    ```bash
    sudo -u sport_admin createdb sport_log
    ```
6. install executable at: */usr/local/bin/sport-log-server*
    ```bash
    cargo build --release
    sudo install -m 755 ../target/release/sport-log-server /usr/local/bin/sport-log-server
    ```
7. install config at: */etc/sport-log-server/sport-log-server.toml* and set the hash from step 3 as `admin_password`; consider turning off `user_self_registration` and `ap_self_registration` if they are not needed (then only the admin can create users and action providers)
    ```bash
    sudo mkdir -p /etc/sport-log-server
    sudo install -m 640 -g sport_admin sport-log-server.toml.template /etc/sport-log-server/sport-log-server.toml
    sudoedit /etc/sport-log-server/sport-log-server.toml
    ```
8. put *ref.log* and the app files (*app-production-release.apk*, ...) into the app dir */var/lib/sport-log-server*
    ```bash
    sudo mkdir -p /var/lib/sport-log-server
    ```
9. install systemd start script
    ```bash
    sudo cp sport-log-server.service /etc/systemd/system/sport-log-server.service
    sudo systemctl daemon-reload
    sudo systemctl enable --now sport-log-server
    sudo systemd-analyze security sport-log-server
    ```
10. set up a reverse proxy, since the server only listens on `127.0.0.1:8000` (`release_address`), e.g. Caddy in */etc/caddy/Caddyfile*
    ```caddy
    sport-log.example.com {
        reverse_proxy 127.0.0.1:8000
    }
    ```

### Update server

1. update Rust
    ```bash
    rustup update
    ```
2. build and install new executable
    ```bash
    cargo build --release
    sudo install -m 755 ../target/release/sport-log-server /usr/local/bin/sport-log-server
    ```
3. restart server
    ```bash
    sudo systemctl restart sport-log-server
    sudo systemctl status sport-log-server
    ```

## Connect to database with psql

```bash
sudo -u sport_admin psql -d sport_log
# development machine: psql -U sport_admin -d sport_log
```

## Backup database

```bash
# custom format without compression, so that backup tools can deduplicate it
sudo -u sport_admin pg_dump -d sport_log -Fc -Z 0 > sport-log_$(date +%Y-%m-%d).dump
# development machine: pg_dump -U sport_admin -d sport_log -Fc -Z 0 > sport-log_$(date +%Y-%m-%d).dump
```

## Restore database

```bash
sudo systemctl stop sport-log-server
sudo -u sport_admin dropdb --if-exists sport_log
sudo -u sport_admin createdb sport_log
sudo -u sport_admin pg_restore -d sport_log --single-transaction --exit-on-error < sport-log.dump
sudo systemctl start sport-log-server # the server runs pending migrations on start
# development machine: same without systemctl, with -U sport_admin instead of sudo -u sport_admin
```

## Update DB Schema

```bash
# update database by hand and only update schema.rs
cd sport-log-types && diesel print-schema > src/schema.rs
# OR
# recreate database
cd sport-log-types && diesel database reset --locked-schema
```

## Reset User Password

```sh
# generate password hash - type the password and press Ctrl-D twice (Enter would add a newline to the password)
argon2 $(head -c 16 /dev/urandom | base64) -id -e
# log in to postgres as sport_admin
sudo -u sport_admin psql -d sport_log # development machine: psql -U sport_admin -d sport_log
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
