import requests
from bs4 import BeautifulSoup
import csv
import os

# Ganti dengan token bot Telegram dan chat ID yang sesuai
TELEGRAM_TOKEN = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
CHAT_ID = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Figma dari halaman HTML
def check_latest_version_figma():
    url = "https://www.figma.com/downloads/"
    try:
        response = requests.get(url)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Temukan elemen yang berisi informasi versi terbaru
        version_element = soup.find('h2', string='Figma for macOS')  # Contoh untuk Figma macOS
        latest_version = None
        
        if version_element:
            # Mengambil versi dari elemen di bawah heading Figma for macOS
            latest_version = version_element.find_next('p').get_text(strip=True)
            print(f"Latest Figma version found: {latest_version}")
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
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Figma", "1.0.0", ""])  # Ganti dengan versi yang sesuai jika perlu
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {}
        for row in reader:
            versions[row['Software']] = (row['Mungki Version'], row['Web Version'])
    
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
        writer = csv.DictWriter(file, fieldnames=["Software", "Mungki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi baru
def compare_versions(mungki_version, web_version):
    return mungki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, web_version):
    telegram_message = f"Update Available for {software_name}!\nCurrent version: {mungki_version}\nLatest version: {web_version}"
    send_text_url = f"https://api.telegram.org/bot{TELEGRAM_TOKEN}/sendMessage"
    params = {
        'chat_id': CHAT_ID,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        response.raise_for_status()  # Akan memunculkan error jika status code tidak 200
        
        print(f"Telegram response status code: {response.status_code}")
        print(f"Telegram response text: {response.text}")
    except requests.exceptions.RequestException as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    latest_figma_version = check_latest_version_figma()
    
    if latest_figma_version:
        figma_mungki_version, figma_web_version = versions.get('Figma', (None, None))

        if compare_versions(figma_mungki_version, latest_figma_version):
            print(f"Versi baru Figma tersedia: {latest_figma_version}")
            update_web_version_csv("Figma", latest_figma_version)
            send_notification_telegram("Figma", figma_mungki_version, latest_figma_version)
        else:
            print("Versi Figma sudah yang terbaru.")
    else:
        print("Tidak dapat mengambil versi terbaru.")

if __name__ == "__main__":
    main()
