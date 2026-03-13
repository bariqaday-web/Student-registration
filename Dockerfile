FROM python:3.9-slim

# تثبيت كروم والمكتبات اللازمة
RUN apt-get update && apt-get install -y \
    wget gnupg unzip \
    google-chrome-stable \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . .
RUN pip install -r requirements.txt

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:app"]

