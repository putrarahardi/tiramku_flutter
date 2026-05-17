import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/api_service.dart';

class CheckoutScreen extends StatefulWidget {
  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

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
            content: Text('Pesanan Anda telah dibuat. Silakan lakukan pembayaran.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(); // Go back to cart
                  Navigator.of(context).pop(); // Go back to catalog/home
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
                Icon(Icons.check_circle_outline, size: 100, color: Colors.green),
                SizedBox(height: 24),
                Text('Total Pembayaran: Rp ${cart.totalAmount}', textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: 48),
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
