# INSTALL GENIEACS OTOMATIS

This is autoinstall GenieACS

# Usage

```
sudo su
```

```
sudo apt update && sudo apt upgrade
```

```
apt install git curl -y
```

```
git clone https://github.com/AMDStore7807/acs
```

```
cd acs
```

```
chmod +x auto.sh
```

INSTALL GENIEACS PILIH THEMA

```
bash auto.sh
```

# Pastikan Anda berada di direktori acs

```
cd acs
```

# (Jika baru di-clone, masuk dengan 'cd acs')

# Untuk restart system jika tidak muncul:

# Berikan izin eksekusi

```
chmod +x restart.sh
```

# Jalankan script

```
bash restart.sh
```

Baca terlebih dahulu !!!

#=== Script update GenieACS ====#

Config sebelumnya akan terhapus dan tergantikan oleh config baru

Yang akan diupdate, yaitu:

• Admin >> Preset <br>
• Admin >> Provosions <br>
• Admin >> Virtual Parameter<br>
• Admin >> Config<br>

#===Script/config tersebut akan terganti dengan yang baru ====#

Jika anda memiliki config/script custom buatan anda sendiri,<br>
silahkan backup terlebih dahulu, kemudian setelah update lakukan config manual lagi sesuai config custom anda.<br>

Device, user, permisions, tidak akan terpengaruh<br>
Bagi yang confignya error, akan ter-repair dengan script ini<br>
Anda masih bisa kembali ke konfigurasi sebelumnya dengan memilih restore<br>
======= CARA RESTORE ========<br>

```
cd
```

```
sudo mongorestore --db=genieacs --drop genieacs-backup/genieacs
```

🤝 Kontribusi
Kontribusi selalu diterima! Silakan buat pull request atau laporkan issue jika menemukan bug.

https://wa.me/6285150614774?text=Halo
