from selenium import webdriver
from selenium.webdriver.firefox.options import Options

options = Options()
options.add_argument("--headless")

driver = webdriver.Firefox(options=options)

driver.get("http://localhost:8761")
driver.save_screenshot("screenshots/screenshot-eureka-dashboard.png")

driver.quit()
