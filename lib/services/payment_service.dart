import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final _db = FirebaseFirestore.instance;

  Future<void> requestPayout({
    required String userId,
    required double amount,
    required String method,
    required Map<String, dynamic> payoutDetails,
  }) async {
    await _db.collection('payouts').add({
      'userId': userId,
      'amount': amount,
      'method': method,
      'payoutDetails': payoutDetails,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(userId).update({'balance': FieldValue.increment(-amount)});
  }
}