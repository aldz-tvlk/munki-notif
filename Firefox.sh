import os
import requests
from bs4 import BeautifulSoup
import json
import csv

# Fungsi untuk mendapatkan versi terbaru dari situs web Firefox
def check_latest_version_firefox():
    firefox_url = "https://www.mozilla.org/en-US/firefox/releases/"
    response = requests.get(firefox_url)

    # Parsing HTML
    soup = BeautifulSoup(response.text, 'html.parser')

    # Temukan elemen <ol> dengan class 'c-release-list'
    release_list = soup.find('ol', class_='c-release-list')

    if release_list:
        # Temukan elemen <li> pertama
        first_li = release_list.find('li')
        
        if first_li:
            # Temukan sublist <ol> di dalam <li> pertama
            sublist = first_li.find('ol')
            
            if sublist:
                # Temukan versi terbaru dalam sublist (elemen <a> di dalam <li>)
                latest_version = sublist.find('li').find('a').text
            else:
                # Jika sublist tidak ditemukan
                print("Sublist tidak ditemukan.")
                latest_version = "Tidak ditemukan"
        else:
            # Jika elemen <li> pertama tidak ditemukan
            print("Elemen <li> pertama tidak ditemukan.")
            latest_version = "Tidak ditemukan"
    else:
        # Jika elemen <ol> dengan class 'c-release-list' tidak ditemukan
        print("Elemen dengan class 'c-release-list' tidak ditemukan.")
        latest_version = "Tidak ditemukan"

    return latest_version

# Fungsi untuk membaca versi dari file CSV
def read_current_version_csv():
    filename = 'current_version.csv'
    
    # Jika file tidak ada, buat file baru dengan nilai default
    if not os.path.exists(filename):
        with open(filename, 'w', newline='') as file:
            writer = csv.writer(file)
            writer.writerow(["Software", "Mungki Version", "Web Version"])
            writer.writerow(["Firefox", "13.0.0.1", ""])
    
    # Baca file CSV
    with open(filename, 'r') as file:
        reader = csv.DictReader(file)
        for row in reader:
            if row['Software'] == "Firefox":
                return row['Software'], row['Mungki Version'], row['Web Version']
    
    return None, None, None

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
        "text": f"Update Available for {software_name}!\nMunki Version: {mungki_version}\nLatest Version: {web_version}"
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
    # Baca versi saat ini dari file CSV
    software_name, mungki_version, web_version = read_current_version_csv()

    # Cek versi terbaru dari website
    latest_firefox_version = check_latest_version_firefox()

    # Jika versi web dari website berbeda dengan yang ada di file CSV, perbarui dan kirim notifikasi
    if compare_versions(mungki_version, latest_firefox_version):
        print(f"Versi baru tersedia: {latest_firefox_version}")
        
        # Perbarui kolom Web Version di file CSV
        update_web_version_csv(software_name, latest_firefox_version)
        
        # Kirim notifikasi ke Slack
        send_notification_slack(software_name, mungki_version, latest_firefox_version)
    else:
        print("Versi Firefox sudah yang terbaru.")

if __name__ == "__main__":
    main()
