# Sport Log Server

## Setup

1. install postgresql: 
    ```bash
    apt install libpq-dev postgresql-client-common postgresql
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
1. generate admin password with [sport-log-password-hasher](../sport-log-password-hasher)
1. edit *sport-log-server.toml* and set new admin password
1. (optional) enable password auth for Unix Domain Socket connections (for psql): 
    *   add entry 
        ```text
        local sport_log sport_admin md5
        ```
        as second entry (after entry for user postgres) to `/etc/postgresql/<pg_version>/main/pg_hba.conf`
    *   reload postgres config
        ```bash
        sudo service postgresql reload
        ```

## Connect to database with psql

```bash
psql -h localhost -U sport_admin -d sport_log
```

## Run server in debug mode

```bash
cargo run
```

## Update DB Schema

```bash
cd ../sport-log-types && diesel database reset --locked-schema && cd ../sport-log-server
```

## Change database password

```bash
sudo -u postgres psql
postgres=# \password sport_admin
```

## SystemD Setup for deployment
service template 
1. create new user `sport-admin`
    ```bash
    adduser --system --no-create-home sport-admin
    ```
1. install executable at: */usr/local/bin/sport-log-server*
    ```bash
    cargo build --release
    sudo cp ../target/release/sport-log-server /usr/local/bin/sport-log-server
    sudo chmod 740 /usr/local/bin/sport-log-server
    sudo chown sport-admin /usr/local/bin/sport-log-server
    ```
1. install config at: */etc/sport-log-server/sport-log-server.toml*
    ```bash
    sudo mkdir -p /etc/sport-log-server
    sudo cp sport-log-server.toml /etc/sport-log-server/sport-log-server.toml
    sudo chmod 600 /etc/sport-log-server/sport-log-server.toml
    sudo chown -R sport-admin /etc/sport-log-server
    ```
1. install systemd start script
    ```bash
    sudo cp sport-log-server.service /etc/systemd/system/sport-log-server.service
    ```

## SystemD service

- check status of systemd deamon

    ```bash
    systemctl status sport-log-server.service
    ```

- start/ stop systemd deamon

    ```bash
    systemctl start sport-log-server.service
    ```

    ```bash
    systemctl stop sport-log-server.service
    ```

- enable/ disable start of service at startup

    ```bash
    systemctl enable sport-log-server.service
    ```

    ```bash
    systemctl disable sport-log-server.service
    ```

- show logging entries

    ```bash
    journalctl -o cat -e -u sport-log-server
    ```

## Client Server Synchronization

refer to [synchronization](SYNCHRONIZATION.md)
