# 📡 Dokumentasi Spesifikasi REST API Flask (Backend)

Dokumen ini adalah kontrak REST API over HTTPS untuk menghubungkan backend Flask dengan frontend aplikasi Flutter **Smart Home Monitoring & Control**.

---

## 1. Konfigurasi Client (Flutter)
- **Base URL:** Dapat diubah di aplikasi via menu **Profil > Pengaturan Backend & Device** atau di file `lib/core/config/api_config.dart`.
- **Default Base URL:** `https://192.168.1.100:5000` (atau IP/Domain Flask server Anda).
- **Format Pertukaran Data:** `application/json` (UTF-8).
- **Header Autentikasi:** `Authorization: Bearer <token_jwt>` (disertakan otomatis setelah login).

---

## 2. Endpoints Autentikasi

### A. Login Pengguna
- **Method:** `POST`
- **URL:** `/api/auth/login`
- **Request Body:**
```json
{
  "email": "admin@smarthome.id",
  "password": "password123"
}
```
- **Response Success (200 OK):**
```json
{
  "token": "eyJhbGciOiJIUzI1NiIsIn...",
  "user": {
    "id": "usr_001",
    "name": "Administrator Rumah",
    "email": "admin@smarthome.id",
    "role": "Owner"
  }
}
```

### B. Logout
- **Method:** `POST`
- **URL:** `/api/auth/logout`
- **Headers:** `Authorization: Bearer <token>`
- **Response (200 OK):** `{"message": "Logged out successfully"}`

---

## 3. Endpoints Telemetri Sensor

### A. Data Sensor Real-Time
- **Method:** `GET`
- **URL:** `/api/sensors/current`
- **Response (200 OK):**
```json
{
  "data": {
    "temperature": 28.4,
    "humidity": 62.0,
    "light_intensity": 45.0,
    "gas_ppm": 95.0,
    "flame_detected": false,
    "motion_detected": false,
    "door_open": false,
    "timestamp": "2026-11-07T23:25:00.000Z"
  }
}
```

### B. Histori Pembacaan Sensor
- **Method:** `GET`
- **URL:** `/api/sensors/history`
- **Response (200 OK):**
```json
{
  "history": [
    {
      "temperature": 28.1,
      "humidity": 61.5,
      "light_intensity": 44.0,
      "gas_ppm": 92.0,
      "flame_detected": false,
      "motion_detected": false,
      "door_open": false,
      "timestamp": "2026-11-07T23:15:00.000Z"
    }
  ]
}
```

---

## 4. Endpoints Kontrol Perangkat

### A. Status Seluruh Perangkat
- **Method:** `GET`
- **URL:** `/api/devices/status`
- **Response (200 OK):**
```json
{
  "status": {
    "light_on": false,
    "cooling_on": true,
    "door_locked": true,
    "light_auto_mode": true,
    "cooling_auto_mode": true,
    "target_temperature": 24.0,
    "last_updated": "2026-11-08T13:50:00.000Z"
  }
}
```

### B. Kendali Perangkat (Toggle/Setting)
- **Method:** `POST`
- **URL:** `/api/devices/control`
- **Request Body (Contoh):**
```json
{
  "device": "cooling",
  "value": true
}
```
*Daftar parameter `device` yang didukung:*
- `"light"`: `true` / `false`
- `"cooling"`: `true` / `false` (Peltier AC)
- `"door_lock"`: `true` (kunci) / `false` (buka)
- `"target_temp"`: `18.0` s/d `30.0`
- `"light_auto_mode"`: `true` / `false`
- `"cooling_auto_mode"`: `true` / `false`

---

## 5. Endpoints Pengenal Wajah & Anti-Spoofing (MiniFasNet)

### A. Daftar Wajah Terdaftar
- **Method:** `GET`
- **URL:** `/api/faces`
- **Response (200 OK):**
```json
{
  "faces": [
    {
      "id": "fc_001",
      "name": "Ahmad Fauzi",
      "role": "Kepala Keluarga",
      "registered_at": "2026-10-08T10:00:00.000Z"
    }
  ]
}
```

### B. Pendaftaran Wajah Baru
- **Method:** `POST`
- **URL:** `/api/faces/register`
- **Request Body:**
```json
{
  "name": "Budi Santoso",
  "role": "Keluarga"
}
```

### C. Riwayat Percobaan Akses & Liveness (MiniFasNet)
- **Method:** `GET`
- **URL:** `/api/faces/attempts`
- **Response (200 OK):**
```json
{
  "attempts": [
    {
      "id": "acc_001",
      "matched_name": "Ahmad Fauzi",
      "is_liveness_passed": false,
      "liveness_score": 0.14,
      "is_authorized": false,
      "message": "MiniFasNet: Manipulasi Wajah Terdeteksi (Foto/Layar)!",
      "timestamp": "2026-11-08T13:40:00.000Z"
    }
  ]
}
```

- **Response (200 OK):**
```json
{
  "status": {
    ... // Updated DeviceStatus object
  }
}
```

---

## 5. Endpoints Log Event & Peringatan

- **Method:** `GET`
- **URL:** `/api/events`
- **Response (200 OK):**
```json
{
  "events": [
    {
      "id": "evt_001",
      "title": "Akses Pintu Depan",
      "description": "Pintu dibuka oleh pengguna terdaftar.",
      "category": "door",
      "severity": "normal",
      "timestamp": "2026-11-07T23:10:00.000Z"
    },
    {
      "id": "evt_002",
      "title": "Peringatan Gas Terdeteksi",
      "description": "Kadar gas MQ-2 mencapai 230 PPM (Status: Waspada).",
      "category": "gas",
      "severity": "warning",
      "timestamp": "2026-11-07T18:15:00.000Z"
    }
  ]
}
```
