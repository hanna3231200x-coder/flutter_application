import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// ตรงนี้สำคัญมาก! เพราะไฟล์ Mango_page.dart อยู่ในโฟลเดอร์ snacks
// เราต้องถอยออกมา 1 ระดับเพื่อไปหา main.dart ค่ะ
import '../main.dart';

class DurianCakePage extends StatefulWidget {
  final VoidCallback onAddToCart;
  const DurianCakePage({super.key, required this.onAddToCart});

  @override
  State<DurianCakePage> createState() => _DurianCakePageState();
}

class _DurianCakePageState extends State<DurianCakePage> {
  late YoutubePlayerController _ytController;

  final double shopLatitude = 18.283941261524387;
  final double shopLongitude = 99.49677414174985;

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
    const videoUrl = 'https://www.youtube.com/watch?v=ZN0OWTvOoVU';
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

  void _addToCart() {
    setState(() {
      // ค้นหาว่ามี ข้าวเหนียวมะม่วง ในตะกร้าหรือยัง
      int index = globalCart.indexWhere(
        (item) => item.name == "ข้าวเหนียวมะม่วง",
      );
      if (index != -1) {
        globalCart[index].quantity++;
      } else {
        globalCart.add(
          CartItem(
            name: "ข้าวเหนียวมะม่วง",
            price: 60.0,
            image:
                "assets/07.jpg", // ใช้รูป 07.jpg ตามที่ตั้งไว้ในหน้า main นะคะ
          ),
        );
      }
    });

    // แจ้งหน้า main ให้รู้ว้าตะกร้ามีการเปลี่ยนแปลง ตัวเลขจะได้ขยับ
    widget.onAddToCart();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("เพิ่มข้าวเหนียวมะม่วงลงตะกร้าแล้ว!"),
        backgroundColor: Colors.pinkAccent,
        duration: Duration(seconds: 1),
      ),
    );
  }

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
        title: const Text("ข้าวเหนียวมะม่วง"),
        backgroundColor: const Color.fromARGB(255, 255, 34, 170),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.shopping_basket, color: Colors.white),
                label: const Text(
                  "สั่งซื้อข้าวเหนียวมะม่วง - 60 บาท",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 255, 34, 170),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "วัตถุดิบ:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              "- ข้าวเหนียว\n- กะทิ\n- น้ำตาล\n- น้ำตาลทราย \n- เกลือป่น",
            ),
            const SizedBox(height: 10),
            const Text(
              "วิธีทำ:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text(
              "1. ล้างข้าวเหนียวให้สะอาด\n2. แช่ข้าวเหนียว 4-6 ชม.\n3. นึ่ง 15-25 นาที\n4. มูนข้าวกับกะทิ\n5. ทานพร้อมมะม่วงสุกหวาน",
            ),
            const SizedBox(height: 20),
            YoutubePlayer(
              controller: _ytController,
              showVideoProgressIndicator: true,
            ),
            const SizedBox(height: 30),
            const Text(
              "แผนที่ร้านอาหาร:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 300,
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
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _getCurrentLocation,
              child: const Text("อ่านพิกัดปัจจุบัน"),
            ),
            const SizedBox(height: 10),
            Text(
              "ระยะทางจากคุณถึงร้าน: ${distance.toStringAsFixed(2)} กม.",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (travelTime.isNotEmpty)
              Text("เวลาเดินทางโดยรถยนต์: $travelTime"),
          ],
        ),
      ),
    );
  }
}
