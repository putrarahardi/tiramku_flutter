import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/utils.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    return Scaffold(
      appBar: AppBar(title: Text('Keranjang Belanja')),
      body: Column(
        children: [
          Card(
            margin: EdgeInsets.all(15),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: TextStyle(fontSize: 20)),
                  Spacer(),
                  Chip(
                    label: Text('Rp ${formatNumber(cart.totalAmount)}', style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.green,
                  ),
                  TextButton(
                    onPressed: cart.itemCount == 0 ? null : () {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => CheckoutScreen()));
                    },
                    child: Text('CHECKOUT', style: TextStyle(color: Colors.green)),
                  )
                ],
              ),
            ),
          ),
          SizedBox(height: 10),
          Expanded(
            child: ListView.builder(
              itemCount: cart.items.length,
              itemBuilder: (ctx, i) {
                final cartItem = cart.items.values.toList()[i];
                final productId = cart.items.keys.toList()[i];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: ListTile(
                      leading: cartItem.imageUrl != null
                          ? CircleAvatar(
                              backgroundImage: NetworkImage('http://10.0.2.2:8000/storage/${cartItem.imageUrl}'),
                              backgroundColor: Colors.transparent,
                            )
                          : CircleAvatar(child: Padding(padding: EdgeInsets.all(5), child: FittedBox(child: Text('Rp${formatNumber(cartItem.price)}')))),
                      title: Text(cartItem.title),
                      subtitle: Text('Total: Rp${formatNumber(cartItem.price * cartItem.quantity)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('${cartItem.quantity} x'),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              cart.removeItem(productId);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
