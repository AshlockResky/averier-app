import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/constants.dart';

class PaymentService {
  final _db = FirebaseFirestore.instance;

  Future<void> requestPayout({
    required String userId,
    required double amount,
    required String method,
    required Map<String, dynamic> payoutDetails,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    // Security: only the owner can request payout
    if (currentUser == null || currentUser.uid != userId) {
      throw Exception('Unauthorized');
    }

    if (amount < AppConstants.minWithdrawal) {
      throw Exception('Minimum withdrawal is \ \]{AppConstants.minWithdrawal}');
    }

    final userRef = _db.collection('users').doc(userId);

    await _db.runTransaction((tx) async {
      final userDoc = await tx.get(userRef);
      if (!userDoc.exists) throw Exception('User not found');

      final balance = (userDoc.data()?['balance'] ?? 0).toDouble();
      if (balance < amount) {
        throw Exception('Insufficient balance');
      }

      // Create payout request
      final payoutRef = _db.collection('payouts').doc();
      tx.set(payoutRef, {
        'userId': userId,
        'amount': amount,
        'method': method,
        'payoutDetails': payoutDetails,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Deduct balance
      tx.update(userRef, {
        'balance': FieldValue.increment(-amount),
      });
    });
  }
}
