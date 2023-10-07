use axum::{
    extract::{Query, State},
    http::StatusCode,
    Json,
};
use sport_log_types::{
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, ActionRule,
    ActionRuleId, CreatableActionRule, DeletableActionEvent, ExecutableActionEvent,
};

use crate::{
    auth::*,
    config::Config,
    db::*,
    handler::{
        check_password, ErrorMessage, HandlerError, HandlerResult, IdOption, TimeSpanOption,
        UnverifiedSingleOrVec,
    },
    state::DbConn,
};

pub async fn adm_create_action_providers(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(action_providers): Json<UnverifiedSingleOrVec<ActionProvider>>,
) -> HandlerResult<StatusCode> {
    match action_providers {
        UnverifiedSingleOrVec::Single(action_provider) => {
            let mut action_provider = action_provider.verify_adm(auth)?;
            check_password(&action_provider.password)?;
            ActionProviderDb::create(&mut action_provider, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_providers) => {
            let mut action_providers = action_providers.verify_adm(auth)?;
            for action_provider in &action_providers {
                check_password(&action_provider.password)?;
            }
            ActionProviderDb::create_multiple(&mut action_providers, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn ap_create_action_provider(
    State(config): State<&Config>,
    mut db: DbConn,
    Json(action_provider): Json<Unverified<ActionProvider>>,
) -> HandlerResult<StatusCode> {
    if !config.ap_self_registration {
        return Err(HandlerError::from((
            StatusCode::FORBIDDEN,
            ErrorMessage::Other {
                error: "action provider self registration is disabled".to_owned(),
            },
        )));
    }

    let mut action_provider = action_provider.verify_unchecked()?;
    check_password(&action_provider.password)?;
    ActionProviderDb::create(&mut action_provider, &mut db)
        .await
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn adm_get_action_providers(
    auth: AuthAdmin,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<ActionProviderId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<ActionProvider>>> {
    match id {
        Some(id) => {
            let action_provider_id = id.verify_adm(auth)?;
            ActionProviderDb::get_by_id(action_provider_id, &mut db)
                .await
                .map(|a| vec![a])
        }
        None => ActionProviderDb::get_all(&mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn ap_get_action_provider(
    auth: AuthAP,
    mut db: DbConn,
) -> HandlerResult<Json<ActionProvider>> {
    ActionProviderDb::get_by_id(*auth, &mut db)
        .await
        .map(Json)
        .map_err(Into::into)
}

pub async fn get_action_providers(
    _auth: AuthUser,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<ActionProviderId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<ActionProvider>>> {
    match id {
        Some(id) => {
            let action_provider_id = id.verify_unchecked()?;
            ActionProviderDb::get_by_id(action_provider_id, &mut db)
                .await
                .map(|a| vec![a])
        }
        None => ActionProviderDb::get_all(&mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn ap_create_actions(
    auth: AuthAP,
    mut db: DbConn,
    Json(actions): Json<UnverifiedSingleOrVec<Action>>,
) -> HandlerResult<StatusCode> {
    match actions {
        UnverifiedSingleOrVec::Single(action) => {
            let action = action.verify_ap_without_db(auth)?;
            ActionDb::create(&action, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(actions) => {
            let actions = actions.verify_ap_without_db(auth)?;
            ActionDb::create_multiple(&actions, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn ap_get_actions(
    auth: AuthAP,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<ActionId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Action>>> {
    match id {
        Some(id) => {
            let action_id = id.verify_ap(auth, &mut db).await?;
            ActionDb::get_by_id(action_id, &mut db)
                .await
                .map(|a| vec![a])
        }
        None => ActionDb::get_by_action_provider(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn get_actions(
    _auth: AuthUser,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<ActionId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<Action>>> {
    match id {
        Some(id) => {
            let action_id = id.verify_unchecked()?;
            ActionDb::get_by_id(action_id, &mut db)
                .await
                .map(|a| vec![a])
        }
        None => ActionDb::get_all(&mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn create_action_rules(
    auth: AuthUser,
    mut db: DbConn,
    Json(action_rules): Json<UnverifiedSingleOrVec<ActionRule>>,
) -> HandlerResult<StatusCode> {
    match action_rules {
        UnverifiedSingleOrVec::Single(action_rule) => {
            let action_rule = action_rule.verify_user_without_db(auth)?;
            ActionRuleDb::create(&action_rule, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_rules) => {
            let action_rules = action_rules.verify_user_without_db(auth)?;
            ActionRuleDb::create_multiple(&action_rules, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_action_rules(
    auth: AuthUser,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<ActionRuleId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<ActionRule>>> {
    match id {
        Some(id) => {
            let action_rule_id = id.verify_user(auth, &mut db).await?;
            ActionRuleDb::get_by_id(action_rule_id, &mut db)
                .await
                .map(|a| vec![a])
        }
        None => ActionRuleDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

//pub async fn get_action_rules_by_action_provider(
//auth: AuthUser,
//Path(action_provider_id): Path<UnverifiedId<ActionProviderId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<ActionRule>>> {
//
//let action_provider_id = action_provider_id.verify_unchecked().map_err(Error::from)?;
//ActionRuleDb::get_by_user_and_action_provider(*auth, action_provider_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_action_rules(
    auth: AuthUser,
    mut db: DbConn,
    Json(action_rules): Json<UnverifiedSingleOrVec<ActionRule>>,
) -> HandlerResult<StatusCode> {
    match action_rules {
        UnverifiedSingleOrVec::Single(action_rule) => {
            let action_rule = action_rule.verify_user_without_db(auth)?;
            ActionRuleDb::update(&action_rule, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_rules) => {
            let action_rules = action_rules.verify_user(auth, &mut db).await?;
            ActionRuleDb::update_multiple(&action_rules, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn create_action_events(
    auth: AuthUser,
    mut db: DbConn,
    Json(action_events): Json<UnverifiedSingleOrVec<ActionEvent>>,
) -> HandlerResult<StatusCode> {
    match action_events {
        UnverifiedSingleOrVec::Single(action_event) => {
            let action_event = action_event.verify_user_without_db(auth)?;
            ActionEventDb::create(&action_event, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_user_without_db(auth)?;
            ActionEventDb::create_multiple(&action_events, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn adm_create_action_events(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(action_events): Json<UnverifiedSingleOrVec<ActionEvent>>,
) -> HandlerResult<StatusCode> {
    match action_events {
        UnverifiedSingleOrVec::Single(action_event) => {
            let action_event = action_event.verify_adm(auth)?;
            ActionEventDb::create(&action_event, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_adm(auth)?;
            ActionEventDb::create_multiple_ignore_conflict(action_events, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn get_action_events(
    auth: AuthUser,
    Query(IdOption { id }): Query<IdOption<UnverifiedId<ActionEventId>>>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<ActionEvent>>> {
    match id {
        Some(id) => {
            let action_event_id = id.verify_user(auth, &mut db).await?;
            ActionEventDb::get_by_id(action_event_id, &mut db)
                .await
                .map(|a| vec![a])
        }
        None => ActionEventDb::get_by_user(*auth, &mut db).await,
    }
    .map(Json)
    .map_err(Into::into)
}

//pub async fn get_action_events_by_action_provider(
//auth: AuthUser,
//Path(action_provider_id): Path<UnverifiedId<ActionProviderId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<ActionEvent>>> {
//
//let action_provider_id = action_provider_id.verify_unchecked().map_err(Error::from)?;
//ActionEventDb::get_by_user_and_action_provider(*auth, action_provider_id, &mut db)
//.map(Json)
//.map_err(Into::into)
//}

pub async fn update_action_events(
    auth: AuthUser,
    mut db: DbConn,
    Json(action_events): Json<UnverifiedSingleOrVec<ActionEvent>>,
) -> HandlerResult<StatusCode> {
    match action_events {
        UnverifiedSingleOrVec::Single(action_event) => {
            let action_event = action_event.verify_user(auth, &mut db).await?;
            ActionEventDb::update(&action_event, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_user(auth, &mut db).await?;
            ActionEventDb::update_multiple(&action_events, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn adm_update_action_events(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(action_events): Json<UnverifiedSingleOrVec<ActionEvent>>,
) -> HandlerResult<StatusCode> {
    match action_events {
        UnverifiedSingleOrVec::Single(action_event) => {
            let action_event = action_event.verify_adm(auth)?;
            ActionEventDb::update(&action_event, &mut db).await
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_adm(auth)?;
            ActionEventDb::update_multiple(&action_events, &mut db).await
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn ap_disable_action_events(
    auth: AuthAP,
    mut db: DbConn,
    Json(ids): Json<UnverifiedIds<ActionEventId>>,
) -> HandlerResult<StatusCode> {
    ActionEventDb::disable_multiple(
        ids.verify_ap(auth, &mut db)
            .await
            .map_err(HandlerError::from)?,
        &mut db,
    )
    .await
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn adm_delete_action_events(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(ids): Json<UnverifiedIds<ActionEventId>>,
) -> HandlerResult<StatusCode> {
    ActionEventDb::delete_multiple(ids.verify_adm(auth)?, &mut db)
        .await
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn adm_get_creatable_action_rules(
    _auth: AuthAdmin,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<CreatableActionRule>>> {
    CreatableActionRuleDb::get_all(&mut db)
        .await
        .map(Json)
        .map_err(Into::into)
}

pub async fn ap_get_executable_action_events(
    auth: AuthAP,
    Query(TimeSpanOption { start, end }): Query<TimeSpanOption>,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<ExecutableActionEvent>>> {
    match (start, end) {
        (Some(start), Some(end)) => {
            ExecutableActionEventDb::get_ordered_by_action_provider_and_timespan(
                *auth, start, end, &mut db,
            )
            .await
        }
        (None, None) => ExecutableActionEventDb::get_by_action_provider(*auth, &mut db).await,
        _ => {
            return Err(HandlerError::from((
                StatusCode::BAD_REQUEST,
                ErrorMessage::Other {
                    error: "'start' and 'end' must be specified either both or not at all"
                        .to_owned(),
                },
            )))
        }
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn adm_get_deletable_action_events(
    _auth: AuthAdmin,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<DeletableActionEvent>>> {
    DeletableActionEventDb::get_all(&mut db)
        .await
        .map(Json)
        .map_err(Into::into)
}
