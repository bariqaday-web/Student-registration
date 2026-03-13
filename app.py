import os
import json
import time
from flask import Flask, request, jsonify
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import Select, WebDriverWait
from selenium.webdriver.support import expected_conditions as EC

app = Flask(__name__)

def get_driver():
    options = Options()
    options.add_argument('--headless')
    options.add_argument('--no-sandbox')
    options.add_argument('--disable-dev-shm-usage')
    # ملاحظة: ريلوي يحتاج هذه الإعدادات لتشغيل كروم
    return webdriver.Chrome(options=options)

@app.route('/register', methods=['POST'])
def register():
    student_data = request.json
    driver = get_driver()
    
    try:
        with open('config.json', 'r', encoding='utf-8') as f:
            config = json.load(f)

        # تحديد المسار تلقائياً
        is_high = student_data.get('type') == 'high' or not student_data.get('exam_number')
        target_url = config['urls']['postgrad'] if is_high else config['urls']['undergrad']
        
        driver.get(target_url)
        time.sleep(3) # انتظار بسيط لتحميل العناصر

        def smart_fill(sel_key, value):
            if not value: return
            try:
                selector = config['selectors'][sel_key]
                element = driver.find_element(By.CSS_SELECTOR, selector)
                element.clear()
                element.send_keys(str(value))
            except: pass

        # تعبئة الحقول الأساسية
        smart_fill('first_name', student_data.get('first_name'))
        smart_fill('father_name', student_data.get('father_name'))
        smart_fill('grandfather_name', student_data.get('grandfather_name'))
        smart_fill('national_id', student_data.get('national_id'))
        smart_fill('phone', student_data.get('phone'))
        
        # حقول إضافية ظهرت في الفيديو
        smart_fill('mother_name', student_data.get('mother_name'))
        smart_fill('exam_number', student_data.get('exam_number'))

        # الضغط على زر الإرسال (اختياري - يفضل تركه للزبون للتأكد أو تفعيله)
        # driver.find_element(By.CSS_SELECTOR, config['selectors']['submit_btn']).click()

        return jsonify({"status": "success", "message": "تمت التعبئة بنجاح"})

    except Exception as e:
        return jsonify({"status": "error", "message": str(e)})
    finally:
        driver.quit()

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get("PORT", 5000)))
