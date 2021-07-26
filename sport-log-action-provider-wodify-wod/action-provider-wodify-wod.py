#!/usr/bin/python3

from sys import exit
from time import sleep
from datetime import datetime, timedelta
from types import SimpleNamespace
import requests
from requests.auth import HTTPBasicAuth
import json
from selenium.webdriver import Firefox
from selenium.webdriver.firefox.options import Options
from selenium.common.exceptions import NoSuchElementException

start_time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
end_time = (datetime.now() + timedelta(hours = 24, minutes = 1)).strftime("%Y-%m-%dT%H:%M:%S")
response = requests.get(
    f"http://localhost:8000/v1/ap/executable_action_event/timespan/{start_time}/{end_time}", 
    auth=HTTPBasicAuth('wodify-wod', 'wodify-wod-passwd'))  
if response.status_code != 200:
    exit(1)

events = json.loads(response.text, object_hook=lambda d: SimpleNamespace(**d))

for event in events:
    event.datetime = datetime.strptime(event.datetime, "%Y-%m-%dT%H:%M:%S")

events = [event for event in events if event.datetime > datetime.now()]

print(events)

options = Options()
#options.add_argument("--headless")
#options.add_argument("--no-sandbox")

for event in events:
    print(event)

    with Firefox(executable_path = "../geckodriver", options=options, service_log_path="/dev/null") as driver:
        time = str(event.datetime.strftime("%-H:%M"))
        date = event.datetime.strftime("%m/%d/%Y")

        driver.get("https://app.wodify.com/WOD/WODEntry.aspx")
        driver.implicitly_wait(4)

        driver.find_element_by_id("Input_UserName").send_keys(event.username)
        sleep(1)
        driver.find_element_by_id("Input_Password").send_keys(event.password)
        sleep(1)
        driver.find_element_by_class_name("signin-btn").click()
        sleep(1)

        try:
            driver.find_element_by_id("AthleteTheme_wtLayoutNormal_block_wt9_wtLogoutLink")
        except NoSuchElementException:
            print("login failed")
            continue

        # only needed for other date
        # date_input = driver.find_element_by_id("AthleteTheme_wtLayoutNormal_block_wtSubNavigation_W_Utils_UI_wt3_block_wtDateInputFrom")
        # date_input.clear()
        # date_input.send_keys(datetime.now().strftime("%m/%d/%Y"))
        # sleep(5)

        wod = driver.find_element_by_id("AthleteTheme_wtLayoutNormal_block_wtMainContent_WOD_UI_wt9_block_wtWODComponentsList")
        elements = wod.find_elements_by_class_name("component_show_wrapper")
        
        for element in elements:
            name = element.find_element_by_class_name("component_name").get_attribute("innerHTML")
            content_el = element.find_element_by_class_name("component_wrapper")
            content = content_el.text.replace("<br>", "\n")
            try:
                comment = content_el.find_element_by_class_name("component_comment").text
            except NoSuchElementException:
                comment = ""

            print("name:\n", name.replace("&nbsp;", " "))
            print("content:\n", content.replace("&nbsp;", " "))
            print("comment:\n", comment.replace("&nbsp;", " "))

        # TODO insert into wod in db