import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // 1. เพิ่มการ Import Firebase
import 'package:cloud_firestore/cloud_firestore.dart';
// เพิ่มเพื่อรองรับฐานข้อมูล

// Import หน้าไฟล์อาหาร/ขนม
import 'foods/KhaoSoi_page.dart';
import 'foods/Spaghett_page.dart';
import 'foods/satak_page.dart';
import 'foods/Crabomelet_page.dart';
import 'snacks/Bingsu_page.dart';
import 'snacks/Mango_page.dart';
import 'snacks/Takraw_page.dart';
import 'cart_page.dart';

// 1. โมเดลข้อมูลสินค้า
class CartItem {
  final String name;
  final double price;
  final String image;
  int quantity;

  CartItem({
    required this.name,
    required this.price,
    required this.image,
    this.quantity = 1,
  });
}

// 2. ตัวแปร Global สำหรับตะกร้า
List<CartItem> globalCart = [];

// 3. ปรับปรุงฟังก์ชัน main ให้เชื่อมต่อ Firebase
void main() async {
  // ต้องมี 2 บรรทัดนี้เพื่อให้ Firebase ทำงานบน Android ได้จ้า
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true);
  runApp(const FoodApp());
}

class FoodApp extends StatefulWidget {
  const FoodApp({super.key});

  @override
  State<FoodApp> createState() => _FoodAppState();
}

class _FoodAppState extends State<FoodApp> {
  // ฟังก์ชันอัปเดตหน้าจอเมื่อมีการเพิ่ม/ลดสินค้า
  void refreshCart() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Phakwalan App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // ใช้ดีไซน์ใหม่สวยๆ
      ),
      // กำหนดเส้นทางไปหน้าต่างๆ
      routes: {
        '/Spaghett_page': (context) => NoodlePage(onAddToCart: refreshCart),
        '/KhaoSoi_page': (context) => SomTumPage(onAddToCart: refreshCart),
        '/satak_page': (context) => KapraoPage(onAddToCart: refreshCart),
        '/Crabomelet_page': (context) => SeafoodPage(onAddToCart: refreshCart),
        '/Bingsu_page': (context) => BingsuPage(onAddToCart: refreshCart),
        '/Mango_page': (context) => DurianCakePage(onAddToCart: refreshCart),
        '/Takraw_page': (context) => KanomBuengPage(onAddToCart: refreshCart),
      },
      home: FoodMenuPage(onRefresh: refreshCart),
    );
  }
}

class FoodMenuPage extends StatelessWidget {
  final VoidCallback onRefresh;
  const FoodMenuPage({super.key, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("รายการอาหาร"),
        backgroundColor: const Color.fromARGB(255, 69, 186, 233),
        actions: [
          // ไอคอนตะกร้าสินค้าพร้อมตัวเลขแจ้งเตือน
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, size: 28),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartPage(onRefresh: onRefresh),
                    ),
                  );
                },
              ),
              if (globalCart.isNotEmpty)
                Positioned(
                  right: 5,
                  top: 5,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.red,
                    child: Text(
                      globalCart
                          .fold(0, (sum, item) => sum + item.quantity)
                          .toString(),
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle("อาหารคาว"),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildMenuCard(
                  context,
                  "สเต็กหมูพริกไทยดำ",
                  "assets/01.png",
                  "/satak_page",
                ),
                _buildMenuCard(
                  context,
                  "ข้าวซอย",
                  "assets/02.jpg",
                  "/Spaghett_page",
                ),
                _buildMenuCard(
                  context,
                  "ไข่เจียวปู",
                  "assets/03.jpg",
                  "/Crabomelet_page",
                ),
                _buildMenuCard(
                  context,
                  "สปาเก็ตตี้คาโบนาร่า",
                  "assets/04.jpg",
                  "/KhaoSoi_page",
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSectionTitle("อาหารหวาน"),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _buildMenuCard(
                  context,
                  "บิงซู",
                  "assets/05.jpg",
                  "/Bingsu_page",
                ),
                _buildMenuCard(
                  context,
                  "ข้าวเหนียวมะม่วง",
                  "assets/07.jpg",
                  "/Mango_page",
                ),
                _buildMenuCard(
                  context,
                  "ขนมตะกร้อ",
                  "assets/06.jpg",
                  "/Takraw_page",
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context,
    String title,
    String img,
    String route,
  ) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Card(
        elevation: 4,
        margin: const EdgeInsets.all(8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(15),
                ),
                child: Image.asset(
                  img,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
