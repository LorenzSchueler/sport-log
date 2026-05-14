use axum::{
    Json,
    extract::{Query, State},
    http::StatusCode,
    response::IntoResponse,
};
use axum_extra::body::AsyncReadBody;
use hyper::{header::CONTENT_DISPOSITION, http::HeaderValue};
use serde::{Deserialize, Serialize};
use tokio::fs::{File, read_to_string};

use crate::{
    auth::AuthUser,
    config::Config,
    handler::{ErrorMessage, HandlerError, HandlerResult},
};

#[derive(Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
enum AppFormat {
    Apk,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
enum BuildType {
    Debug,
    Release,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
enum Flavor {
    Development,
    Production,
}

#[derive(Debug, Deserialize)]
pub struct AppOptions {
    format: AppFormat,
    build: Option<BuildType>,
    flavor: Option<Flavor>,
}

#[derive(Debug, Deserialize)]
pub struct AppRequest {
    git_ref: String,
}

#[derive(Debug, Serialize)]
pub struct AppInfo {
    new_version: bool,
}

pub async fn get_app_info(
    _auth: AuthUser,
    Query(AppRequest { git_ref }): Query<AppRequest>,
    State(config): State<&Config>,
) -> HandlerResult<Json<AppInfo>> {
    let Some(app_dir) = &config.app_dir else {
        return Err(HandlerError::from((
            StatusCode::FORBIDDEN,
            ErrorMessage::Other {
                error: "app download is disabled".to_owned(),
            },
        )));
    };

    if git_ref.len() < 7 || git_ref.chars().any(|c| !c.is_ascii_hexdigit()) {
        return Err(HandlerError::from((
            StatusCode::BAD_REQUEST,
            ErrorMessage::Other {
                error: "the git ref is not a valid git hash".to_owned(),
            },
        )));
    }

    let ref_log = read_to_string(app_dir.join("ref.log"))
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let refs: Vec<_> = ref_log
        .lines()
        .map(str::trim)
        .filter(|r| r.len() >= 7 && r.chars().all(|c| c.is_ascii_hexdigit()))
        .collect();
    let pos = refs
        .iter()
        .position(|current_ref| current_ref.starts_with(&git_ref));

    if let Some(pos) = pos {
        let new_version = pos < refs.len() - 1;
        Ok(Json(AppInfo { new_version }))
    } else {
        Err(HandlerError::from((
            StatusCode::BAD_REQUEST,
            ErrorMessage::Other {
                error: "the git ref was not found in the ref log".to_owned(),
            },
        )))
    }
}

pub async fn download_app(
    _auth: AuthUser,
    Query(AppOptions {
        format,
        build,
        flavor,
    }): Query<AppOptions>,
    State(config): State<&Config>,
) -> HandlerResult<impl IntoResponse + use<>> {
    let Some(app_dir) = &config.app_dir else {
        return Err(HandlerError::from((
            StatusCode::FORBIDDEN,
            ErrorMessage::Other {
                error: "app download is disabled".to_owned(),
            },
        )));
    };

    let build = match build {
        Some(BuildType::Debug) => "debug",
        _ => "release",
    };
    let flavor = match flavor {
        Some(Flavor::Development) => "development",
        _ => "production",
    };
    let filename = match format {
        AppFormat::Apk => format!("app-{flavor}-{build}.apk"),
    };
    let path = app_dir.join(&filename);
    let file = File::open(path)
        .await
        .map(AsyncReadBody::new)
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let headers = [(
        CONTENT_DISPOSITION,
        HeaderValue::from_str(&format!(r#"attachment; filename="{filename}""#)).unwrap(),
    )];

    Ok((headers, file))
}
