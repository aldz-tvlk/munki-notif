import requests
import csv
import os
import subprocess

# Token GitHub dan Telegram diambil langsung dari script
Gtoken = "x"
telegram_token = "x"
chat_id = "-x"  # Chat ID untuk Telegram

# Fungsi untuk mendapatkan versi terbaru Amazon Q menggunakan GitHub API dengan autentikasi
def check_latest_version_amazon_q():
    api_url = "https://api.github.com/repos/amazon/amazon-q/releases/latest"  # Ganti URL sesuai repositori Amazon Q
    headers = {
        'Authorization': f'token {Gtoken}', # Ambil token GitHub dari environment variables
        'Accept': 'application/vnd.github.v3+json'
    }
    response = requests.get(api_url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        latest_version = data['tag_name']  # Mengambil versi terbaru dari tag_name
        print(f"Latest Amazon Q version found: {latest_version}")
        return latest_version
    else:
        print(f"Gagal mengakses API GitHub Amazon Q. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Amazon Q", "2024.1.0", ""])
    
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

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, web_version):
    return Munki_version != web_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, web_version):
    telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"  # Ganti dengan token bot Telegram kamu
    chat_id = "-4523501737"  # Ganti dengan chat ID yang sesuai
    telegram_message = f"Update Available for {software_name}!\nCurrent version: {Munki_version}\nLatest version: {web_version}"
    
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
    
    # Cek versi terbaru dari Amazon Q
    latest_amazon_q_version = check_latest_version_amazon_q()
    amazon_q_Munki_version, amazon_q_web_version = versions.get('Amazon Q', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(amazon_q_Munki_version, latest_amazon_q_version):
        print(f"Versi baru Amazon Q tersedia: {latest_amazon_q_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Amazon Q", latest_amazon_q_version)
        
        # Kirim notifikasi ke telegram
        send_notification_telegram("Amazon Q", amazon_q_Munki_version, latest_amazon_q_version)
    else:
        print("Versi Amazon Q sudah yang terbaru.")

if __name__ == "__main__":
    main()
