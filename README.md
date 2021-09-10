# Sport Log

Sport Log is a sports tracking app written in Flutter together with a server backend written in Rust.
Additionally, there are action providers which are intended to do scheduled repetitive actions like map matching, fetching and inserting data from other sources, exporting data or providing automated reservations for other platforms.
The client and action providers communicate with the server via a REST API.
The client has an own database that synchronizes with the server when connectivity is available in order to allow offline use while still allowing synchronization between multiple devices.

## Goals

The goal of this project is to provide an open source and add free sports tracking app that combines functionality from traditional running or biking apps (focused on GPS tracking) with gym apps (focused on input of sets and reps) together with CrossFit apps (focused on metcons) so that you have all your data in one place.
A key aspect is the self-hosted server backend that also supports multiple users and sharing of data between them.
This way you own your data, and we can provide functionality to export it easily in well established formats.
Additionally, the concept of action provides tries to make this project easily extensible.

## Roadmap and supported features

see [#1](https://github.com/LorenzSchueler/sport-log/issues/1)

## Project Structure

The server and action providers as well as helper tools and libraries are structured in multiple crates:

- [**sport-log-types**] rust types for use in all rust crates (also includes SQL files and methods for database access)
- [**sport-log-types-derive**] macros for types
- [**sport-log-server**] central server backend
- [**sport-log-scheduler**] responsible for creating action events from action rules and deleting old action events
- [**sport-log-api-tester**] command line HTTP client for API testing and manual communication with the server
- [**sport-log-password-hasher**] hash passwords and verify hashes and passwords that can be stored in the server backend
- [**sport-log-ap-utils**] helper functions for rust action providers
- [**sport-log-action-provider-map-matcher**] matches tracked cardio sessions against OSM paths and stores them as routes
- [**sport-log-action-provider-sportstracker**] fetches new cardio sessions from sportstracker
- [**sport-log-action-provider-wodify-login**] reserves spots in crossfit classes
- [**sport-log-action-provider-wodify-wod**] fetches and saved the wod

The flutter app lives in [**sport-log-client**]()

## Setup

refer to [server setup](sport-log-server/README.md)

## Contributing

We would be grateful for any Issues and PRs. Please file your PRs against `server`, `client` or `action-provider` respectively.

For Questions please use the [discussions](https://github.com/LorenzSchueler/sport-log/discussions)

## License

[GPL-3.0 License](LICENSE)