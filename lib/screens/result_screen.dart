import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Match Result")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Match Found!", style: TextStyle(fontSize: 22)),
            SizedBox(height: 10),
            Text("Pet Name: Bruno"),
            Text("Owner: Dikshant"),
            Text("Contact: 98XXXXXXXX"),
          ],
        ),
      ),
    );
  }
}
