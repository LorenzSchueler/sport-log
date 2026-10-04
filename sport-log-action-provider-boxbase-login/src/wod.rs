//! Client for the GentleGiants wod website.

use std::collections::HashMap;

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

/// Fetches the wods of all classes for `date` and returns them as map from class name to wod
/// description.
///
/// The class name is empty for the regular group class, otherwise the name of the special class.
pub async fn fetch_wod(
    username: &str,
    password: &str,
    date: NaiveDate,
) -> Result<HashMap<String, String>> {
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
        .map(|day| format_wods(&day.sections))
        .unwrap_or_default())
}

/// Formats the wod of each class from its sections and returns them as map from class name to
/// wod description.
fn format_wods(sections: &[WodSection]) -> HashMap<String, String> {
    let mut wods: HashMap<String, Vec<String>> = HashMap::new();
    for section in sections {
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
        let section_description = (!header.is_empty())
            .then_some(header)
            .into_iter()
            .chain(lines)
            .collect::<Vec<_>>()
            .join("\n");
        wods.entry(section.class.clone())
            .or_default()
            .push(section_description);
    }

    wods.into_iter()
        .map(|(class, sections)| (class, sections.join("\n\n")))
        .collect()
}

#[cfg(test)]
mod tests {
    use rstest::rstest;

    use super::*;

    #[rstest]
    #[case::group_and_special_class(
        r#"[
            {"label":"A","title":"Warm up","lines":[{"t":"2 Sets:","k":"text"},{"t":"10 Snatch","k":"item"},{"t":"+","k":"text"},{"t":"Rest 60 sec","k":"note"}],"g":"warmup","c":""},
            {"label":"","title":"Gymnastics class","lines":[{"t":"Warm-up","k":"text"}],"g":"gymnastics","c":"Gymnastics"},
            {"label":"","title":"Partner","lines":[{"t":"1. 3-5 HSPU","k":"num"}],"g":"team","c":""}
        ]"#,
        &[
            ("", "A: Warm up\n2 Sets:\n- 10 Snatch\n+\nRest 60 sec\n\nPartner\n1. 3-5 HSPU"),
            ("Gymnastics", "Gymnastics class\nWarm-up"),
        ]
    )]
    #[case::label_without_title(
        r#"[{"label":"B","title":"","lines":[{"t":"Backsquat","k":"text"}],"c":""}]"#,
        &[("", "B\nBacksquat")]
    )]
    #[case::without_header(
        r#"[{"label":"","title":"","lines":[{"t":"Backsquat","k":"text"}],"c":""}]"#,
        &[("", "Backsquat")]
    )]
    #[case::no_sections("[]", &[])]
    fn format_wods_formats_sections_by_class(
        #[case] sections: &str,
        #[case] wods: &[(&str, &str)],
    ) {
        let sections: Vec<WodSection> = serde_json::from_str(sections).unwrap();
        let wods: HashMap<_, _> = wods
            .iter()
            .map(|(class, wod)| ((*class).to_owned(), (*wod).to_owned()))
            .collect();

        assert_eq!(wods, format_wods(&sections));
    }
}
