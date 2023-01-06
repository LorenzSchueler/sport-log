use std::sync::Arc;

use axum::{
    extract::{Query, State},
    http::StatusCode,
    Json,
};
use sport_log_types::{
    Action, ActionEvent, ActionEventId, ActionId, ActionProvider, ActionProviderId, ActionRule,
    ActionRuleId, AuthAP, AuthAdmin, AuthUser, Config, CreatableActionRule, Create, DbConn,
    DeletableActionEvent, ExecutableActionEvent, GetAll, GetById, GetByUser, Unverified,
    UnverifiedId, UnverifiedIds, Update, VerifyForActionProviderWithoutDb, VerifyForAdminWithoutDb,
    VerifyForUserWithDb, VerifyForUserWithoutDb, VerifyIdForActionProvider, VerifyIdForAdmin,
    VerifyIdForUser, VerifyIdUnchecked, VerifyIdsForActionProvider, VerifyIdsForAdmin,
    VerifyMultipleForActionProviderWithoutDb, VerifyMultipleForAdminWithoutDb,
    VerifyMultipleForUserWithDb, VerifyMultipleForUserWithoutDb, VerifyUnchecked,
};

use crate::handler::{
    ErrorMessage, HandlerError, HandlerResult, IdOption, TimeSpanOption, UnverifiedSingleOrVec,
};

pub async fn adm_create_action_providers(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(action_providers): Json<UnverifiedSingleOrVec<ActionProvider>>,
) -> HandlerResult<StatusCode> {
    match action_providers {
        UnverifiedSingleOrVec::Single(action_provider) => {
            let action_provider = action_provider.verify_adm(auth)?;
            ActionProvider::create(action_provider, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_providers) => {
            let action_providers = action_providers.verify_adm(auth)?;
            ActionProvider::create_multiple(action_providers, &mut db)
        }
    }
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn ap_create_action_provider(
    State(config): State<Arc<Config>>,
    mut db: DbConn,
    Json(action_provider): Json<Unverified<ActionProvider>>,
) -> HandlerResult<StatusCode> {
    if !config.ap_self_registration {
        return Err(HandlerError {
            status: StatusCode::FORBIDDEN,
            message: Some(ErrorMessage::Other {
                error: "action provider self registration is disabled".to_owned(),
            }),
        });
    }

    let action_provider = action_provider.verify_unchecked()?;
    ActionProvider::create(action_provider, &mut db)
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
            ActionProvider::get_by_id(action_provider_id, &mut db).map(|a| vec![a])
        }
        None => ActionProvider::get_all(&mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn ap_get_action_provider(
    auth: AuthAP,
    mut db: DbConn,
) -> HandlerResult<Json<ActionProvider>> {
    ActionProvider::get_by_id(*auth, &mut db)
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
            ActionProvider::get_by_id(action_provider_id, &mut db).map(|a| vec![a])
        }
        None => ActionProvider::get_all(&mut db),
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
            Action::create(action, &mut db)
        }
        UnverifiedSingleOrVec::Vec(actions) => {
            let actions = actions.verify_ap_without_db(auth)?;
            Action::create_multiple(actions, &mut db)
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
            let action_id = id.verify_ap(auth, &mut db)?;
            Action::get_by_id(action_id, &mut db).map(|a| vec![a])
        }
        None => Action::get_by_action_provider(*auth, &mut db),
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
            Action::get_by_id(action_id, &mut db).map(|a| vec![a])
        }
        None => Action::get_all(&mut db),
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
            ActionRule::create(action_rule, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_rules) => {
            let action_rules = action_rules.verify_user_without_db(auth)?;
            ActionRule::create_multiple(action_rules, &mut db)
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
            let action_rule_id = id.verify_user(auth, &mut db)?;
            ActionRule::get_by_id(action_rule_id, &mut db).map(|a| vec![a])
        }
        None => ActionRule::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

//#[get("/action_rule/action_provider/<action_provider_id>")]
//pub async fn get_action_rules_by_action_provider(
//auth: AuthUser,
//Path(action_provider_id): Path<UnverifiedId<ActionProviderId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<ActionRule>>> {
//
//let action_provider_id = action_provider_id.verify_unchecked().map_err(Error::from)?;
//ActionRule::get_by_user_and_action_provider(*auth, action_provider_id, &mut db)
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
            ActionRule::update(action_rule, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_rules) => {
            let action_rules = action_rules.verify_user(auth, &mut db)?;
            ActionRule::update_multiple(action_rules, &mut db)
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
            ActionEvent::create(action_event, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_user_without_db(auth)?;
            ActionEvent::create_multiple(action_events, &mut db)
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
            ActionEvent::create(action_event, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_adm(auth)?;
            ActionEvent::create_multiple_ignore_conflict(action_events, &mut db)
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
            let action_event_id = id.verify_user(auth, &mut db)?;
            ActionEvent::get_by_id(action_event_id, &mut db).map(|a| vec![a])
        }
        None => ActionEvent::get_by_user(*auth, &mut db),
    }
    .map(Json)
    .map_err(Into::into)
}

//#[get("/action_event/action_provider/<action_provider_id>")]
//pub async fn get_action_events_by_action_provider(
//auth: AuthUser,
//Path(action_provider_id): Path<UnverifiedId<ActionProviderId>>,
//mut db: DbConn,
//) -> HandlerResult<Json<Vec<ActionEvent>>> {
//
//let action_provider_id = action_provider_id.verify_unchecked().map_err(Error::from)?;
//ActionEvent::get_by_user_and_action_provider(*auth, action_provider_id, &mut db)
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
            let action_event = action_event.verify_user(auth, &mut db)?;
            ActionEvent::update(action_event, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_user(auth, &mut db)?;
            ActionEvent::update_multiple(action_events, &mut db)
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
            ActionEvent::update(action_event, &mut db)
        }
        UnverifiedSingleOrVec::Vec(action_events) => {
            let action_events = action_events.verify_adm(auth)?;
            ActionEvent::update_multiple(action_events, &mut db)
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
    ActionEvent::disable_multiple(
        ids.verify_ap(auth, &mut db)
            .map_err(|status| HandlerError {
                status,
                message: None,
            })?,
        &mut db,
    )
    .map(|_| StatusCode::OK)
    .map_err(Into::into)
}

pub async fn adm_delete_action_events(
    auth: AuthAdmin,
    mut db: DbConn,
    Json(ids): Json<UnverifiedIds<ActionEventId>>,
) -> HandlerResult<StatusCode> {
    ActionEvent::delete_multiple(ids.verify_adm(auth)?, &mut db)
        .map(|_| StatusCode::OK)
        .map_err(Into::into)
}

pub async fn adm_get_creatable_action_rules(
    _auth: AuthAdmin,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<CreatableActionRule>>> {
    CreatableActionRule::get_all(&mut db)
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
            ExecutableActionEvent::get_ordered_by_action_provider_and_timespan(
                *auth, start, end, &mut db,
            )
        }
        (None, None) => ExecutableActionEvent::get_by_action_provider(*auth, &mut db),
        _ => {
            return Err(HandlerError {
                status: StatusCode::BAD_REQUEST,
                message: Some(ErrorMessage::Other {
                    error: "'start' and 'end' must be either specified both or neither of them"
                        .to_owned(),
                }),
            })
        }
    }
    .map(Json)
    .map_err(Into::into)
}

pub async fn adm_get_deletable_action_events(
    _auth: AuthAdmin,
    mut db: DbConn,
) -> HandlerResult<Json<Vec<DeletableActionEvent>>> {
    DeletableActionEvent::get_all(&mut db)
        .map(Json)
        .map_err(Into::into)
}
