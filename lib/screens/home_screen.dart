import 'package:flutter/material.dart';
import '../main.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/favorites_service.dart';
import 'detail_screen.dart';
import 'favorites_screen.dart';

// API'den gelen ISO-8601 (örn: 2026-10-17T10:00:00+03:00) tarihini Türkçe okunabilir formata çevirir
String formatEventDate(String? rawDate) {
  if (rawDate == null || rawDate.trim().isEmpty) {
    return 'Tarih belirtilmemiş';
  }

  final parsed = DateTime.tryParse(rawDate);
  if (parsed == null) {
    // Eğer tarih standart ISO formatında değilse olduğu gibi döndür
    return rawDate;
  }

  final localDate = parsed.toLocal();
  const months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  final day = localDate.day;
  final monthName = months[localDate.month - 1];
  final year = localDate.year;
  final hour = localDate.hour.toString().padLeft(2, '0');
  final minute = localDate.minute.toString().padLeft(2, '0');

  return '$day $monthName $year, $hour:$minute';
}

// Etkinlik başlığına ve kategorisine göre bağlama uygun, hızlı yüklenen benzersiz görsel döndüren yardımcı fonksiyon
String resolveEventImage({
  required String title,
  String? category,
  String? rawImageUrl,
}) {
  const params = '?auto=format&fit=crop&w=600&q=80';
  final text = '${title.toLowerCase()} ${(category ?? '').toLowerCase()}';

  // 1. Teknofest (Resmi Teknofest Logosu)
  if (text.contains('teknofest')) {
    return 'https://upload.wikimedia.org/wikipedia/tr/1/1d/Teknofest_logo.png';
  }

  // 2. Tanışma Kahvaltısı / Yemek & Sosyalleşme
  if (text.contains('kahvaltı') ||
      text.contains('kahvalti') ||
      text.contains('yemek') ||
      text.contains('tanışma') ||
      text.contains('tanisma') ||
      text.contains('brunch')) {
    return 'https://images.unsplash.com/photo-1528605248644-14dd04022da1$params';
  }

  // 3. Siber Güvenlik / CTF ('hack' kelimesi Hackathon kategorisiyle çakışmaması için çıkarıldı)
  if (text.contains('siber') ||
      text.contains('güvenlik') ||
      text.contains('guvenlik') ||
      text.contains('ctf') ||
      text.contains('security')) {
    return 'https://images.unsplash.com/photo-1550751827-4bd374c3f58b$params';
  }

  // 4. Oyun Geliştirme / Game Jam
  if (text.contains('oyun') ||
      text.contains('game') ||
      text.contains('jam') ||
      text.contains('unity') ||
      text.contains('unreal')) {
    return 'https://images.unsplash.com/photo-1550745165-9bc0b252726f$params';
  }

  // 5. Yapay Zeka / AI Destekli Geliştirme / Prompt
  if (text.contains('yapay zeka') ||
      text.contains('ai ') ||
      text.startsWith('ai') ||
      text.contains('prompt') ||
      text.contains('machine learning')) {
    return 'https://images.unsplash.com/photo-1620712943543-bcc4688e7485$params';
  }

  // 6. Python & Veri Analizi / Veri Bilimi
  if (text.contains('python') ||
      text.contains('veri') ||
      text.contains('analiz') ||
      text.contains('data')) {
    return 'https://images.unsplash.com/photo-1551288049-bebda4e38f71$params';
  }

  // 7. Flutter'da State Management & Mimari
  if (text.contains('state management') || text.contains('mimari')) {
    return 'https://images.unsplash.com/photo-1551650975-87deedd944c3$params';
  }

  // 8. Tasarım, UI/UX & Figma (Figma'dan Flutter'a vb.)
  if (text.contains('tasarım') ||
      text.contains('tasarim') ||
      text.contains('ui') ||
      text.contains('ux') ||
      text.contains('figma') ||
      text.contains('design')) {
    return 'https://images.unsplash.com/photo-1561070791-2526d30994b5$params';
  }

  // 9. Mobil & Flutter Geliştirme (Flutter ile İlk Uygulamanı Yayınla vb.)
  if (text.contains('flutter') ||
      text.contains('mobil') ||
      text.contains('android') ||
      text.contains('ios') ||
      text.contains('dart')) {
    return 'https://images.unsplash.com/photo-1512941937669-90a1b58e7e9c$params';
  }

  // 10. Startup / MVP / Girişimcilik
  if (text.contains('startup') ||
      text.contains('mvp') ||
      text.contains('girişim') ||
      text.contains('girisim') ||
      text.contains('yatırım') ||
      text.contains('fikir')) {
    return 'https://images.unsplash.com/photo-1556761175-5973dc0f32e7$params';
  }

  // 11. Kariyer / Sektör Sohbetleri
  if (text.contains('kariyer') ||
      text.contains('sektör') ||
      text.contains('sektor') ||
      text.contains('sohbet') ||
      text.contains('mülakat') ||
      text.contains('mulakat') ||
      text.contains('staj')) {
    return 'https://images.unsplash.com/photo-1515187029135-18ee286d815b$params';
  }

  // 12. Açık Kaynağa İlk Katkı
  if (text.contains('açık kaynak') ||
      text.contains('acik kaynak') ||
      text.contains('open source') ||
      text.contains('katkı')) {
    return 'https://images.unsplash.com/photo-1555949963-ff9fe0c870eb$params';
  }

  // 13. Git, GitHub, Takım Çalışması & DevOps
  if (text.contains('git') ||
      text.contains('github') ||
      text.contains('devops') ||
      text.contains('docker') ||
      text.contains('cloud') ||
      text.contains('bulut')) {
    return 'https://images.unsplash.com/photo-1522071820081-009f0129c71c$params';
  }

  // 14. Web & Next.js
  if (text.contains('web') ||
      text.contains('next.js') ||
      text.contains('nextjs') ||
      text.contains('react') ||
      text.contains('javascript') ||
      text.contains('frontend') ||
      text.contains('backend')) {
    return 'https://images.unsplash.com/photo-1555066931-4365d14bab8c$params';
  }

  // 15. Demo Günü / Sunum
  if (text.contains('demo') ||
      text.contains('networking') ||
      text.contains('buluşma') ||
      text.contains('bulusma') ||
      text.contains('sunum')) {
    return 'https://images.unsplash.com/photo-1475721027785-f74eccf877e2$params';
  }

  // 16. Gecekodu / Hackathon
  if (text.contains('gecekodu') || text.contains('hackathon')) {
    return 'https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5$params';
  }

  // 17. Eğer API'den rastgele mock (picsum vb.) olmayan özel bir görsel geldiyse onu kullan
  if (rawImageUrl != null &&
      rawImageUrl.trim().isNotEmpty &&
      !rawImageUrl.contains('picsum.photos') &&
      !rawImageUrl.contains('placeholder')) {
    return rawImageUrl;
  }

  // 18. Varsayılan Modern Teknoloji & Konferans Görseli
  return 'https://images.unsplash.com/photo-1540575467063-178a50c2df87$params';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventService _eventService = EventService();
  final FavoritesService _favoritesService = FavoritesService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Event> _events = [];
  List<String> _categories = ['Tümü'];
  Set<String> _favoriteIds = {};

  String _selectedCategory = 'Tümü';
  bool _isLoading = true;
  String? _errorMessage;

  // Sayfalama (Pagination) durum değişkenleri
  int _currentPage = 1;
  final int _pageSize = 20;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _initialLoad();
    // Kullanıcı listenin/gridin sonuna yaklaştığında sonraki sayfayı çağırır
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Bellek sızıntısını (memory leak) önlemek için controller'ları temizliyoruz
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // Listenin bitimine 200 piksel kala yeni sayfa yüklemesini tetikle
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreEvents();
    }
  }

  Future<void> _initialLoad() async {
    // Önce yerel hafızadaki favorileri anında oku (ağ beklemesi yok)
    await _loadFavorites();

    // Ardından ana etkinlik verisini çek
    await _fetchEvents(reset: true);

    // Etkinlikler geldikten sonra kategorileri arka planda sessizce yükle
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _eventService.getCategories();
      if (mounted) {
        setState(() {
          _categories = ['Tümü', ...categories];
        });
      }
    } catch (_) {
      // Kategori çekilemezse varsayılan 'Tümü' kalır
    }
  }

  Future<void> _loadFavorites() async {
    final favs = await _favoritesService.getFavoriteIds();
    if (mounted) {
      setState(() {
        _favoriteIds = favs.toSet();
      });
    }
  }

  // Arama veya kategori değiştiğinde sayfayı 1'e sıfırlayarak etkinlikleri getirir
  Future<void> _fetchEvents({bool reset = true}) async {
    if (reset) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final events = await _eventService.getEvents(
        query: _searchController.text,
        category: _selectedCategory,
        page: _currentPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _events = events;
          _isLoading = false;
          // Gelen veri sayısı sayfa limitinden azsa başka sayfa kalmamıştır
          _hasMore = events.length >= _pageSize;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // Sonsuz kaydırma (Infinite Scroll) için bir sonraki sayfayı çekip mevcut listeye ekler
  Future<void> _loadMoreEvents() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final nextPage = _currentPage + 1;
      final newEvents = await _eventService.getEvents(
        query: _searchController.text,
        category: _selectedCategory,
        page: nextPage,
        limit: _pageSize,
      );

      if (mounted) {
        setState(() {
          _currentPage = nextPage;
          _events.addAll(newEvents);
          _isLoadingMore = false;
          // Yeni gelen liste boşsa veya limitten küçükse son sayfaya ulaşılmıştır
          if (newEvents.length < _pageSize) {
            _hasMore = false;
          }
        });
      }
    } catch (_) {
      // Ara sayfa yüklenirken hata olursa mevcut listeyi bozmadan yükleme durumunu kapat
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(String eventId) async {
    await _favoritesService.toggleFavorite(eventId);
    await _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              Icon(
                Icons.explore_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              const Text(
                'Etkinlik Keşif',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          // Favorilerim sayfasına geçiş butonu
          IconButton(
            tooltip: 'Favori Etkinliklerim',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(
                    cachedEvents: _events,
                  ),
                ),
              );
              // Favoriler sayfasından dönüldüğünde güncel favori listesini yükle
              _loadFavorites();
            },
            icon: Badge(
              isLabelVisible: _favoriteIds.isNotEmpty,
              label: Text('${_favoriteIds.length}'),
              child: Icon(
                _favoriteIds.isNotEmpty
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: _favoriteIds.isNotEmpty ? Colors.redAccent : null,
              ),
            ),
          ),
          // Açık / Koyu Tema değiştirme butonu
          IconButton(
            tooltip: isDark ? 'Açık Temaya Geç' : 'Koyu Temaya Geç',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Geniş ekranlarda (Web/Desktop) içeriği 1200px ile sınırlayıp ortalıyoruz
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Column(
            children: [
              // Arama Kutusu
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Etkinlik, teknoloji veya konu ara...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _fetchEvents(reset: true);
                            },
                          )
                        : null,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onSubmitted: (_) => _fetchEvents(reset: true),
                ),
              ),

              // Kategori Filtreleri (ChoiceChip Listesi)
              SizedBox(
                height: 46,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected && _selectedCategory != cat) {
                            setState(() {
                              _selectedCategory = cat;
                            });
                            // Kategori değiştiğinde sayfalama sıfırlanır (page = 1)
                            _fetchEvents(reset: true);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // Ana İçerik (Yükleniyor, Hata, Boş Liste veya Responsive Etkinlik Listesi/Gridi)
              Expanded(
                child: _buildBody(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // 1. Durum: İlk Yüklenme
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Etkinlikler yükleniyor...'),
          ],
        ),
      );
    }

    // 2. Durum: Hata Ekranı
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _fetchEvents(reset: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Durum: Boş Liste Ekranı
    if (_events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Aradığınız kriterde etkinlik bulunamadı.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _selectedCategory = 'Tümü';
                  });
                  _fetchEvents(reset: true);
                },
                icon: const Icon(Icons.filter_alt_off_outlined),
                label: const Text('Filtreleri Temizle'),
              ),
            ],
          ),
        ),
      );
    }

    // 4. Durum: LayoutBuilder ile Responsive Tek Sütun (<800px) veya 2 Sütunlu Grid (>=800px)
    return RefreshIndicator(
      onRefresh: () => _fetchEvents(reset: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          return Column(
            children: [
              Expanded(
                child: isWide
                    // Geniş ekran (>=800px): 2 Sütunlu GridView (156px yükseklik ile overflow korumalı)
                    ? GridView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 12,
                          mainAxisExtent: 156,
                        ),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final isFav = _favoriteIds.contains(event.id);
                          return _buildEventCard(event, isFav, isGrid: true);
                        },
                      )
                    // Mobil / Dar ekran (<800px): Tek Sütunlu ListView
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        itemCount: _events.length,
                        itemBuilder: (context, index) {
                          final event = _events[index];
                          final isFav = _favoriteIds.contains(event.id);
                          return _buildEventCard(event, isFav, isGrid: false);
                        },
                      ),
              ),

              // Sayfalama (Infinite Scroll) sırasında en altta dönen yükleniyor göstergesi
              if (_isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // Modern yatay etkinlik kartı: Solda sabit oranlı yuvarlatılmış görsel, sağda detaylar
  Widget _buildEventCard(Event event, bool isFav, {bool isGrid = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedImageUrl = resolveEventImage(
      title: event.title,
      category: event.category,
      rawImageUrl: event.imageUrl,
    );

    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => DetailScreen(
                eventId: event.id,
                initialImageUrl: resolvedImageUrl,
              ),
            ),
          );
          // Detay ekranından dönüldüğünde favori durumu değişmiş olabilir
          _loadFavorites();
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sol Taraf: Sabit Oranlı (115x115) Yuvarlatılmış Görsel + Hero Animasyonu
              Hero(
                tag: 'event-image-${event.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 115,
                    height: 115,
                    color: resolvedImageUrl.contains('Teknofest_logo')
                        ? Colors.white
                        : null,
                    padding: resolvedImageUrl.contains('Teknofest_logo')
                        ? const EdgeInsets.all(8)
                        : EdgeInsets.zero,
                    child: Image.network(
                      resolvedImageUrl,
                      fit: resolvedImageUrl.contains('Teknofest_logo')
                          ? BoxFit.contain
                          : BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildPlaceholderImage(),
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 14),

              // Sağ Taraf: Kategori, Online/Yüz Yüze Rozeti, Başlık, Formatlı Tarih, Konum ve Favori
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Üst Satır: Kategori & Online/Yüz Yüze Etiketi + Favori Butonu
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (event.category != null &&
                                  event.category!.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    event.category!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              // Online / Yüz Yüze Chip
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: event.isOnline
                                      ? Colors.green.withValues(alpha: 0.15)
                                      : Colors.deepOrange
                                          .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      event.isOnline
                                          ? Icons.videocam_outlined
                                          : Icons.groups_outlined,
                                      size: 12,
                                      color: event.isOnline
                                          ? Colors.green.shade700
                                          : Colors.deepOrange.shade700,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      event.isOnline ? 'Online' : 'Yüz Yüze',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: event.isOnline
                                            ? Colors.green.shade700
                                            : Colors.deepOrange.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Favori Butonu
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            tooltip:
                                isFav ? 'Favorilerden Çıkar' : 'Favorilere Ekle',
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFav
                                  ? Colors.redAccent
                                  : colorScheme.outline,
                            ),
                            onPressed: () => _toggleFavorite(event.id),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    // Kalın Etkinlik Başlığı (maxLines: 2 ve ellipsis ile taşma korumalı)
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        height: 1.22,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Türkçe Formatlanmış Tarih Bilgisi
                    if (event.date != null)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 13,
                            color: colorScheme.outline,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              formatEventDate(event.date),
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                                fontSize: 12.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    // Konum Bilgisi
                    if (event.location != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 13,
                              color: colorScheme.outline,
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                event.location!,
                                style: TextStyle(
                                  color: colorScheme.onSurfaceVariant,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 115,
      height: 115,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.event_outlined,
        size: 36,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
