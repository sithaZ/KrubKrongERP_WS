import 'package:flutter/material.dart';
import '../../../../core/core.dart';

/// POS Screen - Product listing and cart
class PosScreen extends StatelessWidget {
  const PosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Point of Sale')),
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
      body: Center(
        child: Text(context.tr('POS Module - Products Grid Here')),
      ),
    );
  }
}
