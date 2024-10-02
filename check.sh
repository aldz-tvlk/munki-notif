import subprocess

# Daftar nama file skrip Python yang ingin dijalankan
scripts = [
    'Adobereader.sh',  # Ganti dengan nama skrip Python Anda
    'Androidstudio.sh',
    'Appium.sh',
    'Asana.sh',
    'Burpsuitecommunity.sh',
    'Chrome.sh',
    'DBeaver.sh',
    'Drive.sh',
    'Figma.sh',
    'Filezilla.sh',
    'Firefox.sh',
    'Githubdesktop.sh',
    'GnuPG.sh',
    'Go.sh',
    'Homebrew.sh',
    'IntellijCE.sh',
    'PdfSam.sh',
    'Zoom.sh',
]

def run_scripts(scripts):
    for script in scripts:
        try:
            print(f"Menjalankan {script}...")
            result = subprocess.run(['python3', script], check=True, text=True, capture_output=True)
            print(f"Output dari {script}:")
            print(result.stdout)
        except subprocess.CalledProcessError as e:
            print(f"Error saat menjalankan {script}: {e}")
            print(f"Output kesalahan: {e.stderr}")

if __name__ == "__main__":
    run_scripts(scripts)
