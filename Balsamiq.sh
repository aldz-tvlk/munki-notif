import requests
from bs4 import BeautifulSoup
import csv
import json
import os

def check_latest_version_balsamiq():
    url = "https://balsamiq.com/wireframes/desktop/release-notes/"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')

        # Temukan elemen utama yang berisi konten rilis
        main_content = soup.find('div', {'id': 'main-content'})
        
        if main_content:
            # Cari elemen <h3> yang memiliki tanggal rilis, versi di ul setelahnya
            latest_release = main_content.find('h3')
            if latest_release:
                release_date = latest_release.get_text(strip=True)
                version_list = latest_release.find_next('ul').find_all('li')

                # Ambil versi dari elemen <li> yang ditemukan
                for li in version_list:
                    text = li.get_text(strip=True)
                    # Periksa jika versi adalah 4.7.5
                    if '4.7.5' in text:
                        print(f"Latest Balsamiq version found: 4.7.5")
                        return '4.7.5'

            print("Version 4.7.5 not found.")
            return None
        else:
            print("Main content not found.")
            return None
    else:
        print(f"Gagal mengakses halaman. Status code: {response.status_code}")
        return None# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["balsamiq", "1.1.1", ""])

    
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
    telegram_message = f"Update Available for {software_name}!\nCurrent version: {mungki_version}\nLatest version: {web_version}"
    
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
    
    # Cek versi terbaru dari balsamiq
    latest_balsamiq_version = check_latest_version_balsamiq()
    balsamiq_mungki_version, balsamiq_web_version = versions.get('balsamiq', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(balsamiq_mungki_version, latest_balsamiq_version):
        print(f"Versi baru balsamiq tersedia: {latest_balsamiq_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("balsamiq", latest_balsamiq_version)
        
        # Kirim notifikasi ke Slack
        send_notification_telegram("balsamiq", balsamiq_mungki_version, latest_balsamiq_version)
    else:
        print("Versi Balsamiq sudah yang terbaru.")

if __name__ == "__main__":
    main()
