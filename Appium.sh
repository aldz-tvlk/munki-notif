import requests
import csv
import json
import os
import subprocess

# Token Github
Gtoken = "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"

# Fungsi untuk mendapatkan versi terbaru PDF Sam menggunakan GitHub API dengan autentikasi
def check_latest_version_appium():
    api_url = "https://api.github.com/repos/appium/appium-inspector/releases/latest"
    headers = {
        'Authorization': f'token {Gtoken}',  # Ganti dengan token GitHub Anda
        'Accept': 'application/vnd.github.v3+json'
    }
    response = requests.get(api_url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        latest_version = data['tag_name']  # Mengambil versi terbaru dari tag_name
       # print(f"Latest Appium Inspector version found: {latest_version}")
        return latest_version
    else:
        print(f"Gagal mengakses API GitHub Appium Inspector. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Appium Inspector", "4.3.0", ""])
    
    # Baca file CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {}
        for row in reader:
            versions[row['Software']] = (row['Munki Version'], row['Web Version'])
    
    return versions

# Fungsi untuk memperbarui kolom Web Version di file CSV
def update_web_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    rows = []
    # Baca semua baris dari CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    # Update versi Web Version pada baris yang sesuai
    for row in rows:
        if row['Software'] == software_name:
            row['Web Version'] = new_version
    # Tulis kembali file CSV dengan pembaruan
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk memperbarui kolom Munki Version di file CSV
def update_munki_version_csv(software_name, new_version):
    filename = 'current_version.csv'
    rows = []
    # Baca semua baris dari CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    
    # Update versi Munki Version pada baris yang sesuai
    for row in rows:
        if row['Software'] == software_name:
            row['Munki Version'] = new_version
    
    # Tulis kembali file CSV dengan pembaruan
    with open(filename, 'w', newline='') as file:
        writer = csv.DictWriter(file, fieldnames=["Software", "Munki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(munki_version, web_version):
    return munki_version != web_version

# Jalankan autopkg untuk download dan import ke Munki (Apple Silicon & Intel)
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Appium-Inspector"], check=True)
        print("Autopkg berhasil dijalankan untuk Apple Silicon (arm64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon (arm64).")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    try:
        # Jalankan untuk Intel (x86_64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.Appium-Inspectorx86"], check=True)
        print("Autopkg berhasil dijalankan untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel (x86_64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("Appium Inspector", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

## Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, munki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = f"Update Available for {software_name}\nMunki version: {munki_version}\nLatest version: {web_version}\nAppium Inspector is Already Import to MunkiAdmin"
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'  # Optional: Menggunakan Markdown untuk format pesan yang lebih baik
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        # Cek jika respon status bukan 200, artinya ada masalah
        if response.status_code != 200:
            raise ValueError(f"Request to Telegram returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    # Cek versi terbaru dari Appium
    latest_appium_version = check_latest_version_appium()
    appium_munki_version, appium_web_version = versions.get('Appium Inspector', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(appium_munki_version, latest_appium_version):
        print(f"New version of Appium Inspector available: {latest_appium_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Appium Inspector", latest_appium_version)

        # Jalankan autopkg
        run_autopkg()
        
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Appium Inspector", latest_appium_version)

        # Kirim notifikasi ke Slack
        send_notification_telegram("Appium Inspector", appium_munki_version, latest_appium_version)
    else:
        print("Version Appium Inspector sudah yang terbaru.")

if __name__ == "__main__":
    main()
