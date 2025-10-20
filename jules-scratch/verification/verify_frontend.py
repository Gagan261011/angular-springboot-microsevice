from playwright.sync_api import sync_playwright

def run(playwright):
    browser = playwright.chromium.launch(headless=True)
    page = browser.new_page()
    page.goto("http://localhost:4200")
    page.click("text=Browse Menu")
    page.wait_for_selector("text=Add to Cart")
    page.click("text=Add to Cart")
    page.click("text=Cart")
    page.click("text=Place Order")
    page.screenshot(path="jules-scratch/verification/verification.png")
    browser.close()

with sync_playwright() as playwright:
    run(playwright)
