import 'package:flutter/material.dart';

/// POS Screen - Product listing and cart
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Point of Sale'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Open cart
            },
            icon: const Badge(
              child: Icon(Icons.shopping_cart_outlined),
            ),
          ),
        ],
      ),
      body: const Center(
        child: Text('POS Module - Products Grid Here'),
      ),
    );
  }
}
