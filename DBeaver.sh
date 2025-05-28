import requests
from bs4 import BeautifulSoup
import csv
import json
import os
import subprocess

# Fungsi untuk mendapatkan versi terbaru DBeaver dari halaman HTML
def check_latest_version_dbeaver():
    url = "https://github.com/dbeaver/dbeaver/releases"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Temukan elemen <a> yang berisi versi terbaru
        version_element = soup.find('a', {'class': 'Link--primary Link'})
        latest_version = None
        
        if version_element:
            latest_version = version_element.get_text(strip=True)
            #print(f"Latest DBeaver version found: {latest_version}")
            return latest_version
        
        print("Version information not found.")
        return None
    except requests.exceptions.RequestException as e:
        print(f"Error fetching the version: {e}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["DBeaver Community", "21.0.0", ""])  # Ganti dengan versi yang sesuai jika perlu
    
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
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        rows = list(reader)
    
    for row in rows:
        if row['Software'] == software_name:
            row['Web Version'] = new_version
    
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
def compare_versions(Munki_version, web_version):
    return Munki_version != web_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.DBeaverCE"], check=True)
        print("Autopkg berhasil dijalankan.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")
    
    try:
        # Jalankan untuk Intel (x86_64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.DBeaverCEx86"], check=True)
        print("Autopkg berhasil dijalankan untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel (x86_64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("DBeaver Community", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM" # Gunakan variabel lingkungan untuk token
    chat_id = "-4523501737" # Gunakan variabel lingkungan untuk chat ID
    if not telegram_token or not chat_id:
        print("Telegram token atau chat ID belum diset.")
        return
    
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki version: {Munki_version}\n"
                        f"Latest version: {web_version}\n"
                        f"DBeaver Community is Already Import to MunkiAdmin")

    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_dbeaver_version = check_latest_version_dbeaver()
    
    if latest_dbeaver_version:
        dbeaver_Munki_version, dbeaver_web_version = versions.get('DBeaver Community', (None, None))

        if compare_versions(dbeaver_Munki_version, latest_dbeaver_version):
            print(f"Version baru DBeaver Community tersedia: {latest_dbeaver_version}")
            update_web_version_csv("DBeaver Community", latest_dbeaver_version)
            # Jalankan autopkg
            run_autopkg()
            # Perbarui kolom Munki Version di file CSV
            update_munki_version_csv("DBeaver Community", latest_dbeaver_version)
            send_notification_telegram("DBeaver Community", dbeaver_Munki_version, latest_dbeaver_version)
        else:
            print("Version DBeaver Community sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru.")

if __name__ == "__main__":
    main()
