# 🎟️ Etkinlik Keşif Uygulaması (MOBILAB Task)

MOBILAB geliştirici değerlendirmesi kapsamında geliştirilmiş; kararsız API koşullarına dayanıklı, açık/koyu tema destekli, favoriler sayfasına, 2 sütunlu duyarlı (responsive) ızgaraya ve sonsuz kaydırma (pagination) mimarisine sahip Flutter etkinlik keşif uygulaması.

---

## 🚀 Uygulamanın Nasıl Çalıştırılacağı

### 1. Bağımlılıkların Yüklenmesi
Proje dizininde gerekli paketleri yükleyin:

```bash
flutter pub get
```

> **Kullanılan Temel Paketler:**
> - `dio`: Ağ istekleri ve hata yönetimi için.
> - `shared_preferences`: Tema tercihi ve favori etkinlikleri cihazda kalıcı olarak saklamak için.
> *(Not: State management için harici bir paket kullanılmamış, Flutter'ın yerleşik `ValueNotifier` yapısı tercih edilmiştir.)*

### 2. Uygulamayı Çalıştırma (Web - Önerilen)
Tarayıcıda (`SharedPreferences` verilerinin —seçilen favoriler ve tema tercihinin— sayfa yenilendiğinde veya uygulama kapatılıp açıldığında silinmemesi için sabit port ile) çalıştırmak için:

```bash
flutter run -d chrome --web-port=8080
```

> **Neden `--web-port=8080`?** Flutter Web'de yerel hafıza (`localStorage`) port numarasına bağlıdır. Sabit port kullanıldığında kaydettiğiniz favoriler ve tema ayarları tarayıcıyı kapatıp açsanız dahi korunur.

---

## 📁 Klasör Yapısı ve Neden Böyle Kurulduğu

Uygulama, sorumlulukların net olarak ayrıldığı (**Separation of Concerns**) sade ve katmanlı bir mimariyle kurgulanmıştır:

```text
lib/
├── models/
│   └── event_model.dart        # JSON serileştirme ve null-safety korumalı veri modeli
├── services/
│   ├── event_service.dart      # Dio tabanlı HTTP istekleri, _getWithRetry ve hata yönetimi
│   └── favorites_service.dart  # SharedPreferences ile kalıcı (disk tabanlı) favori saklama
├── screens/
│   ├── home_screen.dart        # Responsive Grid/List, arama, kategori filtresi ve infinite scroll
│   ├── detail_screen.dart      # 16:9 afiş, Hero animasyonu, asenkron etkinlik detayı
│   └── favorites_screen.dart   # Kaydedilen favori etkinliklerin listelendiği ve yönetildiği ekran
└── main.dart                   # ValueNotifier tabanlı tema kontrolü ve uygulama başlangıcı
```

### Neden Bu Yapıyı Tercih Ettim?
1. **Arayüz ve İş Mantığının Ayrılması (`screens` vs `services`):** Ekran dosyaları (`home_screen.dart`, `detail_screen.dart`, `favorites_screen.dart`) yalnızca kullanıcı etkileşimi ve görsel durumlarla ilgilenir; API çağrıları, otomatik yeniden deneme (`_getWithRetry`) ve yerel hafıza (`SharedPreferences`) işlemleri tamamen `services/` katmanında tutulmuştur.
2. **Esnek Veri Modeli (`models`):** API'den gelebilecek farklı isimlendirmeleri (`image_url` / `imageUrl`, `isOnline` / `is_online` veya konum bilgisinde `"Online"` yazması durumu) tek bir merkezde (`Event.fromJson`) karşılayarak arayüzü veri tutarsızlıklarından korudum.
3. **Gereksiz Karmaşıklıktan Kaçınma (Zero Over-Engineering):** Bu ölçekteki bir projede okunabilirliği düşüren ağır state management paketleri yerine Flutter'ın yerleşik `StatefulWidget` ve `ValueNotifier` yapılarını kullanarak her satırı anlaşılır ve bakımı kolay bir yapı kurdum.

---

## 🤖 AI'yı Nasıl Kullandım? (Araçlar, Kurallar ve Gerçek Promptlar)

Bu projeyi **Antigravity IDE (AI Pair Programmer)** ile adım adım, iteratif bir süreç izleyerek geliştirdim. AI'ya tek seferde tüm projeyi yazdırmak yerine; önce mimari sınırları çizdim, ardından uygulamayı Chrome'da test ederek karşılaştığım hataları (overflow, API kopması, görsel/etiket uyumsuzlukları) tespit edip nokta atışı promptlarla düzelttirdim.

### 🛠️ Kullanılan Araçlar
- **Antigravity IDE (Gemini tabanlı Agentic Coding Assistant):** Kod geliştirme, hata analizi, dosya düzenleme ve terminal üzerinden `flutter analyze` kontrolleri için kullanıldı.
- **Chrome & Flutter DevTools:** Responsive ekran testleri, piksel taşmaları (overflow) ve API'nin ağ davranışlarını (HTTP 500 / CORS hataları) gözlemlemek için kullanıldı.

### 📏 AI'ya Koyduğum Kurallar
AI'nın gereksiz karmaşık veya kırılgan kod üretmesini engellemek için süreç başında şu kuralları zorunlu tuttum:
1. **Over-Engineering Yasağı:** Gereksiz yere karmaşık, iç içe geçmiş soyut sınıflar veya devasa state yönetim paketleri kullanılmayacak; kod `StatefulWidget` ve `ValueNotifier` seviyesinde sade tutulacak.
2. **Minimal Paket Kuralı:** Ağ istekleri için `dio`, yerel kayıt için `shared_preferences` dışında harici paket şişkinliği yaratılmayacak.
3. **Açıklayıcı Yorum Satırları ve Mevcut Yapıyı Koruma:** Kritik mantıkların (ör. `_getWithRetry`, `ScrollController`, `resolveEventImage`) üzerine neden yazıldıklarını açıklayan Türkçe yorum satırları eklenecek ve yeni özellik eklenirken çalışan yerel kayıt yapısı bozulmayacak.

### 💬 Geliştirme Sürecinde Verdiğim Gerçek Promptlar

**1. Mimari Sınırları Çizme, Tema ve Sayfalama (Infinite Scroll) Promptu:**
> *"Asla gereksiz yere karmaşık, iç içe geçmiş, anlaşılması zor 'over-engineering' yapılar (aşırı soyut sınıflar, devasa state yönetim paketleri) KULLANMA. Kodu olabildiğince temiz, okunabilir, modüler ve Flutter standartlarına uygun (`StatefulWidget` / `ValueNotifier` seviyesinde) sade bir mimaride tut. Kodun kritik satırlarına Türkçe kısa yorum satırları ekle. `main.dart` içinde `ValueNotifier<ThemeMode>` kullanarak açık/koyu tema kontrolü sağla ve tercihi `shared_preferences` içine kaydet. `home_screen.dart` içine bir `ScrollController` bağla; kullanıcı listenin sonuna yaklaştığında API'den bir sonraki sayfayı (`page + 1`) çekip listeye eklesin."*

**2. Geniş Ekran (Responsive 2 Sütunlu Grid) ve Türkçe Tarih Formatlama Promptu:**
> *"`maxWidth: 650` kısıtı web ekranında dar bir telefon simülatörü hissi veriyor. Maksimum genişliği `1200` piksele çıkar ve ortala (`Center`). `LayoutBuilder` kullanarak ekran genişliğini kontrol et: ekran genişliği `< 800px` ise tek sütunlu liste, `>= 800px` ise 2 sütunlu (`crossAxisCount: 2`) yan yana kart dizilimi sağlayan bir `GridView` kur. API'den gelen `2026-10-17T10:00:00+03:00` gibi çiğ ISO tarih formatını kullanıcı dostu Türkçe metne dönüştüren `formatEventDate` yardımcı fonksiyonunu ekle."*

**3. 1.00 Piksel Overflow Hatası ve Akıllı Görsel Eşleştirme (`resolveEventImage`) Promptlarım:**
> *"Uzun başlıklı kartlarda (örneğin 'Startup Fikrinden MVP'ye...') kartın altında `BOTTOM OVERFLOWED BY 1.00 PIXELS` hatası çıkıyor. `GridView.builder` içindeki `mainAxisExtent: 146` değerini `156` yaparak kartlara dikeyde yeterli nefes payı ver."*
>
> *"Teknofest bölümüne Teknofest logosu koyalım. Aynı fotoğrafı 2 kere kullanmayalım; değişecek ve yerine en uygunu gelecek fotolar: AI destekli geliştirme, siber güvenlik, Flutter'da state management, oyun geliştirme jam'i. Ayrıca Skylab tanışma yemeğinin fotosunu değiştirelim, yemekle alakalı bir şey koyalım."*

**4. API Kopmaları (HTTP 500 / CORS) ve Sıralı Yükleme Promptlarım:**
> *"`_initialLoad` fonksiyonunda kategoriler ve etkinlikler aynı anda ateşlendiğinde sunucu darboğaza giriyor olabilir. Önce yerel hafızadaki favorileri anında oku, ardından ana etkinlik verisini çek, etkinlikler geldikten sonra kategorileri arka planda sessizce yükle."*
>
> *"Bu şekilde hata veriyor ne zaman siteyi açsam (ekran görüntüsü ile). Düzeltme yapacaksan neyi neden yaptığını kodun üstüne detaylıca yaz."* *(Bu prompt sonrasında sunucunun kasıtlı 500 hatası ve Web CORS engeli tespit edilerek `EventService` içerisine 3 kez otomatik yeniden deneyen `_getWithRetry` mekanizması eklendi).*

**5. Veri Tutarsızlığını (Online / Yüz Yüze Etiketi) Düzeltme Promptu:**
> *"Şimdi bir şeyi düzeltmen lazım: bazı etkinliklerin konumu Online gözüküyor ama üstte Yüz Yüze etiketi var, o etiketleri de Online yap."*

**6. Favorilerim Sayfası (`FavoritesScreen`) Ekleme Promptu:**
> *"Uygulamaya, mevcut favorileme yapısına entegre çalışacak yeni bir 'Favorilerim' sayfası (`FavoritesScreen`) ekleyelim. `SharedPreferences` ile sağladığımız kalıcı veri tutma yapısı kesinlikle bozulmayacak; favoriler anlık olarak bu sayfadan takip edilip yönetilebilecek."*

---

## ✨ Öne Çıkan Teknik Özellikler

- **Dirençli Ağ Katmanı (`_getWithRetry`):** Sunucunun rastgele fırlattığı HTTP 500 / CORS kopmalarına karşı kullanıcıya hata hissettirmeden arka planda otomatik yeniden deneme yapan `Dio` servisi (`12 sn` timeout).
- **Duyarlı Grid Mimarisi (Responsive 2-Column Grid):** `LayoutBuilder` ile mobil ekranlarda (`<800px`) tek sütunlu liste, geniş ekranlarda (`>=800px`) maksimum `1200px` genişlikte 2 sütunlu modern ızgara (`mainAxisExtent: 156`).
- **Kalıcı Favoriler ve Favorilerim Ekranı:** `SharedPreferences` ile kalıcı olarak saklanan favoriler, üst bardaki sayaç rozeti (`Badge`), önbellek destekli [`FavoritesScreen`](lib/screens/favorites_screen.dart) ve "Geri Al" (`SnackBarAction`) desteği.
- **Sıfır Paket Bağımlılıklı Tema Yönetimi:** `ValueNotifier<ThemeMode>` ve `SharedPreferences` ile kalıcı Açık/Koyu tema geçişi.
- **Akıllı Görsel Çözücü (`resolveEventImage`) & Türkçe Tarih Formatlayıcı (`formatEventDate`):** Etkinlik içeriğine göre bağlama uygun görsel eşleştirme ve ISO-8601 tarihlerini Türkçe okunabilir formata çevirme.
