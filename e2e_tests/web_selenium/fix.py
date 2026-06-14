import re

with open('test_web_selenium.py', 'r', encoding='utf-8') as f:
    content = f.read()

helper = '''
def get_flutter_inputs(driver):
    std = driver.find_elements(By.TAG_NAME, "input")
    if len(std) >= 2: return std
    sems = driver.find_elements(By.CSS_SELECTOR, "flt-semantics[aria-label*='Email' i], flt-semantics[aria-label*='Password' i]")
    return sems

def find_input_by_type(driver, input_type="email"):'''

content = content.replace('def find_input_by_type(driver, input_type="email"):', helper)

new_type = '''def type_into_field(driver, field, text):
    try:
        field.click()
        import time
        time.sleep(0.5)
        from selenium.webdriver.common.action_chains import ActionChains
        from selenium.webdriver.common.keys import Keys
        actions = ActionChains(driver)
        actions.send_keys(Keys.CONTROL + "a").send_keys(Keys.BACKSPACE).perform()
        time.sleep(0.2)
        ActionChains(driver).send_keys(text).perform()
    except Exception:
        pass
'''

content = re.sub(r'def type_into_field.*?except Exception:\s*driver\.execute_script[^\n]*\n', new_type, content, flags=re.DOTALL)

content = content.replace('driver.find_elements(By.TAG_NAME, "input")', 'get_flutter_inputs(driver)')

with open('test_web_selenium.py', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
