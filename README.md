<p align="center">
  <img src="icon.png" height="100" align="center">
</p>

<h1 align="center">Sport Log</h1>
  
![](https://img.shields.io/github/actions/workflow/status/LorenzSchueler/sport-log/rust.yml?branch=master&label=Rust%20Pipeline)
![](https://img.shields.io/github/actions/workflow/status/LorenzSchueler/sport-log/flutter.yml?branch=master&label=Flutter%20Pipeline)
![](https://img.shields.io/github/license/LorenzSchueler/sport-log)
![](https://img.shields.io/github/contributors/LorenzSchueler/sport-log)

<table>
  <tr>
    <td><img src="sport-log-client/screenshots/timeline.png"></td>
    <td><img src="sport-log-client/screenshots/strength_details.png"></td>
    <td><img src="sport-log-client/screenshots/tracking.png"></td>
    <td><img src="sport-log-client/screenshots/route_details.png"></td>
    <td><img src="sport-log-client/screenshots/action_provider_overview.png"></td>
  </tr>
</table>

[All Screenshots](sport-log-client/SCREENSHOTS.md)

Sport Log is a sports tracking app written in Flutter together with a server backend written in Rust.
Additionally, there are action providers which are intended to do scheduled repetitive actions like map matching, fetching and inserting data from other sources, exporting data or providing automated reservations for other platforms.
The client and action providers communicate with the server via a REST API.
The client has an own database in order to allow offline use that synchronizes with the server when connectivity is available.

## Goals

The goal of this project is to provide an open source and add free sports tracking app that combines functionality from:
- traditional outdoor apps (map download, outdoor and satellite map styles, route planning, slope inclination, ...)
- running or biking apps (GPS tracking)
- gym apps (input of sets and reps)
- functional training apps (metcons) 
This way you have all your data in one place.
It also provides some basic utility functions like custom timers for different styles of workouts.
A key aspect is the self-hosted server backend that also supports multiple users.
This way you own your data, and we can provide functionality to export it easily in well established formats.
Additionally, the concept of action provides tries to make this project easily extensible.

## Project Structure

The server and action providers as well as helper tools and libraries are structured in multiple crates:

- [**sport-log-types**](sport-log-types) rust types for use in all rust crates (also includes SQL files and methods for database access)
- [**sport-log-types-derive**](sport-log-types-derive) macros for types
- [**sport-log-server**](sport-log-server) central server backend
- [**sport-log-scheduler**](sport-log-scheduler) responsible for creating action events from action rules and deleting old action events
- [**sport-log-ap-utils**](sport-log-ap-utils) helper functions for rust action providers
- [**sport-log-action-provider-sportstracker**](sport-log-action-provider-sportstracker) fetches new cardio sessions from sportstracker
- [**sport-log-action-provider-wodify-login**](sport-log-action-provider-wodify-login) reserves spots in crossfit classes
- [**sport-log-action-provider-wodify-wod**](sport-log-action-provider-wodify-wod) fetches and saved the wod

The flutter app lives in [**sport-log-client**](sport-log-client)

## Documentation

refer to [server docs](sport-log-server/README.md) and [client docs](sport-log-client/README.md)

## Contributing

We would be grateful for any Issues and PRs.

For Questions please use the [discussions](https://github.com/LorenzSchueler/sport-log/discussions)

## License

[GPL-3.0 License](LICENSE)
