import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';
import '../services/utils.dart';
import 'payment_upload_screen.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  String _selectedPaymentMethod = 'BCA Transfer';
  final Map<String, String> _paymentDetails = {
    'BCA Transfer': 'No. Rek: 1234567890\na.n. Tiramku Farm',
    'Mandiri Transfer': 'No. Rek: 0987654321\na.n. Tiramku Farm',
    'GoPay / Qris': 'No. HP: 081234567890\na.n. Tiramku',
  };

  void _processCheckout(CartProvider cart) async {
    setState(() => _isLoading = true);
    try {
      final items = cart.items.values.map((e) => {
        'product_id': e.productId,
        'quantity': e.quantity
      }).toList();

      final response = await _apiService.post('checkout', {'items': items});

      if (response.statusCode == 201) {
        cart.clear();
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Berhasil'),
            content: Text('Pesanan Anda telah dibuat. Silakan transfer ke $_selectedPaymentMethod dan unggah bukti pembayaran di menu Riwayat.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => PaymentUploadScreen(
                        transactionId: response.data['data']['id'],
                        paymentMethod: _selectedPaymentMethod,
                        paymentInstructions: _paymentDetails[_selectedPaymentMethod]!,
                      ),
                    ),
                  );
                },
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Checkout gagal')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: _isLoading 
        ? Center(child: CircularProgressIndicator())
        : Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
                SizedBox(height: 16),
                Text('Total Pembayaran: Rp ${formatNumber(cart.totalAmount)}', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 32),
                
                Text('Pilih Metode Pembayaran', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  items: _paymentDetails.keys.map((method) {
                    return DropdownMenuItem(value: method, child: Text(method));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedPaymentMethod = val);
                  },
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Instruksi Pembayaran:', style: TextStyle(fontSize: 12, color: Colors.green.shade800)),
                      SizedBox(height: 4),
                      Text(
                        _paymentDetails[_selectedPaymentMethod]!,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade900),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () => _processCheckout(cart),
                  child: Text('Konfirmasi Pesanan', style: TextStyle(fontSize: 18)),
                )
              ],
            ),
          ),
    );
  }
}
