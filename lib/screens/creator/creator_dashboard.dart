import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../services/payment_service.dart';

class CreatorDashboard extends StatelessWidget {
  const CreatorDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Earnings'),
        backgroundColor: Colors.black,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final balance = (data['balance'] ?? 0).toDouble();
          final total = (data['totalEarned'] ?? 0).toDouble();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _card('Available balance', '\$${balance.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _card('Total earned', '\$${total.toStringAsFixed(2)}'),
                const SizedBox(height: 24),
                const Text(
                  'Rules',
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Video needs 5,000 views to earn\n'
                  '• Creators get 50% of ad revenue on eligible videos\n'
                  '• Minimum withdrawal: \$50',
                  style: TextStyle(color: Colors.white54),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: balance < AppConstants.minWithdrawal
                      ? null
                      : () => _requestPayout(context, uid, balance),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: Text(
                    balance < AppConstants.minWithdrawal
                        ? 'Minimum \$${AppConstants.minWithdrawal.toStringAsFixed(0)} required'
                        : 'Request payout',
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white54)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _requestPayout(BuildContext context, String uid, double balance) async {
    final methodController = TextEditingController(text: 'paypal');
    final detailController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Payout details', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: methodController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Method (paypal / bank)',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: detailController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'PayPal email or bank details',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Submit')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await context.read<PaymentService>().requestPayout(
            userId: uid,
            amount: balance,
            method: methodController.text.trim(),
            payoutDetails: {'info': detailController.text.trim()},
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payout requested')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}