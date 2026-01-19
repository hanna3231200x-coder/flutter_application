import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// 1. นำเข้าไฟล์ main เพื่อใช้ตัวแปรตะกร้ากลาง
import '../main.dart';

class SeafoodPage extends StatefulWidget {
  // ---------------------------------------------------------
  // 2. เพิ่มพารามิเตอร์รับฟังก์ชันจากหน้าหลัก
  final VoidCallback onAddToCart;
  const SeafoodPage({super.key, required this.onAddToCart});
  // ---------------------------------------------------------

  @override
  State<SeafoodPage> createState() => _SeafoodPageState();
}

class _SeafoodPageState extends State<SeafoodPage> {
  late YoutubePlayerController _ytController;

  final double collegeLat = 18.2891;
  final double collegeLng = 99.4925;
  final double shopLatitude = 18.29077;
  final double shopLongitude = 99.49261;

  double? currentLat;
  double? currentLng;
  double distance = 0;
  String travelTime = '';

  final MapController _mapController = MapController();
  List<LatLng> routePoints = [];

  final String orsApiKey =
      "eyJvcmciOiI1YjNjZTM1OTc4NTExMTAwMDFjZjYyNDgiLCJpZCI6ImZmYTVkY2ZiYzY4ODQ0ZDI5YjBhZjI0YTIzYTYxMDY2IiwiaCI6Im11cm11cjY0In0=";

  @override
  void initState() {
    super.initState();
    const videoUrl = 'https://www.youtube.com/watch?v=1pO9B-rJeS4';
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

    currentLat = collegeLat;
    currentLng = collegeLng;
    distance = Geolocator.distanceBetween(
          collegeLat,
          collegeLng,
          shopLatitude,
          shopLongitude,
        ) /
        1000;

    _ytController = YoutubePlayerController(
      initialVideoId: videoId ?? '',
      flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
    );
  }

  @override
  void dispose() {
    _ytController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------
  // 3. ฟังก์ชันสำหรับปุ่มสั่งซื้อไข่เจียวปู
  void _addToCart() {
    setState(() {
      int index = globalCart.indexWhere((item) => item.name == "ไข่เจียวปู");
      if (index != -1) {
        globalCart[index].quantity++;
      } else {
        globalCart.add(
          CartItem(
            name: "ไข่เจียวปู",
            price: 150.0, // ตั้งราคาตามใจชอบเลยนะงับ
            image: "assets/04.jpg", // เช็คชื่อไฟล์รูปในโฟลเดอร์ assets ด้วยนะ
          ),
        );
      }
    });
    widget.onAddToCart();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("เพิ่มไข่เจียวปูลงในตะกร้าแล้ว!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }
  // ---------------------------------------------------------

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showMessage("กรุณาเปิด GPS / Location");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLat = position.latitude;
      currentLng = position.longitude;
      distance = Geolocator.distanceBetween(
            currentLat!,
            currentLng!,
            shopLatitude,
            shopLongitude,
          ) /
          1000;
    });

    _mapController.move(LatLng(currentLat!, currentLng!), 15);
    await _fetchRoute();
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _fetchRoute() async {
    if (currentLat == null || currentLng == null) return;
    final url = Uri.parse(
      'https://api.openrouteservice.org/v2/directions/driving-car/geojson',
    );
    final body = jsonEncode({
      "coordinates": [
        [currentLng!, currentLat!],
        [shopLongitude, shopLatitude],
      ],
    });

    final response = await http.post(
      url,
      headers: {"Authorization": orsApiKey, "Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coords = data['features'][0]['geometry']['coordinates'] as List;
      final summary = data['features'][0]['properties']['summary'];

      setState(() {
        routePoints = coords.map((c) => LatLng(c[1], c[0])).toList();
        travelTime = "${(summary['duration'] / 60).toStringAsFixed(0)} นาที";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopPoint = LatLng(shopLatitude, shopLongitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("ไข่เจียวปู"),
        backgroundColor: const Color.fromARGB(255, 18, 129, 8),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 4. เพิ่มปุ่มสั่งซื้อสีส้มสะดุดตา ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text(
                  "สั่งซื้อไข่เจียวปู - 150 บาท",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text(
              "วัตถุดิบ:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              "- ไข่ไก่ 4 ฟอง\n- เนื้อปู 100 กรัม\n- น้ำเปล่า 1 ชต.\n- ซีอิ้วขาวครึ่ง ชต.\n- ผงปรุงรส 1 ชช\n- น้ำมันสูงจากก้นหม้อ 1.5 นิ้ว",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            const Text(
              "วิธีทำ:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              "1. ผสมเครื่องปรุงทั้งหมดกับน้ำเปล่า คนให้เข้ากันก่อนแล้วจึงตอกไข่ใส่ลงไป\n2. ใส่เนื้อปูลงไปผสมแล้วเทใส่เหยือกปากแหลม\n3. ตั้งหม้อใส่น้ำมันให้ร้อนจัด\n4. เทไข่จากที่สูงให้เป็นสายจนหมด\n5. เมื่อเซ็ตตัวให้เทน้ำมันออกเพื่อรีดน้ำมัน\n6. พร้อมเสิร์ฟความกรอบฟู!",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            YoutubePlayer(
              controller: _ytController,
              showVideoProgressIndicator: true,
            ),
            const SizedBox(height: 30),

            const Text(
              "แผนที่ร้านอาหาร:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: shopPoint, zoom: 14),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: shopPoint,
                          width: 40,
                          height: 40,
                          builder: (_) => const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                        if (currentLat != null && currentLng != null)
                          Marker(
                            point: LatLng(currentLat!, currentLng!),
                            width: 40,
                            height: 40,
                            builder: (_) => const Icon(
                              Icons.my_location,
                              color: Colors.blue,
                              size: 40,
                            ),
                          ),
                      ],
                    ),
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.blue,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text("อัปเดตพิกัดปัจจุบัน"),
            ),
            const SizedBox(height: 10),
            Text(
              "ระยะทางจากคุณถึงร้าน: ${distance.toStringAsFixed(2)} กม.",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (travelTime.isNotEmpty)
              Text("เวลาเดินทางโดยรถยนต์: $travelTime"),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
