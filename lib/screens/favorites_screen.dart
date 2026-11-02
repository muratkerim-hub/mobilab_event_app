import 'package:flutter/material.dart';
import '../main.dart';
import '../models/event_model.dart';
import '../services/event_service.dart';
import '../services/favorites_service.dart';
import 'detail_screen.dart';
import 'home_screen.dart';

class FavoritesScreen extends StatefulWidget {
  final List<Event> cachedEvents;

  const FavoritesScreen({
    super.key,
    this.cachedEvents = const [],
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final EventService _eventService = EventService();
  final FavoritesService _favoritesService = FavoritesService();

  List<Event> _favoriteEvents = [];
  Set<String> _favoriteIds = {};
  bool _isLoading = true;
  String? _errorMessage;

  // Ana sayfadan gelen veya detaydan çekilen etkinlikleri bellekte tutan önbellek
  final Map<String, Event> _eventsCache = {};

  @override
  void initState() {
    super.initState();
    for (final event in widget.cachedEvents) {
      _eventsCache[event.id] = event;
    }
    _loadFavoriteEvents();
  }

  Future<void> _loadFavoriteEvents({bool forceRefresh = false}) async {
    final favIds = await _favoritesService.getFavoriteIds();

    if (!mounted) return;

    if (favIds.isEmpty) {
      setState(() {
        _favoriteIds = {};
        _favoriteEvents = [];
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    // Önbellekte olmayan (örn: 2. sayfada kalmış) favori ID'leri tespit et
    final missingIds = forceRefresh
        ? favIds
        : favIds.where((id) => !_eventsCache.containsKey(id)).toList();

    // Eğer tüm favoriler önbellekte mevcutsa ağ isteği beklemeden anında göster
    if (missingIds.isEmpty) {
      setState(() {
        _favoriteIds = favIds.toSet();
        _favoriteEvents = favIds
            .where((id) => _eventsCache.containsKey(id))
            .map((id) => _eventsCache[id]!)
            .toList();
        _isLoading = false;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Eksik olan etkinlikleri API'den paralel olarak çek
      final fetchedEvents = await Future.wait(
        missingIds.map((id) => _eventService.getEventDetail(id)),
      );

      for (final event in fetchedEvents) {
        _eventsCache[event.id] = event;
      }

      if (mounted) {
        final currentFavIds = await _favoritesService.getFavoriteIds();
        setState(() {
          _favoriteIds = currentFavIds.toSet();
          _favoriteEvents = currentFavIds
              .where((id) => _eventsCache.containsKey(id))
              .map((id) => _eventsCache[id]!)
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        // Kısmi önbellek varsa onu göster, hiç yoksa hata mesajını yansıt
        final cachedFavs = favIds
            .where((id) => _eventsCache.containsKey(id))
            .map((id) => _eventsCache[id]!)
            .toList();

        setState(() {
          _favoriteIds = favIds.toSet();
          _favoriteEvents = cachedFavs;
          if (cachedFavs.isEmpty) {
            _errorMessage = e.toString().replaceAll('Exception: ', '');
          }
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite(Event event) async {
    await _favoritesService.toggleFavorite(event.id);
    await _loadFavoriteEvents();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${event.title}" favorilerden çıkarıldı.'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Geri Al',
            onPressed: () async {
              await _favoritesService.toggleFavorite(event.id);
              await _loadFavoriteEvents();
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 8),
              const Text(
                'Favori Etkinliklerim',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              if (_favoriteEvents.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_favoriteEvents.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Açık Temaya Geç' : 'Koyu Temaya Geç',
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: toggleTheme,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Favori etkinlikler yükleniyor...'),
          ],
        ),
      );
    }

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
                onPressed: () => _loadFavoriteEvents(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (_favoriteEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.favorite_border_rounded,
                size: 72,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              const Text(
                'Henüz favorilediğiniz bir etkinlik yok.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Beğendiğiniz etkinliklerin üzerindeki kalp ikonuna dokunarak buraya ekleyebilirsiniz.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.explore_outlined),
                label: const Text('Etkinlikleri Keşfet'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadFavoriteEvents(forceRefresh: true),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 800;

          if (isWide) {
            return GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 12,
                mainAxisExtent: 156,
              ),
              itemCount: _favoriteEvents.length,
              itemBuilder: (context, index) {
                final event = _favoriteEvents[index];
                final isFav = _favoriteIds.contains(event.id);
                return _buildEventCard(event, isFav, isGrid: true);
              },
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _favoriteEvents.length,
            itemBuilder: (context, index) {
              final event = _favoriteEvents[index];
              final isFav = _favoriteIds.contains(event.id);
              return _buildEventCard(event, isFav, isGrid: false);
            },
          );
        },
      ),
    );
  }

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
          // Detay ekranından dönüldüğünde favori durumu değişmişse listeyi güncelle
          _loadFavoriteEvents();
        },
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                            tooltip: 'Favorilerden Çıkar',
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 20,
                              color: isFav
                                  ? Colors.redAccent
                                  : colorScheme.outline,
                            ),
                            onPressed: () => _toggleFavorite(event),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
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

