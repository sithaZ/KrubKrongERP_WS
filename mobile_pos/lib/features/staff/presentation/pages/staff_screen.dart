import 'package:flutter/material.dart';

/// Staff management screen
class StaffScreen extends StatelessWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: Add staff
            },
            icon: const Icon(Icons.person_add_outlined),
          ),
        ],
      ),
      body: const Center(
        child: Text('Staff Module - Staff List Here'),
      ),
    );
  }
}
