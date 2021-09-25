#!/usr/bin/bash

cargo check --manifest-path sport-log-action-provider-map-matcher/Cargo.toml
cargo check --manifest-path sport-log-action-provider-sportstracker/Cargo.toml
cargo check --manifest-path sport-log-action-provider-wodify-login/Cargo.toml
cargo check --manifest-path sport-log-action-provider-wodify-wod/Cargo.toml
cargo check --manifest-path sport-log-ap-utils/Cargo.toml
cargo check --manifest-path sport-log-api-tester/Cargo.toml
cargo check --manifest-path sport-log-password-hasher/Cargo.toml
cargo check --manifest-path sport-log-scheduler/Cargo.toml
cargo check --manifest-path sport-log-server/Cargo.toml
cargo check --manifest-path sport-log-types/Cargo.toml
cargo check --manifest-path sport-log-types-derive/Cargo.toml

cargo test -- --test-threads=1
cargo fmt --all 
cargo clippy --all-targets
cargo doc
