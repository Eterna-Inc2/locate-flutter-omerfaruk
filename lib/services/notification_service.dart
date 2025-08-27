import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  int _idCounter = 2000;
  int _nextId() => _idCounter++;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);
    // İzinler
    await _requestPermissions();

    // Android kanalını garanti altına al
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'geofence_channel',
        'Geofence Alerts',
        description: 'Güvenli alan ihlalleri için bildirim kanalı',
        importance: Importance.high,
      ),
    );
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    // iOS/macOS izinleri
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    // Android 13+ bildirim izni
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  Future<void> showGeofenceBreach(
    String deviceId,
    double distanceMeters,
    double radiusMeters,
  ) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'geofence_channel',
          'Geofence Alerts',
          channelDescription: 'Güvenli alan ihlalleri için bildirim kanalı',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = 'Güvenli Alan İhlali';
    final String body =
        'Cihaz $deviceId güvenli alanın dışında: ${(distanceMeters / 1000).toStringAsFixed(2)} km > ${(radiusMeters / 1000).toStringAsFixed(2)} km';

    await _plugin.show(_nextId(), title, body, details);
  }

  Future<void> showGeofenceEnter(
    String deviceId,
    double distanceMeters,
    double radiusMeters,
  ) async {
    if (!_initialized) await init();

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'geofence_channel',
          'Geofence Alerts',
          channelDescription: 'Güvenli alan ihlalleri için bildirim kanalı',
          importance: Importance.high,
          priority: Priority.high,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
      presentBadge: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final String title = 'Güvenli Alana Geri Döndü';
    final String body = 'Cihaz $deviceId güvenli alanın içine geri girdi.';

    await _plugin.show(_nextId(), title, body, details);
  }
}
