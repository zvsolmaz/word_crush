# word_crush
# Word Crush - Mobil Kelime Bulmaca Oyunu

[cite_start]Bu proje, mobil platformlar için Flutter programlama teknolojisi kullanılarak geliştirilmiş, Türkçe dil yapısına ve harf frekanslarına uygun akıllı mekaniklere sahip iki boyutlu bir kelime bulmaca oyunudur.

## 📊 Ekran Görüntüleri / Screenshots

### Giriş Arayüzü (Main Menu)
![Giriş Arayüzü](images/Ekran%20görüntüsü%202026-07-08%20213335.png)

### Oyun Alanı (Gameplay)
![Oyun Alanı](images/Ekran%20görüntüsü%202026-07-08%20213356.png)

### Market ve Joker Sistemi (In-Game Store)
![Market Arayüzü](images/Ekran%20görüntüsü%202026-07-08%20213346.png)
---

## 🚀 Özellikler (Turkish)

* [cite_start]**Akıllı Grid Üretimi:** Oyun alanı (6x6, 8x8, 10x10) oluşturulurken Türkçe harf frekansları (A, E, İ gibi harflere yüksek; J, F, V gibi harflere düşük ağırlık) baz alınır[cite: 162, 226, 227].
* [cite_start]**Gelişmiş Kelime Doğrulama:** Gönderilen kelimeler önce yerel önbellekten, ardından 600'den fazla kelime içeren çevrimdışı sözlükten taranır; bulunamazsa anlık TDK API entegrasyonu tetiklenir.
* **Kesintisiz Oyun Akışı (DFS Kontrolü):** Her hamleden sonra arka planda çalışan DFS tabanlı kelime tarama algoritması, gridde oluşturulabilecek kelime sayısını hesaplar. [cite_start]Kelime kalmadığında alanı otomatik karıştırır (`_reshuffleGrid`).
* [cite_start]**Özel Güç Simgeleri:** Kelime uzunluğuna göre (4 harf: Satır Temizleme, 5 harf: Alan Patlatma, 6 harf: Sütun Temizleme, 7+ harf: Mega Patlatma) özel yetenekler üretilir ve hücre tabanlı saklanır.
* [cite_start]**Yerel Veri Yönetimi:** Kullanıcı verileri, kazanılan altınlar, satın alınan jokerler ve skor geçmişi harici veritabanı bağımlılığı olmadan `SharedPreferences` ile cihazda güvenle saklanır[cite: 372, 398].

## 🛠️ Uygulama Mimarisi

[cite_start]Sistem iki temel katmandan oluşur:
1. [cite_start]**Ekranlar Katmanı (UI):** Kullanıcı etkileşimlerini, animasyonları ve yerçekimi efektli harif kayma mekaniklerini yönetir[cite: 180, 181, 357].
2. [cite_start]**Servisler Katmanı:** Sözlük denetimi, TDK API HTTP istekleri, combo puanlama hesabı ve DFS tabanlı grid tarama süreçlerini yürütür[cite: 181, 356, 361, 368].

## 📋 Kurulum ve Çalıştırma

### Ön Gereksinimler
* [cite_start]Flutter SDK (v3.27.4 veya üzeri) [cite: 375]
* Dart SDK
* Android Studio / VS Code (Flutter eklentileri yüklü)

### Adımlar

1. Proje dizinine gidin:
``bash
cd word_crush
Bağımlılıkları yükleyin:

Bash
flutter pub get
Uygulamayı emülatör veya bağlı bir cihazda başlatın:

Bash
flutter run
Word Crush - Mobile Word Puzzle GameThis project is a 2D mobile word puzzle game developed using Flutter for Android and iOS platforms, utilizing specialized algorithms integrated with Turkish letter frequencies and morphology.  🚀 Features (English)Weighted Random Grid Generation: Supports 6x6, 8x8, and 10x10 puzzle grids constructed dynamically based on real Turkish letter frequencies.  Hybrid Word Validation: Scans requested words through a multi-tier structure: local cache memory, an offline dictionary containing 600+ words, and real-time TDK (Turkish Language Association) API endpoints.  DFS-Based Solvability Check: Executes an absolute automated system checking grid solvability after each move using DFS word-search logic. Triggers _reshuffleGrid() instantly if zero matches remain.  Combo & Special Power-ups: Rewards strategic plays based on word length, creating power tiles (Row Clear, Area Explode, Column Clear, Mega Explode) directly stored inside the game matrix.  In-Game Economy & Store: Players can buy 6 different types of jokers (Fish, Wheel, Lollipop Crusher, Free Swap, Reshuffle, Party Booster) using starting gold balances tracked locally.  🛠️ Framework ArchitectureBuilt on a clean two-layer paradigm:  Presentation Layer (Screens): Handles animations, 8-way gesture neighborhood controls, and gravity-based block-dropping mechanisms.  Service Layer: Manages heavy computational operations such as subword discovery (findSubwords), external API requests, and local SharedPreferences storage.  📋 Installation & ExecutionNavigate to the project path:Bashcd word_crush
Install Dart/Flutter packages:Bashflutter pub get
Run the application:Bashflutter run
