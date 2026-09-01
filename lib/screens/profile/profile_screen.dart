import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Not logged in', style: TextStyle(color: Colors.white70))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await context.read<AuthService>().logout();
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final username = data['username'] ?? 'User';
          final email = data['email'] ?? user.email ?? '';
          final balance = (data['balance'] ?? 0).toDouble();
          final totalEarned = (data['totalEarned'] ?? 0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xFF6C63FF),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  '@$username',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(color: Colors.white54)),
                const SizedBox(height: 30),
                _infoCard('Available Balance', '\ \]{balance.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _infoCard('Total Earned', '\$${totalEarned.toStringAsFixed(2)}'),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
