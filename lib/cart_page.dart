import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. เพิ่มตัวเชื่อม Firebase
import 'main.dart';

class CartPage extends StatefulWidget {
  final VoidCallback onRefresh;
  const CartPage({super.key, required this.onRefresh});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  // ฟังก์ชันคำนวณราคารวม
  double get total =>
      globalCart.fold(0, (sum, item) => sum + (item.price * item.quantity));

  // --- 2. ฟังก์ชันพิเศษสำหรับส่งข้อมูลไป Firebase ---
  Future<void> saveOrderToFirebase() async {
    try {
      // เตรียมข้อมูลรายการอาหารแปลงเป็น List ของ Map
      List<Map<String, dynamic>> itemsData = globalCart.map((item) {
        return {
          'name': item.name,
          'price': item.price,
          'quantity': item.quantity,
          'subtotal': item.price * item.quantity,
        };
      }).toList();

      // บันทึกลงคอลเลกชันชื่อ 'orders'
      await FirebaseFirestore.instance.collection('orders').add({
        'items': itemsData,
        'totalAmount': total,
        'orderTimestamp': FieldValue.serverTimestamp(),
        'status': 'รอดำเนินการ',
      });

      // เมื่อบันทึกสำเร็จ ให้ล้างตะกร้าสินค้า
      setState(() {
        globalCart.clear();
      });
      widget.onRefresh(); // อัปเดตตัวเลขหน้าหลักให้เป็น 0

      // แสดงข้อความสำเร็จ
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("รับรายการแล้วค่ะ"),
          ),
        );
        Navigator.pop(context); // กลับหน้าหลัก
      }
    } catch (e) {
      // ถ้าพลาด ให้แจ้งเตือน
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("เกิดข้อผิดพลาด: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ตะกร้าสินค้าของฉัน"),
        backgroundColor: Colors.orange,
      ),
      body: globalCart.isEmpty
          ? const Center(
              child: Text("ตะกร้ายังว่างอยู่จ้า กลับไปเลือกอาหารก่อนนะ"),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: globalCart.length,
                    itemBuilder: (context, index) {
                      final item = globalCart[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        child: ListTile(
                          leading: Image.asset(
                            item.image,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text("ราคาต่อชิ้น: ${item.price} บาท"),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.remove_circle,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      if (item.quantity > 1) {
                                        item.quantity--;
                                      } else {
                                        globalCart.removeAt(index);
                                      }
                                    });
                                    widget.onRefresh();
                                  },
                                ),
                                Text(
                                  '${item.quantity}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.add_circle,
                                    color: Colors.green,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      item.quantity++;
                                    });
                                    widget.onRefresh();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildTotalSection(),
              ],
            ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.3), blurRadius: 10),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "ยอดรวมทั้งหมด:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "${total.toStringAsFixed(2)} บาท",
                style: const TextStyle(
                  fontSize: 22,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("ยืนยันการสั่งซื้อ"),
                  content: Text(
                    "ยอดรวมทั้งหมดของคุณคือ ${total.toStringAsFixed(2)} บาท",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("ยกเลิก"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // ปิดหน้าต่างถาม
                        saveOrderToFirebase(); // 3. เรียกใช้ฟังก์ชันส่งค่าไป Firebase
                      },
                      child: const Text("ตกลง"),
                    ),
                  ],
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              "ยืนยันรายการสั่งซื้อ",
              style: TextStyle(fontSize: 18, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
