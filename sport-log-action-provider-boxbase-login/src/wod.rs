//! Client for the GentleGiants wod website.

use chrono::NaiveDate;
use reqwest::{
    Client, StatusCode,
    header::{LOCATION, ORIGIN},
    redirect::Policy,
};
use serde::Deserialize;

use crate::{Error, Result};

const URL: &str = "https://gentle-giants.at";
const USER_AGENT: &str = "Mozilla/5.0 (X11; Linux x86_64; rv:130.0) Gecko/20100101 Firefox/130.0";

#[derive(Deserialize, Debug)]
struct WodResponse {
    week: WodWeek,
}

#[derive(Deserialize, Debug)]
struct WodWeek {
    days: Vec<WodDay>,
}

#[derive(Deserialize, Debug)]
struct WodDay {
    date: NaiveDate,
    sections: Vec<WodSection>,
}

#[derive(Deserialize, Debug)]
struct WodSection {
    label: String,
    title: String,
    lines: Vec<WodLine>,
    /// Empty for the regular group class, otherwise the name of the special class.
    #[serde(rename = "c")]
    class: String,
}

#[derive(Deserialize, Debug)]
struct WodLine {
    #[serde(rename = "t")]
    text: String,
    #[serde(rename = "k")]
    kind: String,
}

/// Fetches the group class wod for `date`.
pub async fn fetch_wod(username: &str, password: &str, date: NaiveDate) -> Result<Option<String>> {
    let client = Client::builder()
        .cookie_store(true)
        .redirect(Policy::none())
        .user_agent(USER_AGENT)
        .build()?;

    let response = client
        .post(format!("{URL}/wod/login.php"))
        .header(ORIGIN, URL)
        .form(&[("user", username), ("password", password)])
        .send()
        .await?;
    let location = response
        .headers()
        .get(LOCATION)
        .and_then(|location| location.to_str().ok());
    if response.status() != StatusCode::SEE_OTHER || location != Some("/wod/") {
        return Err(Error::UnexpectedResponse(format!(
            "wod login responded with status {} and location {location:?}",
            response.status()
        )));
    }

    let wod: WodResponse = client
        .get(format!("{URL}/wod/data.php"))
        .send()
        .await?
        .error_for_status()?
        .json()
        .await?;

    Ok(wod
        .week
        .days
        .into_iter()
        .find(|day| day.date == date)
        .and_then(|day| format_wod(&day.sections)))
}

/// Formats the sections of the group class as wod description.
fn format_wod(sections: &[WodSection]) -> Option<String> {
    let sections: Vec<_> = sections
        .iter()
        .filter(|section| section.class.is_empty())
        .map(|section| {
            let header = match (section.label.as_str(), section.title.as_str()) {
                ("", title) => title.to_owned(),
                (label, "") => label.to_owned(),
                (label, title) => format!("{label}: {title}"),
            };
            let lines = section.lines.iter().map(|line| {
                if line.kind == "item" {
                    format!("- {}", line.text)
                } else {
                    line.text.clone()
                }
            });
            (!header.is_empty())
                .then_some(header)
                .into_iter()
                .chain(lines)
                .collect::<Vec<_>>()
                .join("\n")
        })
        .collect();

    (!sections.is_empty()).then(|| sections.join("\n\n"))
}

#[cfg(test)]
mod tests {
    use rstest::rstest;

    use super::*;

    #[rstest]
    #[case::group_and_special_class_sections(
        r#"[
            {"label":"A","title":"Warm up","lines":[{"t":"2 Sets:","k":"text"},{"t":"10 Snatch","k":"item"},{"t":"+","k":"text"},{"t":"Rest 60 sec","k":"note"}],"g":"warmup","c":""},
            {"label":"","title":"Gymnastics class","lines":[{"t":"Warm-up","k":"text"}],"g":"gymnastics","c":"Gymnastics"},
            {"label":"","title":"Partner","lines":[{"t":"1. 3-5 HSPU","k":"num"}],"g":"team","c":""}
        ]"#,
        Some("A: Warm up\n2 Sets:\n- 10 Snatch\n+\nRest 60 sec\n\nPartner\n1. 3-5 HSPU")
    )]
    #[case::label_without_title(
        r#"[{"label":"B","title":"","lines":[{"t":"Backsquat","k":"text"}],"c":""}]"#,
        Some("B\nBacksquat")
    )]
    #[case::without_header(
        r#"[{"label":"","title":"","lines":[{"t":"Backsquat","k":"text"}],"c":""}]"#,
        Some("Backsquat")
    )]
    #[case::only_special_class(
        r#"[{"label":"","title":"Gymnastics class","lines":[],"c":"Gymnastics"}]"#,
        None
    )]
    fn format_wod_formats_group_class_sections(
        #[case] sections: &str,
        #[case] description: Option<&str>,
    ) {
        let sections: Vec<WodSection> = serde_json::from_str(sections).unwrap();

        assert_eq!(description, format_wod(&sections).as_deref());
    }
}
