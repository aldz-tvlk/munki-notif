import requests
from bs4 import BeautifulSoup
import csv
import os

# Token Telegram diambil langsung dari script
telegram_token = "8184924708:AAGZ56uxf7LzbukNx2tdx-F148-9NtLdhOM"
chat_id = "-4523501737"  # Chat ID untuk Telegram

# Fungsi untuk mendapatkan versi terbaru Spotify dari APKMirror
def check_latest_version_spotify():
    url = "https://www.apkmirror.com/apk/spotify-ltd/spotify/"
    response = requests.get(url)

    if response.status_code == 200:
        soup = BeautifulSoup(response.text, 'html.parser')
        
        # Mencari elemen yang berisi informasi versi terbaru
        version_tag = soup.find('div', class_='appRowTitle')  # Pastikan class name sesuai dengan struktur halaman APKMirror
        
        if version_tag:
            # Ekstrak nomor versi dari teks, misalnya: 'Spotify 8.7.70.553'
            latest_version = version_tag.text.strip().split()[-1]  # Mengambil '8.7.70.553'
            print(f"Raw version string: '{version_tag.text.strip()}'")
            print(f"Latest Spotify version found: {latest_version}")
            return latest_version
        else:
            print("Could not find the latest version information on the page.")
            return None

    else:
        print(f"Failed to access APKMirror page. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Munki Version", "Web Version"])
            writer.writerow(["Spotify", "1.0.0", ""])  # Nilai default jika belum ada data
    
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

# Fungsi untuk membandingkan versi
def compare_versions(Munki_version, latest_version):
    return Munki_version != latest_version

# Fungsi untuk mengirim notifikasi ke Telegram
def send_notification_telegram(software_name, Munki_version, latest_version):
    telegram_message = (f"Update Available for {software_name}!\n"
                        f"Current version: {Munki_version}\n"
                        f"Latest version: {latest_version}")
    
    send_text_url = f"https://api.telegram.org/bot{telegram_token}/sendMessage"
    params = {
        'chat_id': chat_id,
        'text': telegram_message,
        'parse_mode': 'Markdown'
    }
    
    try:
        response = requests.get(send_text_url, params=params)
        print(f"Telegram response status code: {response.status_code}")
        print(f"Telegram response text: {response.text}")
        
        if response.status_code != 200:
            raise ValueError(f"Error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Telegram: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    versions = read_current_version_csv()
    
    latest_spotify_version = check_latest_version_spotify()
    spotify_Munki_version, spotify_web_version = versions.get('Spotify', (None, None))

    if compare_versions(spotify_Munki_version, latest_spotify_version):
        print(f"New version of Spotify available: {latest_spotify_version}")
        
        update_web_version_csv("Spotify", latest_spotify_version)
        
        send_notification_telegram("Spotify", spotify_Munki_version, latest_spotify_version)
    else:
        print("Spotify is up to date.")

if __name__ == "__main__":
    main()
