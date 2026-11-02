import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _storageKey = 'favorite_event_ids';

  // 1. Kaydedilmiş tüm favori ID'lerini telefon hafızasından oku
  Future<List<String>> getFavoriteIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? [];
  }

  // 2. Favori durumunu tersine çevir (varsa sil, yoksa ekle)
  Future<bool> toggleFavorite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentFavorites = prefs.getStringList(_storageKey) ?? [];

    final bool isFav = currentFavorites.contains(eventId);

    if (isFav) {
      currentFavorites.remove(eventId);
    } else {
      currentFavorites.add(eventId);
    }

    await prefs.setStringList(_storageKey, currentFavorites);
    return !isFav; // Etkinliğin son durumunu döner (true: eklendi, false: çıkarıldı)
  }

  // 3. Bir etkinliğin favoride olup olmadığını kontrol et
  Future<bool> isFavorite(String eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> currentFavorites = prefs.getStringList(_storageKey) ?? [];
    return currentFavorites.contains(eventId);
  }
}