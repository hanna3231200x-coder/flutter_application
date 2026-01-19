import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

// 1. นำเข้าไฟล์ main เพื่อให้รู้จักตัวแปร globalCart และ CartItem
import '../main.dart';

class KapraoPage extends StatefulWidget {
  final VoidCallback onAddToCart;
  const KapraoPage({super.key, required this.onAddToCart});

  @override
  State<KapraoPage> createState() => _KapraoPageState();
}

class _KapraoPageState extends State<KapraoPage> {
  late YoutubePlayerController _ytController;

  // พิกัดร้านสเต็ก (ในตัวเมืองลำปาง)
  final double shopLatitude = 18.2897423969351;
  final double shopLongitude = 99.49596807831392;

  double? currentLat;
  double? currentLng;
  double distance = 0;
  String travelTime = '';
  bool _isLoading = false; // ตัวแปรสำหรับสถานะการโหลด

  final MapController _mapController = MapController();
  List<LatLng> routePoints = [];

  // API Key สำหรับ OpenRouteService (ควรตรวจสอบว่า Key ยังใช้งานได้)
  final String orsApiKey =
      "5b3ce3597851110001cf6248ffa5dcfbc68844d29b0af24a23a61066";

  @override
  void initState() {
    super.initState();
    const videoUrl = 'https://www.youtube.com/watch?v=YqnBTsSko4w';
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

  // ฟังก์ชันเพิ่มสินค้าลงตะกร้า
  void _addToCart() {
    setState(() {
      int index = globalCart.indexWhere(
        (item) => item.name == "สเต็กหมูพริกไทยดำ",
      );

      if (index != -1) {
        globalCart[index].quantity++;
      } else {
        globalCart.add(
          CartItem(
            name: "สเต็กหมูพริกไทยดำ",
            price: 129.0,
            image: "assets/01.png",
          ),
        );
      }
    });

    widget.onAddToCart();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("เพิ่มสเต็กหมูพริกไทยดำลงในตะกร้าแล้ว!"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ฟังก์ชันดึงพิกัดปัจจุบัน
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showMessage("กรุณาเปิด GPS / Location");
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        _showMessage("กรุณาเปิดสิทธิ์ Location ใน Settings");
        return;
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
    } catch (e) {
      _showMessage("เกิดข้อผิดพลาด: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ฟังก์ชันเรียก API เพื่อดึงเส้นทางและเวลาเดินทาง
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

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": orsApiKey,
          "Content-Type": "application/json"
        },
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
      } else {
        print("API Error: ${response.body}");
      }
    } catch (e) {
      print("Network Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopPoint = LatLng(shopLatitude, shopLongitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text("สเต็กหมูพริกไทยดำ"),
        backgroundColor: const Color.fromARGB(255, 204, 78, 172),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ปุ่มสั่งซื้อ
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addToCart,
                icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                label: const Text(
                  "สั่งซื้อเมนูนี้ - 129 บาท",
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
              "- สันคอหมู 700 กรัม\n- เกลือ 1/2 ช้อนชา\n- นมข้นจืด 5 ช้อนโต๊ะ\n- น้ำมันมะกอก 1 1/2 ช้อนโต๊ะ\n- พริกไทยดำ 1 ช้อนชา",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 15),

            const Text(
              "วิธีทำ:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text(
              "1.เครื่องหมัก: ผสมเกลือ, นมข้นจืด, น้ำมันพืช และพริกไทยดำ \n2.เคล็ดลับ: ใส่สับปะรดเล็กน้อยช่วยให้เนื้อนุ่ม \n3.หมักในตู้เย็น 4-6 ชั่วโมง \n4.ย่างบนกระทะร้อนจัดจนสุกเด้ง",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),

            YoutubePlayer(
              controller: _ytController,
              showVideoProgressIndicator: true,
            ),
            const SizedBox(height: 30),

            const Text(
              "แผนที่นำทางไปยังร้าน:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),

            // แผนที่
            SizedBox(
              height: 300,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    center: shopPoint,
                    zoom: 14,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                      subdomains: const ['a', 'b', 'c'],
                    ),
                    MarkerLayer(
                      markers: [
                        // หมุดร้านค้า
                        Marker(
                          point: shopPoint,
                          width: 45,
                          height: 45,
                          builder: (_) => const Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 45,
                          ),
                        ),
                        // หมุดตำแหน่งปัจจุบัน (ถ้ามี)
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
                    // เส้นทางขับรถ
                    if (routePoints.isNotEmpty)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: routePoints,
                            color: Colors.blue,
                            strokeWidth: 5,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 15),

            // ปุ่มเช็คระยะทาง
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 204, 78, 172),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text("เช็คระยะทางและเวลาเดินทางไปที่ร้าน",
                        style: TextStyle(color: Colors.white)),
              ),
            ),

            // แสดงผลระยะทางและเวลา
            if (distance > 0)
              Container(
                margin: const EdgeInsets.only(top: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.directions_car, color: Colors.blue),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "ระยะทาง: ${distance.toStringAsFixed(2)} กม. \nคาดว่าจะใช้เวลา: $travelTime",
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
