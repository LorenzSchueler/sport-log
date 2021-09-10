# Sport Log Server

## Setup

1. install postgresql: `apt install libpq-dev postgresql-client-common postgresql`
1. install diesel cli: `cargo install diesel-cli --no-default-features --features postgres`
1. create db user: `sudo -u postgres createuser --createdb --pwprompt sport_admin`
1. create `.env` file in repo root with the following content:
    ```
    DATABASE_URL=postgres://sport_admin:<password>@localhost/sport_log
    ```
1. copy *sport-log-server-config.toml.template* to *sport-log-server-config.toml*: `cp sport-log-server-config.toml.template sport-log-server-config.toml`
1. edit *sport-log-server/sport-log-server-config.toml*
1. set up tables: `cd ../sport-log-types && diesel database setup && ./patch.sh && cd ../sport-log-server`
1. (optional) enable password auth for Unix Domain Socket connections (for psql): 
    * add entry `local sport_log sport_admin md5` as second entry (after entry for user postgres) to `/etc/postgresql/<pg_version>/main/pg_hba.conf`
    * `sudo service postgresql reload`

## Run server in debug mode

```bash
cargo run
```

## Update DB Schema

```bash
cd ../sport-log-types && diesel database reset && ./patch.sh && cd ../sport-log-server
```

## SystemD Setup

*replace ```<user>``` with the user you want to run the server with*

1. install executable at: */usr/local/bin/sport-log-server*
    ```bash
    cargo build --release
    sudo cp ../target/release/sport-log-server /usr/local/bin/sport-log-server
    sudo chmod 740 /usr/local/bin/sport-log-server
    sudo chown <user> /usr/local/bin/sport-log-server
    ```
1. install config at: */etc/sport-log-server/sport-log-server-config.toml*
    ```bash
    sudo mkdir -p /etc/sport-log-server
    sudo cp sport-log-server-config.toml /etc/sport-log-server/sport-log-server-config.toml
    sudo chmod 600 /etc/sport-log-server/sport-log-server-config.toml
    sudo chown -R <user> /etc/sport-log-server
    ```
1. edit */etc/sport-log-server/sport-log-server-config.toml* if needed
1. install systemd start script
    ```bash
    sudo cp sport-log-server.service /etc/systemd/system/sport-log-server.service
    ```
1. edit */etc/systemd/system/sport-log-server.service* (set user)

## SystemD service

- check status of systemd deamon

    `systemctl status sport-log-server.service`

- start systemd deamon

    `systemctl start sport-log-server.service`

- stop systemd deamon

    `systemctl stop sport-log-server.service`

- enable/ disable start of service at startup

    `systemctl enable sport-log-server.service`

    `systemctl disable sport-log-server.service`

- show logging entries

    `journalctl -o cat -e -u sport-log-server` 
