import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobilab_event_app/main.dart';

void main() {
  testWidgets('Uygulama baslatma duman testi', (WidgetTester tester) async {
    // Test ortamında SharedPreferences için sahte (mock) başlangıç verisi tanımla
    SharedPreferences.setMockInitialValues({});

    // Uygulamayı ayağa kaldır
    await tester.pumpWidget(const MobilabEventApp());

    // Asenkron ağ zamanlayıcılarının tamamlanmasını bekle
    await tester.pumpAndSettle();

    // Uygulamanın başarıyla çizildiğini doğrula
    expect(find.byType(MobilabEventApp), findsOneWidget);
  });
}
