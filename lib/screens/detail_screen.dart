import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/favorites_service.dart';
import 'home_screen.dart';

class DetailScreen extends StatefulWidget {
  final String eventId;
  final String? initialImageUrl;

  const DetailScreen({
    super.key,
    required this.eventId,
    this.initialImageUrl,
  });

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final EventService _eventService = EventService();
  final FavoritesService _favoritesService = FavoritesService();

  Event? _event;
  bool _isLoading = true;
  bool _isFavorite = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchEventDetail();
    _checkFavoriteStatus();
  }

  // Etkinliğin favorilerde olup olmadığını yerel hafızadan kontrol et
  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.eventId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  // /events/{id} adresinden uzun açıklamayı (description) ve detayları çek
  Future<void> _fetchEventDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final event = await _eventService.getEventDetail(widget.eventId);
      if (mounted) {
        setState(() {
          _event = event;
          _isLoading = false;
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

  // Favoriye ekleme/çıkarma işlemini yap ve arayüzü güncelle
  Future<void> _toggleFavorite() async {
    final newStatus = await _favoritesService.toggleFavorite(widget.eventId);
    if (mounted) {
      setState(() {
        _isFavorite = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Detay verisi yüklendiyse Smart Image Resolver ile, henüz yüklenmediyse initialImageUrl ile göster
    final resolvedImageUrl = _event != null
        ? resolveEventImage(
            title: _event!.title,
            category: _event!.category,
            rawImageUrl: _event!.imageUrl,
          )
        : widget.initialImageUrl;

    return Scaffold(
      // Geniş ekranlarda (Web/Desktop) detay görünümünü de 650px ile ortalayıp sınırlıyoruz
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Afiş Görseli (16:9 Sabit En-Boy Oranı) + Üzerinde Geri ve Favori Butonları
                Stack(
                  children: [
                    // Ana sayfadaki kart ile eşleşen Hero animasyonu
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Hero(
                        tag: 'event-image-${widget.eventId}',
                        child: (resolvedImageUrl != null &&
                                resolvedImageUrl.isNotEmpty)
                            ? Container(
                                color: resolvedImageUrl
                                        .contains('Teknofest_logo')
                                    ? Colors.white
                                    : null,
                                padding: resolvedImageUrl
                                        .contains('Teknofest_logo')
                                    ? const EdgeInsets.all(24)
                                    : EdgeInsets.zero,
                                child: Image.network(
                                  resolvedImageUrl,
                                  width: double.infinity,
                                  fit: resolvedImageUrl
                                          .contains('Teknofest_logo')
                                      ? BoxFit.contain
                                      : BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      _buildBannerPlaceholder(),
                                ),
                              )
                            : _buildBannerPlaceholder(),
                      ),
                    ),

                    // Görsel üzerindeki butonların okunabilirliğini artıran hafif üst karartma
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: 110,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.55),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Afiş Görselinin Üzerindeki Geri ve Favori Butonları
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Geri Butonu
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                tooltip: 'Geri',
                                icon: const Icon(Icons.arrow_back,
                                    color: Colors.white),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            // Favori Butonu
                            CircleAvatar(
                              backgroundColor: Colors.black54,
                              child: IconButton(
                                tooltip: _isFavorite
                                    ? 'Favorilerden Çıkar'
                                    : 'Favorilere Ekle',
                                icon: Icon(
                                  _isFavorite
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: _isFavorite
                                      ? Colors.redAccent
                                      : Colors.white,
                                ),
                                onPressed: _toggleFavorite,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Alt İçerik (Yükleniyor, Hata veya Düzenli Detay Kartları)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildDetailContent(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 64.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 54,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _fetchEventDetail,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_event == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48.0),
        child: Center(child: Text('Etkinlik detayı bulunamadı.')),
      );
    }

    final event = _event!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Kart: Başlık ve Kategori / Online Etiketleri
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (event.category != null && event.category!.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.label_outline, size: 16),
                        label: Text(event.category!),
                        visualDensity: VisualDensity.compact,
                      ),
                    Chip(
                      avatar: Icon(
                        event.isOnline
                            ? Icons.videocam_outlined
                            : Icons.groups_outlined,
                        size: 16,
                      ),
                      label: Text(event.isOnline ? 'Online' : 'Yüz Yüze'),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  event.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 2. Kart: Tarih ve Konum Bilgileri
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.calendar_today_outlined,
                        color: colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tarih ve Saat',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatEventDate(event.date),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.location_on_outlined,
                        color: colorScheme.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konum',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.outline,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            event.location ?? 'Konum belirtilmemiş',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // 3. Kart: Etkinlik Hakkında Uzun Açıklama (description)
        Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 20, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'Etkinlik Hakkında',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  (event.description != null &&
                          event.description!.trim().isNotEmpty)
                      ? event.description!
                      : 'Bu etkinlik için detaylı açıklama bulunmuyor.',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerPlaceholder() {
    return Container(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Icon(
        Icons.event_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.outline,
      ),
    );
  }
}
