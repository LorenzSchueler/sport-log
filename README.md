<p align="center">
  <img src="icon.png" height="100" align="center">
</p>

<h1 align="center">Sport Log</h1>
  
![](https://img.shields.io/github/actions/workflow/status/LorenzSchueler/sport-log/rust.yml?branch=master&label=Rust%20CI)
![](https://img.shields.io/github/actions/workflow/status/LorenzSchueler/sport-log/flutter.yml?branch=master&label=Flutter%20CI)
![](https://img.shields.io/github/license/LorenzSchueler/sport-log)
![](https://img.shields.io/github/contributors/LorenzSchueler/sport-log)

Sport Log consists of an app written in 🐦 Flutter together with a server backend written in 🦀 Rust.
Additionally, there are action providers which can perform scheduled actions like importing or exporting data from other sources or providing automated reservations on other platforms.
The client and action providers communicate with the server via a REST API.
The client has an own database in order to allow offline use. It synchronizes with the server when connectivity is available.

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

## 🥕 Features

- 🔓 open source and add free
- 🛈 ️open REST API
- 🔁 auto synchronization and multi device support while still allowing offline use
- 🏋️ track your strength metrics (input of sets and reps)
- 💯 track your metcons (enter scores for predefined or user defined workouts)
- 🏃 GPS tracking for outdoor activities (supports 👣 step counting and 💓 heart rate tracking)
- 🏞 plan routes in advance and use them when tracking (also supports import/ export as GPX)
- 📝 add diary entries
- 📊 statistics about workouts including 🏅 records, 📈 charts over time and much more
- 🚴 create new movements
- 🗺️ map with different styles (⛺ outdoor, 🚗 street, 🛰️ satellite) support for 🌍 3D and ⛰️ hill shading
- 💾 download offline maps (*not yet supported*)
- ⏱️ timer with different modes (timer, interval, stopwatch)
- 🗓️ schedule task to be executed by action providers

## 🏛 Project Structure

The server and action providers as well as helper tools are structured as follows:

- [migrations](migrations) SQL files and methods for server database
- [sport-log-server](sport-log-server) central server backend
- [sport-log-types](sport-log-types) rust types for use in all rust crates
- [sport-log-types-derive](sport-log-types-derive) rust macros used in [sport-log-types](sport-log-types) and [sport-log-server](sport-log-server)
- [sport-log-scheduler](sport-log-scheduler) responsible for creating action events from action rules, deleting old action events and for garbage collection
- [sport-log-ap-utils](sport-log-ap-utils) helper functions for rust action providers
- [sport-log-action-provider-sportstracker](sport-log-action-provider-sportstracker) fetches new cardio sessions from sportstracker
- [sport-log-action-provider-wodify-login](sport-log-action-provider-wodify-login) reserves spots in wodify classes
- [sport-log-action-provider-wodify-wod](sport-log-action-provider-wodify-wod) fetches and saves the wod from wodify

The flutter app lives in [sport-log-client](sport-log-client)

## 📖 Documentation

Refer to [server docs](sport-log-server/README.md), [client docs](sport-log-client/README.md) and [synchronization docs](SYNCHRONIZATION.md).

## 🤝 Contributing

We would be grateful for any Issues and PRs.

For questions please use the [discussions](https://github.com/LorenzSchueler/sport-log/discussions).

## ⚖ License

[GPL-3.0 License](LICENSE)
