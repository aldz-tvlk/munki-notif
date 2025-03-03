import requests
from bs4 import BeautifulSoup
import csv
import os

# Token Telegram dan chat ID
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai

# Fungsi untuk mendapatkan versi terbaru Arc Browser dari halaman rilis
url = "https://resources.arc.net/hc/en-us/articles/20498293324823-Arc-for-macOS-2024-Release-Notes"

def check_latest_version_arc():
    try:
        # Mengatur headers yang lebih lengkap
        headers = {
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.121 Safari/537.36",
            "Accept-Language": "en-US,en;q=0.9",
            "Accept-Encoding": "gzip, deflate, br",
            "Connection": "keep-alive"
        }
        response = requests.get(url, headers=headers)
        response.raise_for_status()  # Pastikan permintaan berhasil
        soup = BeautifulSoup(response.content, 'html.parser')
        
        # Cari h2 pertama yang berisi tanggal
        h2_tag = soup.find('h2', id="october102024")  # Ganti dengan ID yang sesuai jika perlu
        if h2_tag:
            # Ambil versi dari elemen <p> setelah h2_tag
            version_paragraph = h2_tag.find_next('p')
            if version_paragraph:
                latest_version = version_paragraph.text.strip().replace('V', '')
                return latest_version
        return None
    except Exception as e:
        print(f"Error occurred: {e}")
        return None
        
# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Arc Browser", "0.0.0", ""])  # Nilai default jika belum ada data
    
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        versions = {row['Software']: (row['Mungki Version'], row['Web Version']) for row in reader}
    
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

# Fungsi untuk membandingkan versi
def compare_versions(mungki_version, latest_version):
    return mungki_version != latest_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Mungki Version: {mungki_version}\n"
                        f"Latest version: {latest_version}")
    
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
    
    latest_arc_version = check_latest_version_arc()
    arc_mungki_version, arc_web_version = versions.get('Arc Browser', (None, None))

    if latest_arc_version and compare_versions(arc_mungki_version, latest_arc_version):
        print(f"New version of Arc Browser available: {latest_arc_version}")
        
        update_web_version_csv("Arc Browser", latest_arc_version)
        
        send_notification_telegram("Arc Browser", arc_mungki_version, latest_arc_version)
    else:
        print("Arc Browser is up to date or could not retrieve the latest version.")

if __name__ == "__main__":
    main()
