# Word Crush - Mobil Kelime Bulmaca Oyunu

Bu proje, mobil platformlar için Flutter programlama teknolojisi kullanılarak geliştirilmiş, Türkçe dil yapısına ve harf frekanslarına uygun akıllı mekaniklere sahip iki boyutlu bir kelime bulmaca oyunudur.

## 📊 Ekran Görüntüleri / Screenshots

### Giriş Arayüzü (Main Menu)
![Giriş Arayüzü](images/Ekran%20görüntüsü%202026-07-08%20213335.png)

### Oyun Alanı (Gameplay)
![Oyun Alanı](images/Ekran%20görüntüsü%202026-07-08%20213346.png)

### Market ve Joker Sistemi (In-Game Store)
![Market Arayüzü](images/Ekran%20görüntüsü%202026-07-08%20213356.png)

---

## 🚀 Özellikler (Türkçe)

* **Akıllı Grid Üretimi:** Oyun alanı (6x6, 8x8, 10x10) oluşturulurken Türkçe harf frekansları (A, E, İ gibi harflere yüksek; J, F, V gibi harflere düşük ağırlık) baz alınır.
* **Gelişmiş Kelime Doğrulama:** Gönderilen kelimeler önce yerel önbellekten, ardından 600'den fazla kelime içeren çevrimdışı sözlükten taranır; bulunamazsa anlık TDK API entegrasyonu tetiklenir.
* **Kesintisiz Oyun Akışı (DFS Kontrolü):** Her hamleden sonra arka planda çalışan DFS tabanlı kelime tarama algoritması, gridde oluşturulabilecek kelime sayısını hesaplar. Kelime kalmadığında alanı otomatik olarak karıştırır (`_reshuffleGrid`).
* **Özel Güç Simgeleri:** Kelime uzunluğuna göre (4 harf: Satır Temizleme, 5 harf: Alan Patlatma, 6 harf: Sütun Temizleme, 7+ harf: Mega Patlatma) özel yetenekler üretilir ve hücre tabanlı olarak saklanır.
* **Oyun İçi Ekonomi ve Market:** Oyuncular kazandıkları altınlarla 6 farklı türde joker (Balık, Çark, Lolipop Kırıcı, Serbest Takas, Karıştırma, Parti Güçlendirici) satın alabilir.
* **Yerel Veri Yönetimi:** Kullanıcı verileri, kazanılan altınlar, satın alınan jokerler ve skor geçmişi harici veritabanı bağımlılığı olmadan `SharedPreferences` ile cihazda güvenle saklanır.

## 🛠️ Uygulama Mimarisi

Sistem iki temel katmandan oluşur:

1. **Ekranlar Katmanı (UI / Presentation Layer):** Kullanıcı etkileşimlerini, animasyonları, 8 yönlü dokunma/kaydırma kontrollerini ve yerçekimi efektli harf düşme mekaniklerini yönetir.
2. **Servisler Katmanı (Service Layer):** Sözlük denetimini, TDK API HTTP isteklerini, alt kelime taramasını (`findSubwords`), combo puanlama hesabını, DFS tabanlı grid tarama süreçlerini ve `SharedPreferences` üzerinden yerel veri saklamayı yürütür.

## 📋 Kurulum ve Çalıştırma

### Ön Gereksinimler

* Flutter SDK (v3.27.4 veya üzeri)
* Dart SDK
* Android Studio / VS Code (Flutter eklentileri yüklü)

### Adımlar

1. Proje dizinine gidin:
   ```bash
   cd word_crush
   ```

2. Bağımlılıkları yükleyin:
   ```bash
   flutter pub get
   ```

3. Uygulamayı emülatör veya bağlı bir cihazda başlatın:
   ```bash
   flutter run
   ```

---

## 🚀 Features (English)

* **Weighted Random Grid Generation:** Supports 6x6, 8x8, and 10x10 puzzle grids constructed dynamically based on real Turkish letter frequencies (high weight for common letters like A, E, İ; low weight for rare ones like J, F, V).
* **Hybrid Word Validation:** Scans submitted words through a multi-tier structure — local cache memory first, then an offline dictionary containing 600+ words, and finally a real-time TDK (Turkish Language Association) API lookup if no match is found.
* **DFS-Based Solvability Check:** Runs an automated background system that checks grid solvability after each move using DFS word-search logic, instantly triggering `_reshuffleGrid()` when zero possible words remain.
* **Combo & Special Power-ups:** Rewards strategic plays based on word length, creating power tiles (Row Clear, Area Explode, Column Clear, Mega Explode) directly stored inside the game matrix.
* **In-Game Economy & Store:** Players can buy 6 different types of jokers (Fish, Wheel, Lollipop Crusher, Free Swap, Reshuffle, Party Booster) using gold balances tracked locally.
* **Local Data Management:** User data, earned gold, purchased jokers, and score history are stored securely on-device via `SharedPreferences`, with no external database dependency.

## 🛠️ Framework Architecture

Built on a clean two-layer paradigm:

1. **Presentation Layer (Screens):** Handles user interactions, animations, 8-way gesture/swipe controls, and gravity-based letter-drop mechanics.
2. **Service Layer:** Manages dictionary validation, TDK API HTTP requests, subword discovery (`findSubwords`), combo scoring calculations, DFS-based grid scanning, and local `SharedPreferences` storage.

## 📋 Installation & Execution

### Prerequisites

* Flutter SDK (v3.27.4 or higher)
* Dart SDK
* Android Studio / VS Code (with Flutter plugins installed)

### Steps

1. Navigate to the project directory:
   ```bash
   cd word_crush
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run the application on an emulator or connected device:
   ```bash
   flutter run
   ```
