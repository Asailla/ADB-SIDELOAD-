ADB School Loader

แอป Android ที่พัฒนาด้วย Flutter สำหรับช่วยติดตั้งไฟล์ APK ผ่าน ADB โดยเชื่อมต่อกับอุปกรณ์ผ่าน Wi-Fi

ฟังก์ชันหลัก

- Pair อุปกรณ์ผ่าน Wireless Debugging
- เชื่อมต่ออุปกรณ์ผ่าน ADB
- ติดตั้งไฟล์ APK
- รองรับไฟล์ APK แบบหลาย Split เช่น ".apks"
- จัดการอุปกรณ์ที่เคยเชื่อมต่อ
- แสดงผลการทำงานและ Error จาก ADB
- มีเครื่องมือ ADB พื้นฐานภายในแอป

เทคโนโลยีที่ใช้

- Flutter
- Dart
- Android
- ADB
- SharedPreferences

โครงสร้างโปรเจกต์

- "lib/main.dart" — ส่วนหลักของแอปและการตั้งค่าเริ่มต้น
- "lib/services/adb_service.dart" — จัดการการเชื่อมต่อและคำสั่ง ADB
- "lib/services/apks_service.dart" — จัดการไฟล์ ".apks"
- "lib/services/device_storage_service.dart" — จัดเก็บข้อมูลอุปกรณ์และประวัติการเชื่อมต่อ
- "lib/screens/" — หน้าต่างต่าง ๆ ของแอป

สถานะ

โปรเจกต์สามารถ Build เป็น APK และใช้งานได้จริงในสภาพแวดล้อมที่รองรับ ADB ผ่าน Wi-Fi

Repository

GitHub: https://github.com/Asailla/ADB-SIDELOAD-