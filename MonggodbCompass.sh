import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru MongoDB Compass dari GitHub
def check_latest_version_mongodb_compass():
    url = "https://github.com/mongodb-js/compass/releases"  # URL untuk halaman rilis GitHub MongoDB Compass
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Cari elemen yang berisi versi terbaru MongoDB Compass
        version_tag = soup.find('a', {'href': lambda x: x and x.startswith('/mongodb-js/compass/releases/tag/')})
        if version_tag:
            latest_version = version_tag.text.strip()  # Mengambil teks dari elemen yang ditemukan
            #print(f"Latest MongoDB Compass version found: {latest_version}")
            return latest_version

        print("Could not find the latest version information for MongoDB Compass.")
        return None

    else:
        print(f"Failed to access MongoDB Compass page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["MongoDB Compass", "0.0.0", ""])  # Nilai default jika belum ada data
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Munki Version'], row['Web Version']) for row in reader}
    
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
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Jalankan autopkg untuk download dan import ke Munki
def run_autopkg():
    success = True
    failed_archs = []

    try:
        # Jalankan untuk Apple Silicon (arm64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.MongoDB"], check=True)
        print("Autopkg berhasil dijalankan untuk MAC.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")
    
    try:
        # Jalankan untuk Intel (x86_64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.MongoDBx86"], check=True)
        print("Autopkg berhasil dijalankan untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel (x86_64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("MongoDB Compass", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki Version: {Munki_version}\n"
                        f"Latest version: {latest_version}\n"
                        f"MongoDB Compass is Already Import to MunkiAdmin")
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_mongodb_compass_version = check_latest_version_mongodb_compass()
    compass_Munki_version, compass_web_version = versions.get('MongoDB Compass', (None, None))

    if latest_mongodb_compass_version and compare_versions(compass_Munki_version, latest_mongodb_compass_version):
        print(f"Version baru MongoDB Compass tersedia: {latest_mongodb_compass_version}")
        update_web_version_csv("MongoDB Compass", latest_mongodb_compass_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("MongoDB Compass", latest_mongodb_compass_version)
        send_notification_telegram("MongoDB Compass", compass_Munki_version, latest_mongodb_compass_version)
    else:
        print("Version MongoDB Compass sudah yang terbaru.")

if __name__ == "__main__":
    main()
