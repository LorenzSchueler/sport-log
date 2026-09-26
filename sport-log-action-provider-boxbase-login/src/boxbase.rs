//! Client for the JSON endpoints of the BoxBase web app.

use std::sync::Arc;

use chrono::{DateTime, NaiveDate, Utc};
use percent_encoding::percent_decode_str;
use reqwest::{
    Client, Method, RequestBuilder, StatusCode, Url,
    cookie::{CookieStore, Jar},
    header::{ACCEPT, LOCATION},
    redirect::Policy,
};
use serde::Deserialize;
use serde_json::Value;

use crate::{Error, Result, UserError, UserResult};

const URL: &str = "https://admin.boxbase.app";
const INVALID_CREDENTIALS_MESSAGE: &str = "These credentials do not match our records.";

/// The status of the registration of the user for a class.
#[derive(Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[serde(tag = "status", rename_all = "snake_case")]
pub enum RegistrationStatus {
    Registered,
    WaitingList,
    /// Cancelled or any other status.
    #[serde(other)]
    Other,
}

/// The id of a class, or the id of its template if the class does not exist yet.
#[derive(Deserialize, Debug, Clone, Copy, PartialEq, Eq)]
#[serde(try_from = "RawClassId")]
pub enum ClassId {
    Id(i64),
    TemplateId(i64),
}

/// The id fields of a class as returned by BoxBase.
#[derive(Deserialize)]
struct RawClassId {
    id: Option<i64>,
    class_unit_template_id: Option<i64>,
}

impl TryFrom<RawClassId> for ClassId {
    type Error = &'static str;

    fn try_from(raw: RawClassId) -> std::result::Result<Self, Self::Error> {
        match (raw.id, raw.class_unit_template_id) {
            (Some(id), _) => Ok(Self::Id(id)),
            (None, Some(template_id)) => Ok(Self::TemplateId(template_id)),
            (None, None) => Err("class has neither id nor template id"),
        }
    }
}

/// A class at a date.
#[derive(Deserialize, Debug)]
pub struct Class {
    #[serde(flatten)]
    pub id: ClassId,
    /// The local date as UTC midnight (`2026-09-28T00:00:00.000000Z`), so `date_naive` is the
    /// local date.
    pub date: DateTime<Utc>,
    pub name: String,
    /// The local start time as `HH:MM`.
    pub starts_at: String,
    /// `None` if the user never registered.
    #[serde(rename = "current_user_registration")]
    pub registration_status: Option<RegistrationStatus>,
}

impl Class {
    /// Whether the user is registered or on the waiting list.
    pub fn is_reserved(&self) -> bool {
        matches!(
            self.registration_status,
            Some(RegistrationStatus::Registered | RegistrationStatus::WaitingList)
        )
    }

    /// Returns the path segment that identifies the class in the API.
    fn path(&self) -> String {
        match self.id {
            ClassId::Id(id) => id.to_string(),
            ClassId::TemplateId(template_id) => format!("{template_id}/{}", self.date.date_naive()),
        }
    }
}

/// The wrapper of the data in API responses.
#[derive(Deserialize, Debug)]
struct Data<T> {
    data: T,
}

/// A membership of the user.
#[derive(Deserialize, Debug)]
struct Membership {
    id: i64,
}

/// A logged in BoxBase session.
pub struct BoxBase {
    client: Client,
    jar: Arc<Jar>,
    user_uuid: String,
}

impl BoxBase {
    /// Logs in with `username` and `password`.
    pub async fn login(username: &str, password: &str) -> Result<UserResult<Self>> {
        let jar = Arc::new(Jar::default());
        let client = Client::builder()
            .cookie_provider(jar.clone())
            .redirect(Policy::none())
            .build()?;

        client
            .get(format!("{URL}/login"))
            .send()
            .await?
            .error_for_status()?;
        let response = client
            .post(format!("{URL}/login"))
            .header("X-XSRF-TOKEN", xsrf_token(&jar))
            .form(&[("email", username), ("password", password)])
            .send()
            .await?;
        // BoxBase redirects with an absolute URL to `/dashboard` or, on failure, to `/login`.
        let location = response
            .headers()
            .get(LOCATION)
            .and_then(|location| location.to_str().ok())
            .and_then(|location| location.strip_prefix(URL));
        match location {
            Some("/dashboard") => {}
            Some("/login") => {
                let page = page_data(&client, "login").await?;
                let error = page.pointer("/props/errors/email").and_then(Value::as_str);
                if error == Some(INVALID_CREDENTIALS_MESSAGE) {
                    return Ok(Err(UserError::InvalidCredential));
                }
                return Err(Error::UnexpectedResponse(format!(
                    "login failed with error {error:?}"
                )));
            }
            location => {
                return Err(Error::UnexpectedResponse(format!(
                    "login responded with status {} and location {location:?}",
                    response.status()
                )));
            }
        }

        let page = page_data(&client, "classes").await?;
        let user_uuid = page
            .pointer("/props/auth/user/uuid")
            .and_then(Value::as_str)
            .ok_or_else(|| Error::UnexpectedResponse("user uuid not found".to_owned()))?
            .to_owned();

        Ok(Ok(Self {
            client,
            jar,
            user_uuid,
        }))
    }

    /// Returns the classes at `date`.
    pub async fn classes(&self, date: NaiveDate) -> Result<Vec<Class>> {
        let classes: Data<Vec<Class>> = self
            .api_request(
                Method::GET,
                &format!("box/classes?dateFrom={date}&dateTo={date}"),
            )
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?;

        Ok(classes.data)
    }

    /// Registers for `class`.
    pub async fn register(&self, class: &Class) -> Result<()> {
        let class_path = class.path();

        let memberships: Data<Vec<Membership>> = self
            .api_request(
                Method::GET,
                &format!(
                    "user/{}/registration-memberships/{class_path}",
                    self.user_uuid
                ),
            )
            .send()
            .await?
            .error_for_status()?
            .json()
            .await?;
        let membership = memberships
            .data
            .first()
            .map(|membership| format!("/{}", membership.id))
            .unwrap_or_default();

        self.api_request(
            Method::POST,
            &format!("schedule/classes/{class_path}/register{membership}"),
        )
        .send()
        .await?
        .error_for_status()?;

        Ok(())
    }

    /// Builds a request to the API endpoint at `path`.
    ///
    /// Without a valid session the API responds with 401, not with a redirect.
    fn api_request(&self, method: Method, path: &str) -> RequestBuilder {
        self.client
            .request(method, format!("{URL}/api/{path}"))
            .header(ACCEPT, "application/json")
            .header("X-XSRF-TOKEN", xsrf_token(&self.jar))
    }
}

/// Returns the Inertia page data embedded in the html of the page at `path`.
async fn page_data(client: &Client, path: &str) -> Result<Value> {
    let response = client.get(format!("{URL}/{path}")).send().await?;
    if response.status() != StatusCode::OK {
        return Err(Error::UnexpectedResponse(format!(
            "{path} responded with status {}",
            response.status()
        )));
    }

    parse_page_data(&response.text().await?)
}

/// Extracts the Inertia page data from the html of a page.
///
/// The data is unescaped JSON in `<script data-page="app">`, not a `data-page` attribute.
fn parse_page_data(html: &str) -> Result<Value> {
    let page_data = html
        .find(r#"data-page="app""#)
        .and_then(|tag| html[tag..].find('>').map(|end| tag + end + 1))
        .and_then(|start| {
            html[start..]
                .find("</script>")
                .map(|end| &html[start..start + end])
        })
        .ok_or_else(|| Error::UnexpectedResponse("page data not found".to_owned()))?;

    Ok(serde_json::from_str(page_data)?)
}

/// Returns the decoded `XSRF-TOKEN` cookie or an empty string if there is none.
fn xsrf_token(jar: &Jar) -> String {
    jar.cookies(&Url::parse(URL).unwrap())
        .and_then(|cookies| {
            cookies.to_str().ok().and_then(|cookies| {
                cookies
                    .split("; ")
                    .find_map(|cookie| cookie.strip_prefix("XSRF-TOKEN="))
                    .map(|token| percent_decode_str(token).decode_utf8_lossy().into_owned())
            })
        })
        .unwrap_or_default()
}

#[cfg(test)]
mod tests {
    use rstest::rstest;
    use serde_json::json;

    use super::*;

    #[rstest]
    #[case(r#"{"id":1,"class_unit_template_id":2}"#, Some(ClassId::Id(1)))]
    #[case(r#"{"id":1,"class_unit_template_id":null}"#, Some(ClassId::Id(1)))]
    #[case(
        r#"{"id":null,"class_unit_template_id":2}"#,
        Some(ClassId::TemplateId(2))
    )]
    #[case(r#"{"id":null,"class_unit_template_id":null}"#, None)]
    fn class_id_deserializes(#[case] json: &str, #[case] id: Option<ClassId>) {
        assert_eq!(id, serde_json::from_str(json).ok());
    }

    #[rstest]
    #[case(
        r#"<html><script data-page="app" type="application/json">{"props":{"a":1}}</script></html>"#,
        Some(json!({"props":{"a":1}}))
    )]
    #[case("<html></html>", None)]
    #[case(r#"<script data-page="app">{"a":1}"#, None)]
    fn parse_page_data_extracts_json(#[case] html: &str, #[case] page: Option<Value>) {
        assert_eq!(page, parse_page_data(html).ok());
    }

    #[test]
    fn xsrf_token_decodes_cookie() {
        let jar = Jar::default();
        assert_eq!("", xsrf_token(&jar));

        let url = Url::parse(URL).unwrap();
        jar.add_cookie_str("boxbase_session=session; Path=/", &url);
        jar.add_cookie_str("XSRF-TOKEN=a%3Db%3D%3D; Path=/", &url);

        assert_eq!("a=b==", xsrf_token(&jar));
    }
}
