import 'package:cloud_firestore/cloud_firestore.dart';

class Announcement {
  final String id;
  final String title;
  final String body;
  final String groupId;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final List<String> imageUrls;

  Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.groupId,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    this.imageUrls = const [],
  });

  factory Announcement.fromMap(Map<String, dynamic> data, String documentId) {
    return Announcement(
      id: documentId,
      title: data['title'] as String,
      body: data['body'] as String,
      groupId: data['groupId'] as String,
      createdById: data['createdById'] as String,
      createdByName: data['createdByName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      imageUrls: (data['imageUrls'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'body': body,
      'groupId': groupId,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdAt': createdAt,
      'imageUrls': imageUrls,
    };
  }
}
