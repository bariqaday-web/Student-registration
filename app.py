# بدلاً من الروابط المكتوبة يدوياً، نستخدم هذا:
with open('config.json', 'r') as f:
    config = json.load(f)

# تحديد الرابط من ملف الجيسون
if student_data.get('type') == 'high' or not student_data.get('exam_number'):
    target_url = config['urls']['postgrad']
else:
    target_url = config['urls']['undergrad']

# وعند التعبئة نستخدم الـ selectors من الجيسون:
smart_fill(config['selectors']['first_name'], student_data.get('first_name'))
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
    options.binary_location = "/usr/bin/google-chrome"
    return webdriver.Chrome(options=options)

@app.route('/register', methods=['POST'])
def register():
    student_data = request.json
    driver = get_driver()
    wait = WebDriverWait(driver, 15)

    try:
        # 1. تحديد الرابط المناسب تلقائياً
        # إذا أرسلت الواجهة أن النوع "high" أو لم يوجد رقم امتحاني، نذهب للدراسات العليا
        if student_data.get('type') == 'high' or not student_data.get('exam_number'):
            target_url = "https://inpt.rdd.edu.iq/register?type=postgrad" # مثال لرابط الدراسات العليا
        else:
            target_url = "https://inpt.rdd.edu.iq/register?type=undergrad" # مثال للدراسات الأولية

        driver.get(target_url)

        # 2. وظيفة التعبئة الذكية (تعبئ فقط إذا وجد الحقل)
        def smart_fill(selector, value):
            try:
                elements = driver.find_elements(By.CSS_SELECTOR, selector)
                if elements and value:
                    elements[0].clear()
                    elements[0].send_keys(str(value))
                    return True
            except:
                return False
            return False

        # 3. البدء بتعبئة "المعلومات المشتركة" أولاً
        smart_fill("#first_name", student_data.get('first_name'))
        smart_fill("#father_name", student_data.get('father_name'))
        smart_fill("#grandfather_name", student_data.get('grandfather_name'))
        smart_fill("#national_id", student_data.get('national_id'))
        smart_fill("#phone", student_data.get('phone'))
        
        # 4. تعبئة "المعلومات الخاصة" (تلقائياً سيتجاهل ما لا يجد)
        if student_data.get('exam_number'):
            smart_fill("#exam_number", student_data['exam_number'])
            
        # 5. التعامل مع القوائم المنسدلة (الجنس، الدراسة)
        try:
            gender_select = driver.find_elements(By.CSS_SELECTOR, "#gender")
            if gender_select:
                Select(gender_select[0]).select_by_visible_text(student_data.get('gender', 'ذكر'))
        except:
            pass

        # 6. الموافقة والإرسال
        # ملاحظة: نترك الضغط على زر "إنشاء الحساب" كخيار أخير أو نجعل السكريبت يضغط عليه
        # wait.until(EC.element_to_be_clickable((By.ID, "submit_btn"))).click()

        return jsonify({"status": "success", "message": "تمت معالجة البيانات بنجاح وفقاً لنوع التقديم"})

    except Exception as e:
        return jsonify({"status": "error", "message": f"حدث خطأ تقني: {str(e)}"})
    finally:
        driver.quit()

if __name__ == '__main__':
    port = int(os.environ.get("PORT", 5000))
    app.run(host='0.0.0.0', port=port)
