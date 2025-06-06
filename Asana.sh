import requests
from bs4 import BeautifulSoup
import csv
import json
import os

def check_latest_version_asana():
    url = "https://asana.com/download"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Temukan elemen dengan atribut data-sublocation="Hero"
        hero_section = soup.find('section', {'data-sublocation': 'Hero'})
        
        if hero_section:
            # Cari semua elemen <span> di dalam Hero section
            span_elements = hero_section.find_all('span')

            for span in span_elements:
                text = span.get_text(strip=True)
                
                # Periksa apakah teks tersebut adalah versi (misalnya, pola "v1.x.x" atau "V1.x.x")
                if text.lower().startswith('v') and any(char.isdigit() for char in text):
                    latest_version = text
                    #print(f"Latest Asana version found: {latest_version}")
                    return latest_version

            print("Version information not found.")
            return None
        else:
            print("Hero section not found.")
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
            writer.writerow(["Asana", "1.1.1", ""])

    
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
def compare_versions(mungki_version, web_version):
    return mungki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, mungki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = f"Update Available for {software_name}!\nMungki version: {mungki_version}\nLatest version: {web_version}"
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'  # Optional: Menggunakan Markdown untuk format pesan yang lebih baik
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        
        # Debugging: Cetak status code dari respon Telegram
        #print(f"Telegram response status code: {response.status_code}")
        #print(f"Telegram response text: {response.text}")
        
        # Cek jika respon status bukan 200, artinya ada masalah
        if response.status_code != 200:
            raise ValueError(f"Request to Telegram returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    
    # Cek versi terbaru dari Asana
    latest_asana_version = check_latest_version_asana()
    asana_mungki_version, asana_web_version = versions.get('Asana', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(asana_mungki_version, latest_asana_version):
        print(f"Versi baru Asana tersedia: {latest_asana_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Asana", latest_asana_version)
        
        # Kirim notifikasi ke Slack
        send_notification_telegram("Asana", asana_mungki_version, latest_asana_version)
    else:
        print("Versi Asana sudah yang terbaru.")

if __name__ == "__main__":
    main()
