import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../services/firestore_service.dart';
import '../models/announcement_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AnnouncementsScreen extends StatefulWidget {
  static const String id = 'announcements_screen';

  const AnnouncementsScreen({super.key});

  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _groupName = 'Loading...';
  String _userGroupId = '';
  String _creatorName = '';
  String _creatorId = '';

  bool _isLoadingHeader = true;
  bool _hasGroupError = false;
  bool _isFormVisible = false;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHeaderData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadHeaderData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      _creatorId = user?.uid ?? '';

      // groupId + nazwa grupy
      final groupId = await _firestoreService.getCurrentUserGroupId();
      final groupName = await _firestoreService.getGroupName(groupId);

      // dane użytkownika
      final profile = await _firestoreService.getCurrentUserProfile();
      final firstName = profile?['firstName'] ?? '';
      final lastName = profile?['lastName'] ?? '';
      final fullName =
          [firstName, lastName].where((x) => x.isNotEmpty).join(' ');

      if (mounted) {
        setState(() {
          _userGroupId = groupId;
          _groupName = groupName;
          _creatorName = fullName.isNotEmpty ? fullName : 'Someone';
          _isLoadingHeader = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _groupName = 'No group found';
          _isLoadingHeader = false;
          _hasGroupError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading group data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _toggleForm() {
    setState(() {
      _isFormVisible = !_isFormVisible;
      if (!_isFormVisible) {
        _titleController.clear();
        _bodyController.clear();
      }
    });
  }

  Future<void> _submitAnnouncement() async {
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty ||
        _userGroupId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _userGroupId.isEmpty
                ? 'Error: You must belong to a group to add announcements.'
                : 'Please fill in title and message.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final announcement = Announcement(
      id: '',
      title: _titleController.text.trim(),
      body: _bodyController.text.trim(),
      groupId: _userGroupId,
      createdById: _creatorId,
      createdByName: _creatorName,
      createdAt: DateTime.now(),
    );

    try {
      await _firestoreService.addAnnouncement(announcement);
      if (mounted) {
        _toggleForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Announcement added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding announcement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAnnouncementDetails(Announcement announcement) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          title: Text(
            announcement.title,
            style: const TextStyle(
              color: textColor,
              fontFamily: appFontFamily,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.body,
                  style: const TextStyle(
                    color: textColor,
                    fontFamily: appFontFamily,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Posted by ${announcement.createdByName}',
                  style: const TextStyle(
                    color: lightTextColor,
                    fontFamily: appFontFamily,
                    fontSize: 13,
                  ),
                ),
                Text(
                  DateFormat('dd.MM.yyyy HH:mm').format(announcement.createdAt),
                  style: const TextStyle(
                    color: lightTextColor,
                    fontFamily: appFontFamily,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(fontFamily: appFontFamily),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Group announcements',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    fontFamily: appFontFamily,
                  ),
                ),
                Text(
                  'Post important info for your roommates',
                  style: TextStyle(
                    color: lightTextColor,
                    fontSize: 13,
                    fontFamily: appFontFamily,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _toggleForm,
            child: Text(_isFormVisible ? 'Cancel' : 'New'),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAnnouncementForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor, width: 2),
      ),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: const TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
              ),
              filled: true,
              fillColor: primaryColor.withAlpha(38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
              color: textColor,
              fontFamily: appFontFamily,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Message',
              labelStyle: const TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
              ),
              alignLabelWithHint: true,
              filled: true,
              fillColor: primaryColor.withAlpha(38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(
              color: textColor,
              fontFamily: appFontFamily,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAnnouncement,
              child: const Text('Post announcement'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnnouncementsList() {
    return StreamBuilder<List<Announcement>>(
      stream: _firestoreService.getAnnouncements(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading announcements: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return const Center(
            child: Text(
              'No announcements yet.\nBe the first to post one!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: lightTextColor,
                fontFamily: appFontFamily,
              ),
            ),
          );
        }

        return ListView.separated(
          itemCount: announcements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return GestureDetector(
              onTap: () => _showAnnouncementDetails(announcement),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: textColor, width: 2),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            announcement.title,
                            style: const TextStyle(
                              color: textColor,
                              fontFamily: appFontFamily,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            announcement.body.length > 120
                                ? '${announcement.body.substring(0, 120)}...'
                                : announcement.body,
                            style: const TextStyle(
                              color: textColor,
                              fontFamily: appFontFamily,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                announcement.createdByName,
                                style: const TextStyle(
                                  color: lightTextColor,
                                  fontFamily: appFontFamily,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                DateFormat('dd.MM.yyyy HH:mm')
                                    .format(announcement.createdAt),
                                style: const TextStyle(
                                  color: lightTextColor,
                                  fontFamily: appFontFamily,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: textColor),
        title: Column(
          children: [
            const Text(
              'ROOMIES',
              style: TextStyle(
                color: textColor,
                fontFamily: appFontFamily,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                fontSize: 20,
              ),
            ),
            Text(
              _groupName,
              style: const TextStyle(
                color: lightTextColor,
                fontFamily: appFontFamily,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Announcements',
                style: TextStyle(
                  color: textColor,
                  fontFamily: appFontFamily,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildHeaderCard(),
            const SizedBox(height: 10),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: _isFormVisible
                  ? Column(
                      children: [
                        _buildNewAnnouncementForm(),
                        const SizedBox(height: 12),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _buildAnnouncementsList(),
            ),
          ],
        ),
      ),
    );
  }
}
