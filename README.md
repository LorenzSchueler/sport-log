# Sport Log

Sport Log is a sports tracking app written in Flutter together with a server backend written in Rust.
Additionally, there are action providers which are intended to do scheduled repetitive actions like fetching and inserting data from other sources.
The client and action providers communicate with the server via a REST API.
In later releases it is planned to equip the client with its own database that synchronizes with the server when connectivity is available in order to allow offline use of the app while still allowing synchronization between multiple devices.

## Goals

The goal of this project is to provide an open source and add free sports tracking app that combines functionality from traditional running or biking apps (focused on GPS tracking) with gym apps (focused on input of sets and reps) together with CrossFit apps (focused on metcons) so that you have all your data in one place.
A key aspect is the self-hosted server backend that also supports multiple users and sharing of data between them.
This way you own your data, and we can provide functionality to export it easily in well established formats.
Additionally, the concept of action provides tries to make this project easily extensible.
Use cases are for example fetching data from external sources or automatic login/ reservation in you gym.

## Roadmap and supported features

see [#1](https://github.com/LorenzSchueler/sport-log/issues/1)

## Project Structure

The sport-log consists of multiple crates:

- **sport-log-client** flutter app
- **sport-log-types** rust types for use in all rust crates (also includes SQL files and methods for database access)
- **sport-log-server** central server backend
- **sport-log-types-derive** macros for types
- **sport-log-api-tester** command line HTTP client for API testing and manual communication with the server
- **sport-log-password-hasher** hash passwords and verify hashes and passwords that can be stored in the server backend
- **sport-log-action-provider-<name>** various action providers

## Setup

* `apt install libpq-dev postgresql-client-common postgresql` for postgresql
* `sudo -u postgres createuser <username>`
* `sudo -u postgres createdb sport_log`
* `sudo -u postgres psql`
    * `alter user <username> with encrypted password '<password>';`
    * `grant all privileges on database sport_log to <username> ;`
* `sudo nano /etc/postgresql/<version>/main/pg_hba.conf`
  * add entry `local sport_log sport_admin md5`
* `sudo service postgresql restart`
* `sudo service postgresql reload`
* create .env file in repo root with the following content:
```
DATABASE_URL=postgres://sport_admin:<password>@localhost/sport_log
ROCKET_DATABASES='{sport_log={url="postgres://<username>:<password>@localhost/sport_log"}}'
```
* `cargo install diesel-cli --no-default-features --features postgres`
* `cd sport-log-types`
* `diesel migration run`
* `./patch.sh`

* `cd ../sport-log-server`
* run the server:`cargo run`


## License

[GPL-3.0 License](LICENSE)