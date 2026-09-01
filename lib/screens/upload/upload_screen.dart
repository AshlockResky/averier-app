import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  File? _videoFile;
  bool _uploading = false;

  Future<void> _pickVideo() async {
    final picked = await ImagePicker().pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _videoFile = File(picked.path));
    }
  }

  Future<void> _upload() async {
    if (_videoFile == null || _title.text.trim().isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _uploading = true);
    try {
      final id = const Uuid().v4();
      final ref = FirebaseStorage.instance.ref().child('videos/$id.mp4');
      await ref.putFile(_videoFile!);
      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance.collection('videos').doc(id).set({
        'id': id,
        'creatorId': user.uid,
        'creatorUsername': user.email?.split('@').first ?? 'creator',
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'videoUrl': url,
        'thumbnailUrl': '',
        'views': 0,
        'likes': 0,
        'comments': 0,
        'adRevenueGenerated': 0.0,
        'isEligibleToEarn': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Video uploaded')),
        );
        _title.clear();
        _description.clear();
        setState(() => _videoFile = null);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload'),
        backgroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickVideo,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    _videoFile == null ? 'Tap to select video' : 'Video selected',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _title,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Title',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            TextField(
              controller: _description,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _uploading ? null : _upload,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C63FF),
                minimumSize: const Size.fromHeight(48),
              ),
              child: _uploading
                  ? const CircularProgressIndicator()
                  : const Text('Publish'),
            ),
          ],
        ),
      ),
    );
  }
}