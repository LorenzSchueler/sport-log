use std::{iter, time::Duration};

use axum::{
    Json, Router,
    body::{Body, Bytes},
    extract::DefaultBodyLimit,
    http::{Request, StatusCode, header::AUTHORIZATION},
    response::Response,
    routing::{delete, get, post},
};
use sport_log_types::{Version, uri::*};
use tower::ServiceBuilder;
use tower_http::{
    classify::ServerErrorsFailureClass,
    compression::{CompressionBody, CompressionLayer},
    sensitive_headers::SetSensitiveRequestHeadersLayer,
    trace::TraceLayer,
};
use tracing::{Span, debug, trace, warn};

use crate::{error::HandlerError, handler::*, state::AppState};

async fn handler_not_found() -> HandlerError {
    HandlerError::from(StatusCode::NOT_FOUND)
}

async fn get_version() -> Json<Version> {
    Json(Version {
        min: MIN_VERSION.to_owned(),
        max: MAX_VERSION.to_owned(),
    })
}

pub fn get_router(state: AppState) -> Router {
    let admin_router = Router::new()
        .route(
            ADM_PLATFORM,
            post(adm_create_platforms)
                .get(adm_get_platforms)
                .put(adm_update_platforms),
        ) // needed if ap self registration disabled
        .route(
            ADM_ACTION_PROVIDER,
            post(adm_create_action_providers).get(adm_get_action_providers),
        ) // needed if ap self registration disabled
        .route(
            ADM_ACTION_EVENT,
            post(adm_create_action_events)
                .put(adm_update_action_events)
                .delete(adm_delete_action_events),
        ) // scheduler
        .route(
            ADM_CREATABLE_ACTION_RULE,
            get(adm_get_creatable_action_rules),
        ) // scheduler
        .route(
            ADM_DELETABLE_ACTION_EVENT,
            get(adm_get_deletable_action_events),
        ) // scheduler
        .route(ADM_USER, post(adm_create_users)); // needed if user self registration disabled

    let ap_router = Router::new()
        .route(AP_PLATFORM, post(ap_create_platform).get(ap_get_platforms))
        .route(
            AP_ACTION_PROVIDER,
            post(ap_create_action_provider).get(ap_get_action_provider),
        )
        .route(
            AP_ACTION,
            post(ap_create_actions)
                .get(ap_get_actions)
                .put(ap_update_actions),
        )
        .route(AP_ACTION_EVENT, delete(ap_disable_action_events))
        .route(
            AP_EXECUTABLE_ACTION_EVENT,
            get(ap_get_executable_action_events),
        );

    let user_router = Router::new()
        .route(APP_INFO, get(get_app_info))
        .route(APP_DOWNLOAD, get(download_app))
        .route(ACCOUNT_DATA, get(get_account_data))
        .route(
            USER,
            post(create_user)
                .get(get_user)
                .put(update_user)
                .delete(delete_user),
        )
        .route(PLATFORM, get(get_platforms))
        .route(
            PLATFORM_CREDENTIAL,
            post(create_platform_credentials)
                .get(get_platform_credentials)
                .put(update_platform_credentials),
        )
        .route(ACTION_PROVIDER, get(get_action_providers))
        .route(ACTION, get(get_actions))
        .route(
            ACTION_RULE,
            post(create_action_rules)
                .get(get_action_rules)
                .put(update_action_rules),
        )
        .route(
            ACTION_EVENT,
            post(create_action_events)
                .get(get_action_events)
                .put(update_action_events),
        )
        .route(
            STRENGTH_SESSION,
            post(create_strength_sessions)
                .get(get_strength_sessions)
                .put(update_strength_sessions),
        )
        .route(
            STRENGTH_SET,
            post(create_strength_sets)
                .get(get_strength_sets)
                .put(update_strength_sets),
        )
        .route(EORM, get(get_eorms))
        .route(
            METCON_SESSION,
            post(create_metcon_sessions)
                .get(get_metcon_sessions)
                .put(update_metcon_sessions),
        )
        .route(
            METCON,
            post(create_metcons).get(get_metcons).put(update_metcons),
        )
        .route(
            METCON_MOVEMENT,
            post(create_metcon_movements)
                .get(get_metcon_movements)
                .put(update_metcon_movements),
        )
        .route(
            CARDIO_SESSION,
            post(create_cardio_sessions)
                .get(get_cardio_sessions)
                .put(update_cardio_sessions),
        )
        .route(
            ROUTE,
            post(create_routes).get(get_routes).put(update_routes),
        )
        .route(
            DIARY,
            post(create_diaries).get(get_diaries).put(update_diaries),
        )
        .route(WOD, post(create_wods).get(get_wods).put(update_wods))
        .route(
            MOVEMENT,
            post(create_movements)
                .get(get_movements)
                .put(update_movements),
        );

    let trace_layer = ServiceBuilder::new()
        .layer(SetSensitiveRequestHeadersLayer::new(iter::once(
            AUTHORIZATION,
        )))
        .layer(
            TraceLayer::new_for_http()
                .make_span_with(|request: &Request<Body>| {
                    tracing::error_span!(
                        "",
                        method = %request.method(),
                        uri = %request.uri(),
                    )
                })
                .on_request(|request: &Request<Body>, _span: &Span| {
                    debug!("request\n{:#?}", request.headers());
                })
                .on_response(
                    |response: &Response<CompressionBody<Body>>,
                     _latency: Duration,
                     _span: &Span| {
                        debug!("response {}\n{:#?}", response.status(), response.headers());
                    },
                )
                .on_body_chunk(|chunk: &Bytes, _latency: Duration, _span: &Span| {
                    trace!("response body\n{:?}", chunk);
                })
                .on_failure(
                    |error: ServerErrorsFailureClass, _latency: Duration, _span: &Span| match error
                    {
                        ServerErrorsFailureClass::StatusCode(status) => {
                            warn!("{status}");
                        }
                        ServerErrorsFailureClass::Error(error) => {
                            warn!("an error occurred: {error}");
                        }
                    },
                ),
        );

    Router::new()
        .route(VERSION, get(get_version))
        .nest(
            &format!("/v{MAX_VERSION}"),
            Router::new()
                .merge(admin_router)
                .merge(ap_router)
                .merge(user_router),
        )
        .fallback(handler_not_found)
        .layer(
            ServiceBuilder::new()
                .layer(trace_layer)
                .layer(DefaultBodyLimit::max(100 * 1024 * 1024))
                .layer(CompressionLayer::new()),
        )
        .with_state(state)
}
