import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';

class CatalogScreen extends StatefulWidget {
  @override
  _CatalogScreenState createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  void _fetchProducts() async {
    try {
      final response = await _apiService.get('products');
      if (response.statusCode == 200) {
        setState(() {
          _products = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Katalog Baglog'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => CartScreen()));
                },
              ),
              if (cart.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                    constraints: BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text('${cart.itemCount}', textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                )
            ],
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: EdgeInsets.all(10),
              itemCount: _products.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3 / 4,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemBuilder: (ctx, i) {
                final prod = _products[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: GridTile(
                    footer: GridTileBar(
                      backgroundColor: Colors.black87,
                      title: Text(prod['name'], textAlign: TextAlign.center),
                      subtitle: Text('Rp ${prod['price']}'),
                      trailing: IconButton(
                        icon: Icon(Icons.add_shopping_cart, color: Colors.greenAccent),
                        onPressed: () {
                          cart.addItem(prod['id'], prod['price'], prod['name']);
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('Ditambahkan ke keranjang!'),
                            duration: Duration(seconds: 2),
                          ));
                        },
                      ),
                    ),
                    child: Container(
                      color: Colors.white,
                      child: Icon(Icons.eco, size: 80, color: Colors.green.shade200), // Placeholder image
                    ),
                  ),
                );
              },
            ),
    );
  }
}
