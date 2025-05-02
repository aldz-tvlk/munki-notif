import requests
from bs4 import BeautifulSoup
import csv
import json
import os
import subprocess

def check_latest_version_android_studio():
    url = "https://developer.android.com/studio/releases"  # Ganti dengan URL yang sesuai jika berbeda
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Temukan tabel dengan header "Android Studio version"
        table = soup.find('table')
        if not table:
            print("Tabel tidak ditemukan.")
            return None

        header = table.find_all('th')
        if len(header) > 0 and header[0].get_text(strip=True) == "Android Studio version":
            rows = table.find_all('tr')

            latest_version = None
            for row in rows:
                cols = row.find_all('td')
                if len(cols) > 0:
                    version_text = cols[0].get_text(strip=True)
                    # Ambil bagian setelah " | "
                    if " | " in version_text:
                        version = version_text.split(' | ')[1]
                        latest_version = version
                        break

            if latest_version:
                #print(f"Latest Android Studio version found: {latest_version}")
                return latest_version
            else:
                print("Versi terbaru Android Studio tidak ditemukan.")
                return None
        else:
            print("Header 'Android Studio version' tidak ditemukan dalam tabel.")
            return None
    else:
        print(f"Gagal mengakses halaman. Status code: {response.status_code}")
        return None
# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Android Studio", "2024.1.1", ""])
    
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
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.AndroidStudio"], check=True)
        print("Autopkg berhasil dijalankan untuk Apple Silicon (arm64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Apple Silicon (arm64).")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    try:
        # Jalankan untuk Intel (x86_64)
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.AndroidStudiox86"], check=True)
        print("Autopkg berhasil dijalankan untuk Intel (x86_64).")
    except subprocess.CalledProcessError:
        print("Autopkg gagal untuk Intel (x86_64).")
        success = False
        failed_archs.append("Intel (x86_64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("Android Studio", "Failed Import", f"Autopkg gagal untuk:\n{failed_msg}")

    return success


# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, munki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki version: {Munki_version}\n"
                        f"Latest version: {web_version}\n"
                        f"Android Studio is Already Import to MunkiAdmin")   
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
    
    # Cek versi terbaru dari Android Studio
    latest_android_studio_version = check_latest_version_android_studio()
    android_studio_munki_version, android_studio_web_version = versions.get('Android Studio', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(android_studio_munki_version, latest_android_studio_version):
        print(f"Version baru Android Studio tersedia: {latest_android_studio_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Android Studio", latest_android_studio_version)

        # Jalankan autopkg
        run_autopkg()

        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Android Studio", latest_android_studio_version)

        # Kirim notifikasi ke Slack
        send_notification_telegram("Android Studio", android_studio_munki_version, latest_android_studio_version)
    else:
        print("Version Android Studio sudah yang terbaru.")

if __name__ == "__main__":
    main()
