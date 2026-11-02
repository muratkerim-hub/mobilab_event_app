class Event {
  final String id;
  final String title;
  final String? description;
  final String? date;
  final String? location;
  final String? imageUrl;
  final String? category;
  final bool isOnline;

  Event({
    required this.id,
    required this.title,
    this.description,
    this.date,
    this.location,
    this.imageUrl,
    this.category,
    this.isOnline = false,
  });

  // API'den gelen JSON'ı Event nesnesine çeviren fabrika kurucu
  factory Event.fromJson(Map<String, dynamic> json) {
    final String? location = json['location']?.toString();
    final bool isLocationOnline =
        location != null && location.toLowerCase().contains('online');

    return Event(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'İsimsiz Etkinlik',
      description: json['description'],
      date: json['date'] ?? json['start_time'] ?? json['startDate'],
      location: location,
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['image'],
      category: json['category'],
      // API 'isOnline' (camelCase), 'is_online' (snake_case) gönderebilir veya konum 'Online' olabilir
      isOnline: (json['isOnline'] == true) ||
          (json['online'] == true) ||
          (json['is_online'] == true) ||
          isLocationOnline,
    );
  }
}
