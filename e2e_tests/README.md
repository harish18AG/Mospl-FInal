# MOSPL E2E Selenium Test Suite

**Application:** MOSPL – Premium Leather Shopping (Flutter Web)  
**URL:** https://harish18ag.github.io/Mospl-FInal/  
**Tests:** 142 end-to-end test cases

## Prerequisites

- Python 3.8+
- Google Chrome (latest)
- Internet connection

## Install Dependencies

```bash
pip install -r requirements.txt
```

## Run All Tests

```bash
python test_mospl_e2e.py
```

## Run Specific Test Module

```bash
python -m unittest test_mospl_e2e.TC05_HomeScreen -v
```

## Run Single Test Case

```bash
python -m unittest test_mospl_e2e.TC05_HomeScreen.test_TC029_home_page_loads -v
```

## Output

After execution, the XLSX report is saved in the same folder:
```
E2E_Test_Report_MOSPL_<timestamp>.xlsx
```

## Test Coverage

| Module           | TC Range   | Count |
|------------------|------------|-------|
| App Launch       | TC001–TC005| 5     |
| Sign In          | TC006–TC014| 9     |
| Sign Up          | TC015–TC020| 6     |
| Forgot Password  | TC021–TC023| 3     |
| Onboarding       | TC024–TC028| 5     |
| Home Screen      | TC029–TC040| 12    |
| Categories       | TC041      | 1     |
| Products         | TC042–TC046| 5     |
| Search & Filters | TC047–TC052| 6     |
| Wishlist         | TC053      | 1     |
| Collections      | TC054–TC055| 2     |
| Cart             | TC056–TC057| 2     |
| Checkout         | TC058–TC060| 3     |
| Address          | TC061–TC066| 6     |
| Payment          | TC067–TC069| 3     |
| Orders           | TC070–TC079| 10    |
| Profile          | TC080–TC085| 6     |
| Account          | TC086–TC091| 6     |
| Notifications    | TC092      | 1     |
| Offers/Coupons   | TC093–TC094| 2     |
| Reviews/Ratings  | TC095–TC097| 3     |
| Returns/Support  | TC098–TC099| 2     |
| AI Chatbot       | TC100–TC103| 4     |
| Info Pages       | TC104–TC109| 6     |
| Collections      | TC110–TC114| 5     |
| Admin Panel      | TC115–TC125| 11    |
| Navigation/UX    | TC126–TC135| 10    |
| Edge Cases       | TC136–TC142| 7     |
| **Total**        |            | **142**|
