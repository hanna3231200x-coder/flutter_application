import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// 1. นำเข้าไฟล์ main เพื่อใช้ตัวแปรตะกร้าและ CartItem
import '../main.dart';

class SomTumPage extends StatefulWidget {
  // ---------------------------------------------------------
  // 2. เพิ่มพารามิเตอร์รับฟังก์ชันแจ้งเตือนการเพิ่มของลงตะกร้า
  final VoidCallback onAddToCart;
  const SomTumPage({super.key, required this.onAddToCart});
  // ---------------------------------------------------------

  @override
  State<SomTumPage> createState() => _SomTumPageState();
}

class _SomTumPageState extends State<SomTumPage> {
  late YoutubePlayerController _ytController;

  final double shopLatitude = 18.292729680065868;
  final double shopLongitude = 99.50764543068901;

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
    const videoUrl = 'https://www.youtube.com/watch?v=GSoWFl0McX4';
    final videoId = YoutubePlayer.convertUrlToId(videoUrl);

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
  // 3. ฟังก์ชันสำหรับกดสั่งซื้อสปาเก็ตตี้
  void _addToCart() {
    setState(() {
      int index = globalCart.indexWhere((item) => item.name == "สปาเก็ตตี้");
      if (index != -1) {
        globalCart[index].quantity++;
      } else {
        globalCart.add(
          CartItem(
            name: "สปาเก็ตตี้",
            price: 89.0, // ราคาตามที่ที่รักต้องการเลยงับ
            image:
                "assets/03.jpg", // อย่าลืมเช็คชื่อไฟล์รูปในโฟลเดอร์ assets นะ
          ),
        );
      }
    });
    widget.onAddToCart(); // แจ้งหน้า main ให้รีเฟรชเลขตะกร้า
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("เพิ่มสปาเก็ตตี้ลงในตะกร้าแล้ว!"),
        backgroundColor: Colors.deepOrange,
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
        title: const Text("สปาเก็ตตี้คาโบนาร่า"),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 4. ปุ่มสั่งซื้อสปาเก็ตตี้ ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                label: const Text(
                  "สั่งซื้อสปาเก็ตตี้ - 89 บาท",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
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
              "- เส้นสปาเกตตี\n- เบคอน\n- น้ำมันมะกอก\n- หอมหัวใหญ่หั่นเต๋า\n- ไข่",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            const Text(
              "วิธีทำ:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              "1. ต้มเส้นจนนุ่ม\n2. ผัดเบคอนและหอมหัวใหญ่กับน้ำมันมะกอก\n3. ปิดไฟ ใส่ไข่และชีสลงคลุกคนเร็วๆ ให้เป็นซอส\n4. ตักใส่จาน โรยพริกไทยตามชอบ",
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
