import requests
from bs4 import BeautifulSoup
import csv
import os
import re

# Fungsi untuk mendapatkan versi terbaru Google Chrome dari blog rilis
def check_latest_version_chrome():
    url = "https://chromereleases.googleblog.com/"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Temukan semua elemen <span> dan cari yang berisi informasi versi
        version_elements = soup.find_all('span')
        
        latest_version = None
        
        for element in version_elements:
            text = element.get_text(strip=True)
            # Menggunakan regex untuk menemukan nomor versi dalam format yang tepat
            match = re.search(r'(\d+\.\d+\.\d+\.\d+)', text)
            if match:
                latest_version = match.group(0)  # Ambil versi yang cocok
                break
        
        if latest_version:
            print(f"Latest Google Chrome version found: {latest_version}")
            return latest_version
        else:
            print("Version information not found.")
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
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Google Chrome", "114.0.5735.110", ""])  # Default Chrome version
    
    # Baca file CSV
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
        writer = csv.DictWriter(file, fieldnames=["Software", "Mungki Version", "Web Version"])
        writer.writeheader()
        writer.writerows(rows)

# Fungsi untuk membandingkan versi
def compare_versions(local_version, web_version):
    return local_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, local_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = f"Update Available for {software_name}!\nCurrent version: {local_version}\nLatest version: {web_version}"
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'  # Optional: Menggunakan Markdown untuk format pesan yang lebih baik
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        
        # Debugging: Cetak status code dari respon Telegram
        print(f"Telegram response status code: {response.status_code}")
        print(f"Telegram response text: {response.text}")
        
        # Cek jika respon status bukan 200, artinya ada masalah
        if response.status_code != 200:
            raise ValueError(f"Request to Telegram returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    
    # Cek versi terbaru dari Google Chrome
    latest_chrome_version = check_latest_version_chrome()
    chrome_local_version, chrome_web_version = versions.get('Google Chrome', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(chrome_local_version, latest_chrome_version):
        print(f"Versi baru Google Chrome tersedia: {latest_chrome_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Google Chrome", latest_chrome_version)
        
        # Kirim notifikasi ke Telegram
        send_notification_telegram("Google Chrome", chrome_local_version, latest_chrome_version)
    else:
        print("Versi Google Chrome sudah yang terbaru.")

if __name__ == "__main__":
    main()
