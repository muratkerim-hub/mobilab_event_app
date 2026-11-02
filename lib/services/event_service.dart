import 'package:dio/dio.dart';
import '../models/event_model.dart';

class EventService {
  // ============================================================================
  // NEDEN BU AYARLARI YAPTIK?
  // 1. Mülakat API'si (mobilab-task-api.vercel.app) adayların hata yönetimini
  //    test etmek için yaklaşık her 4-5 istekten birinde kasıtlı olarak (Chaos Mode)
  //    "HTTP 500 Internal Server Error" döndürmekte veya yanıtı geciktirmektedir.
  // 2. Üstelik sunucu 200 OK döndüğünde "Access-Control-Allow-Origin: *" (CORS)
  //    başlığı eklerken, 500 hatası döndüğünde bu CORS başlığını eklemeyi unutmaktadır.
  // 3. Tarayıcı (Flutter Web), CORS başlığı olmayan 500 yanıtını güvenlik gereği
  //    engellediği için Dio bunu 500 hatası olarak değil, "connectionError"
  //    ("İnternet bağlantısı kurulamadı") olarak algılamaktadır.
  // 4. Bu sorunu kökünden çözmek için aşağıda "_getWithRetry" (Otomatik Yeniden
  //    Deneme) mekanizması kurduk ve zaman aşımı (timeout) süresini 12 saniyeye çıkardık.
  // ============================================================================
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://mobilab-task-api.vercel.app',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
    ),
  );

  // ============================================================================
  // NEDEN _getWithRetry FONKSİYONUNU YAZDIK?
  // Sunucu rastgele %20-25 ihtimalle 500 (veya Web'de CORS kaynaklı connectionError)
  // fırlattığında hatayı doğrudan kullanıcıya yansıtmak yerine, arka planda
  // kullanıcı hiç fark etmeden 3 kez daha deneme (toplam 4 deneme) yapar.
  // Böylece ilk açılışta hata görme ihtimali %25'ten %0.3'ün altına düşer.
  // ============================================================================
  Future<Response<dynamic>> _getWithRetry(
    String path, {
    Map<String, dynamic>? queryParameters,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        attempt++;
        return await _dio.get(path, queryParameters: queryParameters);
      } on DioException catch (e) {
        // Maksimum deneme sayısına ulaşıldıysa veya 404 gibi kalıcı bir istemci hatasıysa fırlat
        final statusCode = e.response?.statusCode;
        final isClientError =
            statusCode != null && statusCode >= 400 && statusCode < 500;

        if (attempt > maxRetries || isClientError) {
          rethrow;
        }
        // Geçici sunucu hatası (500), timeout veya Web CORS engeli durumunda döngü devam eder ve tekrar dener
      }
    }
  }

  // 1. Kategorileri Çek
  Future<List<String>> getCategories() async {
    try {
      final response = await _getWithRetry('/categories');
      if (response.statusCode == 200 && response.data is List) {
        return List<String>.from(response.data);
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Kategoriler alınırken beklenmeyen bir hata oluştu.');
    }
  }

  // 2. Etkinlikleri Listele (Filtreleme, Arama ve Sayfalama destekli)
  Future<List<Event>> getEvents({
    String? query,
    String? category,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
      };

      if (query != null && query.trim().isNotEmpty) {
        queryParams['q'] = query.trim();
      }

      if (category != null && category.isNotEmpty && category != 'Tümü') {
        queryParams['category'] = category;
      }

      final response = await _getWithRetry(
        '/events',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        // API doğrudan liste dönebilir ya da { "events": [...] } / { "items": [...] } şeklinde paketleyebilir
        List items = [];
        if (data is List) {
          items = data;
        } else if (data is Map && data.containsKey('events')) {
          items = data['events'];
        } else if (data is Map && data.containsKey('items')) {
          items = data['items'];
        }

        return items.map((json) => Event.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Etkinlikler yüklenirken bir sorun oluştu.');
    }
  }

  // 3. Tek Bir Etkinliğin Detayını Çek (/events/{id})
  Future<Event> getEventDetail(String eventId) async {
    try {
      final response = await _getWithRetry('/events/$eventId');
      if (response.statusCode == 200 && response.data != null) {
        return Event.fromJson(response.data);
      }
      throw Exception('Etkinlik detayı bulunamadı.');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Detay verisi alınamadı.');
    }
  }

  // Dio Hatalarını Anlaşılır Mesajlara Dönüştür
  String _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Sunucu çok yavaş yanıt veriyor. Lütfen tekrar deneyin.';
      case DioExceptionType.connectionError:
        return 'Sunucuya şu an ulaşılamıyor veya bağlantı kesildi. Lütfen tekrar deneyin.';
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode;
        return 'Sunucu hatası ($status). Lütfen daha sonra tekrar deneyin.';
      default:
        return 'Bağlantı sırasında bir hata oluştu.';
    }
  }
}
