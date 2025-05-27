import requests
from bs4 import BeautifulSoup
import csv
import os
import subprocess

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Microsoft Remote Desktop dari halaman App Store
def check_latest_version_remote_desktop():
    url = "https://apps.apple.com/us/app/windows-app/id1295203466?mt=12"  # URL untuk halaman App Store
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Mencari elemen yang berisi versi terbaru
        version_tag = soup.find('h4', class_='version-history__item__version-number')
        if not version_tag:
            # Jika tidak ditemukan, coba mencari dengan p yang memiliki teks "Version"
            version_tag = soup.find('p', class_='whats-new__latest__version')
        
        if version_tag:
            latest_version = version_tag.text.replace("Version ", "").strip()  # Mengambil teks dari elemen yang ditemukan
            #print(f"Latest Microsoft Remote Desktop version found: {latest_version}")
            return latest_version
        
        print("Could not find the version information in the page.")
        return None

    else:
        print(f"Failed to access Microsoft Remote Desktop page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Microsoft Remote Desktop", "0.0.0", ""])  # Nilai default jika belum ada data
    
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
        subprocess.run(["autopkg", "run", "com.github.munki-tvlk.munki.microsoftremotedesktop"], check=True)
        print("Autopkg berhasil dijalankan untuk MAC.")
    except subprocess.CalledProcessError:
        print("Autopkg gagal.")
        success = False
        failed_archs.append("Apple Silicon (arm64)")

    # Kirim notifikasi jika ada yang gagal
    if not success:
        failed_msg = "\n".join(failed_archs)
        send_notification_telegram("Microsoft Remote Desktop", "Failed Import", f"Autopkg gagal untuk:{failed_msg}")

    return success


# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Munki Version: {Munki_version}\n"
                        f"Latest version: {latest_version}\n"
                        f"Microsoft Remote Desktop is Already Import to MunkiAdmin")

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
    latest_remote_desktop_version = check_latest_version_remote_desktop()
    remote_desktop_Munki_version, remote_desktop_web_version = versions.get('Microsoft Remote Desktop', (None, None))
    if latest_remote_desktop_version and compare_versions(remote_desktop_Munki_version, latest_remote_desktop_version):
        print(f"Version baru Microsoft Remote Desktop tersedia: {latest_remote_desktop_version}")
        update_web_version_csv("Microsoft Remote Desktop", latest_remote_desktop_version)
        # Jalankan autopkg
        run_autopkg()
        # Perbarui kolom Munki Version di file CSV
        update_munki_version_csv("Microsoft Remote Desktop", latest_remote_desktop_version)
        send_notification_telegram("Microsoft Remote Desktop", remote_desktop_Munki_version, latest_remote_desktop_version)
    else:
        print("Version Microsoft Remote Desktop sudah yang terbaru.")

if __name__ == "__main__":
    main()
