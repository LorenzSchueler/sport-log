use axum::{
    body::{self, Full},
    extract::{Query, State},
    http::StatusCode,
    response::{IntoResponse, Response},
    Json,
};
use hyper::header::{CONTENT_DISPOSITION, CONTENT_TYPE};
use mime::APPLICATION_OCTET_STREAM;
use serde::{Deserialize, Serialize};
use tokio::{
    fs::{read_to_string, File},
    io::AsyncReadExt,
};

use crate::{
    auth::AuthUser,
    config::Config,
    handler::{ErrorMessage, HandlerError, HandlerResult},
};

#[derive(Debug, Deserialize)]
#[serde(rename_all = "lowercase")]
enum AppFormat {
    APK,
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
    let app_dir = match &config.app_dir {
        None => {
            return Err(HandlerError::from((
                StatusCode::FORBIDDEN,
                ErrorMessage::Other {
                    error: "app download is disabled".to_owned(),
                },
            )));
        }
        Some(app_dir) => app_dir,
    };

    let ref_log = read_to_string(app_dir.join("ref.log"))
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let ref_index = ref_log
        .split("\n")
        .enumerate()
        .find(|(_, current_ref)| current_ref == &git_ref)
        .map(|(index, _)| index);

    match ref_index {
        Some(0) => Ok(Json(AppInfo { new_version: false })),
        Some(_) => Ok(Json(AppInfo { new_version: true })),
        None => Err(HandlerError::from((
            StatusCode::BAD_REQUEST,
            ErrorMessage::Other {
                error: "the git ref was not found in the ref log".to_owned(),
            },
        ))),
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
) -> HandlerResult<impl IntoResponse> {
    let app_dir = match &config.app_dir {
        None => {
            return Err(HandlerError::from((
                StatusCode::FORBIDDEN,
                ErrorMessage::Other {
                    error: "app download is disabled".to_owned(),
                },
            )));
        }
        Some(app_dir) => app_dir,
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
        AppFormat::APK => format!("app-{flavor}-{build}.apk"),
    };
    let path = app_dir.join(&filename);
    let mut file = File::open(path)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    let mut content = Vec::new();
    file.read_to_end(&mut content)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Response::builder()
        .header(CONTENT_TYPE, APPLICATION_OCTET_STREAM.as_ref())
        .header(
            CONTENT_DISPOSITION,
            format!(r#"Content-Disposition: attachment; filename="{filename}""#),
        )
        .body(body::boxed(Full::from(content)))
        .unwrap())
}
