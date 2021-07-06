use std::env::{self, Args};

use reqwest::blocking::Client;
use serde_json::Value;

fn main() {
    let args = env::args();

    if let Err(()) = handle(args) {
        println!(
            "sport-log-api-tester <method> <endpoint> <credentials> <data>\n\n\
            makes as <method> request to http://localhost:8000<endpoint> \n\
            credentials (http basic auth) and data are optionally"
        );
    }
}

fn handle(args: Args) -> Result<(), ()> {
    let args: Vec<_> = args.collect();
    let method = args.get(1).ok_or(())?;
    let endpoint = args.get(2).ok_or(())?;
    let credentials = args.get(3).ok_or(())?;
    let data = args.get(4).ok_or(())?;

    let url = format!("http://localhost:8000{}", endpoint);
    println!("{} {}\n", method, url);

    let client = Client::new();
    let mut request = match method.as_str() {
        "GET" => client.get(url),
        "POST" => client.post(url),
        "PUT" => client.put(url),
        "DELETE" => client.delete(url),
        _ => return Err(()),
    };
    if !credentials.is_empty() {
        let credentials: Vec<_> = credentials.splitn(2, ':').collect();
        request = request.basic_auth(credentials.get(0).unwrap(), credentials.get(1));
    }
    if !data.is_empty() {
        request = request.json(&data);
    }
    let response = request.send().unwrap();

    println!("{}\n", response.status());
    println!("{:#?}\n", response.headers());
    if response.status().is_success() {
        println!("{:#?}", response.json::<Value>().unwrap());
    } else {
        println!("{}", response.text().unwrap());
    }

    Ok(())
}
