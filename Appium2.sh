import requests
import csv
import os
import subprocess

# Konfigurasi
GITHUB_TOKEN = "s"
TELEGRAM_TOKEN = "s:s"
CHAT_ID = "-s"
CSV_FILE = 'current_version.csv'

# Cek versi terbaru dari GitHub
def check_latest_version_appium():
    api_url = "https://api.github.com/repos/appium/appium-inspector/releases/latest"
    headers = {'Authorization': f'token {GITHUB_TOKEN}'}
    response = requests.get(api_url, headers=headers)
    if response.status_code == 200:
        return response.json().get('tag_name')
    else:
        print(f"Gagal mendapatkan versi terbaru. Status code: {response.status_code}")
        return None

# Baca versi saat ini dari CSV
def read_current_version_csv():
    if not os.path.exists(CSV_FILE):
        return None
    with open(CSV_FILE, 'r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if row['Software'] == 'Appium Inspector':
                return row['Mungki Version']
    return None

# Perbarui CSV dengan versi terbaru
def update_csv(new_version):
    rows = []
    with open(CSV_FILE, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    for row in rows:
        if row['Software'] == 'Appium Inspector':
            row['Web Version'] = new_version
    with open(CSV_FILE, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=['Software', 'Mungki Version', 'Web Version'])
        writer.writeheader()
        writer.writerows(rows)

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    try:
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Appium-Inspector"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError as e:
        print(f"Autopkg gagal: {e}")

# Kirim notifikasi ke Telegram
def send_notification(new_version):
    message = f"Appium Inspector berhasil diupdate ke versi {new_version} dan diimport ke Munki."
    url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    requests.post(url, data={'chat_id': CHAT_ID, 'text': message})

# Proses utama
def main():
    latest_version = check_latest_version_appium()
    if not latest_version:
        print("Gagal mendapatkan versi terbaru.")
        return
    current_version = read_current_version_csv()
    if latest_version != current_version:
        print(f"Versi baru ditemukan: {latest_version}")
        run_autopkg()
        update_csv(latest_version)
        send_notification(latest_version)
    else:
        print("Tidak ada versi baru.")

if __name__ == "__main__":
    main()
