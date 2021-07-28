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
    auth=HTTPBasicAuth('wodify-login', 'wodify-login-passwd'))  
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

        driver.get("https://app.wodify.com/Schedule/CalendarListView.aspx")
        driver.implicitly_wait(4)

        driver.find_element_by_id("Input_UserName").send_keys(event.username)
        sleep(1)
        driver.find_element_by_id("Input_Password").send_keys(event.password)
        sleep(1)
        driver.find_element_by_class_name("signin-btn").click()
        sleep(1)

        try:
            driver.find_element_by_id("AthleteTheme_wt6_block_wt9_wtLogoutLink")
        except NoSuchElementException:
            print("login failed")
            continue

        driver.implicitly_wait(0.5)

        while datetime.now() < event.datetime - timedelta(hours=24):
            sleep(0.1)

        success = False
        start_time = datetime.now()

        while not success and datetime.now() < start_time + timedelta(minutes=1):
            driver.refresh()
            rows = driver.find_elements_by_xpath("//table[@class='TableRecords']/tbody/tr")
            for i, row in enumerate(rows):
                try:
                    day = row.find_element_by_xpath(f'./td[1]/span[contains(@class, "h3")]')
                    if date in day.get_attribute("innerHTML"):
                        break
                except NoSuchElementException:
                    pass
            for row in rows[i+1:]:
                try:
                    label = row.find_element_by_xpath('./td[1]/div/span') 
                    title = label.get_attribute('title')
                    if type_ in title and time in title:
                        row.find_element_by_xpath('./td[3]/div/a').click()

                        requests.delete(f"http://localhost:8000/v1/action_event/{event.action_event_id}")  
                        #with open("last_login", "a+") as f:
                            #f.write(f"{datetime_.strftime('%d.%m.%Y %H:%M:%S')} at {datetime.now().strftime('%d.%m.%Y %H:%M:%S')}\n")
                        success = True
                        sleep(2)
                        break
                except NoSuchElementException:
                    pass

    connection.close()