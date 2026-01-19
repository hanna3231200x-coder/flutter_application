import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// 1. นำเข้าไฟล์ main เพื่อเข้าถึง globalCart และ CartItem
import '../main.dart';

class KanomBuengPage extends StatefulWidget {
  // ---------------------------------------------------------
  // 2. เพิ่มพารามิเตอร์รับฟังก์ชันแจ้งเตือนตะกร้าสินค้า
  final VoidCallback onAddToCart;
  const KanomBuengPage({super.key, required this.onAddToCart});
  // ---------------------------------------------------------

  @override
  State<KanomBuengPage> createState() => _KanomBuengPageState();
}

class _KanomBuengPageState extends State<KanomBuengPage> {
  late YoutubePlayerController _ytController;

  // พิกัดร้าน
  final double shopLatitude = 18.287508189755098;
  final double shopLongitude = 99.473505143151;

  // พิกัดผู้ใช้
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
    const videoUrl = 'https://www.youtube.com/watch?v=zErwDvoKIYs';
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
  // 3. ฟังก์ชันสำหรับกดสั่งซื้อขนมตะกร้อ
  void _addToCart() {
    setState(() {
      int index = globalCart.indexWhere((item) => item.name == "ขนมตะกร้อ");
      if (index != -1) {
        globalCart[index].quantity++;
      } else {
        globalCart.add(
          CartItem(
            name: "ขนมตะกร้อ",
            price: 35.0, // ราคาน่ารักๆ
            image:
                "assets/06.jpg", // อย่าลืมเช็คชื่อไฟล์รูปในโฟลเดอร์ assets นะครับ
          ),
        );
      }
    });
    widget.onAddToCart(); // แจ้งหน้า main ให้ refresh เลขตะกร้า
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("เพิ่มขนมตะกร้อลงในตะกร้าแล้ว!"),
        backgroundColor: Colors.redAccent,
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
      distance =
          Geolocator.distanceBetween(
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
        title: const Text("ขนมตะกร้อ"),
        backgroundColor: const Color.fromARGB(255, 219, 11, 11),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 4. ปุ่มสั่งซื้อขนม ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(
                  Icons.shopping_cart_checkout,
                  color: Colors.white,
                ),
                label: const Text(
                  "สั่งซื้อขนมตะกร้อ - 35 บาท",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 219, 11, 11),
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
              "- แป้งข้าวเจ้า\n- แป้งมัน\n- กะทิ\n- น้ำตาล/เกลือเล็กน้อย",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            const Text(
              "วิธีทำ:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              "1. ผสมแป้งข้าวเจ้าและแป้งมันให้เข้ากัน\n2. เติมกะทิ น้ำตาล และเกลือ คนให้ละลาย\n3. ใส่ข้าวโพดต้มหรือเครื่องตามชอบลงในพิมพ์\n4. นำไปนึ่งประมาณ 15-20 นาทีจนสุกใส\n5. พักให้เย็นแล้วแซะออกจากพิมพ์พร้อมทาน",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            YoutubePlayer(
              controller: _ytController,
              showVideoProgressIndicator: true,
            ),
            const SizedBox(height: 30),

            const Text(
              "แผนที่ร้านขนม:",
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
              child: const Text("เช็คพิกัดปัจจุบันของคุณ"),
            ),
            const SizedBox(height: 10),
            Text(
              "ระยะทางจากคุณ: ${distance.toStringAsFixed(2)} กม.",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (travelTime.isNotEmpty)
              Text("เวลาเดินทางโดยประมาณ: $travelTime"),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
