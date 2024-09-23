import requests
import csv
import json
import os

# Fungsi untuk mendapatkan versi terbaru PDF Sam menggunakan GitHub API dengan autentikasi
def check_latest_version_appium():
    api_url = "https://api.github.com/repos/appium/appium-inspector/releases/latest"
    headers = {
        'Authorization': 'token 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',  # Ganti dengan token GitHub Anda
        'Accept': 'application/vnd.github.v3+json'
    }
    response = requests.get(api_url, headers=headers)

    if response.status_code == 200:
        data = response.json()
        latest_version = data['tag_name']  # Mengambil versi terbaru dari tag_name
        print(f"Latest Appium version found: {latest_version}")
        return latest_version
    else:
        print(f"Gagal mengakses API GitHub Appium. Status code: {response.status_code}")
        return None

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Appium", "4.3.0", ""])
    
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

# Fungsi untuk mengirim notifikasi ke Slack melalui webhook
def send_notification_slack(software_name, mungki_version, web_version):
    webhook_url = "https://hooks.slack.com/services/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"  # Ganti dengan URL webhook Anda
    slack_data = {
        "text": f"Update Available for {software_name}!\nCurrent version: {mungki_version}\nLatest version: {web_version}"
    }
    
    headers = {
        'Content-Type': 'application/json',
    }
    
    try:
        response = requests.post(webhook_url, data=json.dumps(slack_data), headers=headers)
        
        # Debugging: Cetak status code dari respon Slack
        print(f"Slack response status code: {response.status_code}")
        print(f"Slack response text: {response.text}")
        
        # Cek jika respon status bukan 200, artinya ada masalah
        if response.status_code != 200:
            raise ValueError(f"Request to Slack returned an error {response.status_code}, response: {response.text}")
    except Exception as e:
        print(f"Error sending notification to Slack: {e}")

# Proses utama untuk mengecek versi dan memperbarui jika diperlukan
def main():
    # Baca semua versi saat ini dari file CSV
    versions = read_current_version_csv()
    
    # Cek versi terbaru dari Appium
    latest_appium_version = check_latest_version_appium()
    appium_mungki_version, appium_web_version = versions.get('Appium', (None, None))

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(appium_mungki_version, latest_appium_version):
        print(f"Versi baru Appium tersedia: {latest_appium_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv("Appium", latest_appium_version)
        
        # Kirim notifikasi ke Slack
        send_notification_slack("Appium", appium_mungki_version, latest_appium_version)
    else:
        print("Versi Appium sudah yang terbaru.")

if __name__ == "__main__":
    main()
