import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../constants.dart';
import '../services/firestore_service.dart';
import '../models/announcement_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart' show SettableMetadata;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../widgets/menu_bar.dart' as mb; // Import drawera

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

  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];
  List<Uint8List> _selectedImageBytes = []; // for web previews

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
        _selectedImages = [];
        _selectedImageBytes = [];
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

    try {
      // 1. Upload zdjęć (jeśli są)
      final imageUrls = await _uploadImagesAndGetUrls();

      // 2. Stwórz ogłoszenie
      final announcement = Announcement(
        id: '',
        title: _titleController.text.trim(),
        body: _bodyController.text.trim(),
        groupId: _userGroupId,
        createdById: _creatorId,
        createdByName: _creatorName,
        createdAt: DateTime.now(),
        imageUrls: imageUrls,
      );

      // 3. Zapisz w Firestore
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
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  announcement.body,
                  style: const TextStyle(
                    color: textColor,
                    fontFamily: appFontFamily,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                if (announcement.imageUrls.isNotEmpty) ...[
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: announcement.imageUrls.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            announcement.imageUrls[index],
                            width: 160,
                            height: 160,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'By ${announcement.createdByName}',
                      style: const TextStyle(
                        color: lightTextColor,
                        fontFamily: appFontFamily,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Close',
                style: TextStyle(
                  fontFamily: appFontFamily,
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage();
      if (!mounted || images == null) return;

      if (kIsWeb) {
        final bytesList = <Uint8List>[];
        for (final img in images) {
          bytesList.add(await img.readAsBytes());
        }

        setState(() {
          _selectedImages = images;
          _selectedImageBytes = bytesList;
        });
      } else {
        setState(() {
          _selectedImages = images;
          _selectedImageBytes = [];
        });
      }
    } catch (e, st) {
      debugPrint('Error adding announcement: $e');
      debugPrint('Stack trace: $st');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding announcement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<String>> _uploadImagesAndGetUrls() async {
    if (_selectedImages.isEmpty) return [];

    final storage = FirebaseStorage.instance;
    final List<String> urls = [];

    for (int i = 0; i < _selectedImages.length; i++) {
      final ref = storage.ref().child(
            'announcements/$_userGroupId/${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
          );

      UploadTask uploadTask;

      if (kIsWeb) {
        final data = _selectedImageBytes[i];
        uploadTask = ref.putData(
          data,
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        final file = File(_selectedImages[i].path);
        uploadTask = ref.putFile(file);
      }

      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  // --- UI WIDGETS (Clean Style) ---

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // JASNE TŁO
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor), // Delikatna ramka
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Announcements',
                style: TextStyle(
                  color: lightTextColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  fontFamily: appFontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'What\'s new?',
                style: const TextStyle(
                  color: textColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  fontFamily: appFontFamily,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          // Przycisk "+" (Action Button)
          Material(
            color: primaryColor,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _toggleForm,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      _isFormVisible ? Icons.close : Icons.add,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isFormVisible ? 'Close' : 'New',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: appFontFamily,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewAnnouncementForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: textColor.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("New Post",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    fontFamily: appFontFamily)),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Title',
              prefixIcon: const Icon(Icons.title, color: lightTextColor),
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _bodyController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Write your message here...',
              hintStyle: TextStyle(color: textColor.withOpacity(0.5)),
              filled: true,
              fillColor: surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: textColor, fontFamily: appFontFamily),
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: _pickImages,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.photo_library_rounded,
                      color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedImages.isEmpty
                        ? 'Add photos'
                        : '${_selectedImages.length} photos selected',
                    style: const TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontFamily: appFontFamily,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.memory(
                            _selectedImageBytes[index],
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(_selectedImages[index].path),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitAnnouncement,
              child: const Text('Post Announcement'),
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
            child: CircularProgressIndicator(color: primaryColor),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading announcements',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined,
                    size: 64, color: lightTextColor.withOpacity(0.3)),
                const SizedBox(height: 16),
                const Text(
                  'No announcements yet.\nBe the first to post one!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: lightTextColor,
                    fontFamily: appFontFamily,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 40),
          itemCount: announcements.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final announcement = announcements[index];
            return GestureDetector(
              onTap: () => _showAnnouncementDetails(announcement),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                  boxShadow: [
                    BoxShadow(
                      color: textColor.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
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
                            announcement.body,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: lightTextColor,
                              fontFamily: appFontFamily,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                announcement.createdByName,
                                style: const TextStyle(
                                  color: primaryColor,
                                  fontFamily: appFontFamily,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM')
                                    .format(announcement.createdAt),
                                style: const TextStyle(
                                  color: lightTextColor,
                                  fontFamily: appFontFamily,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (announcement.imageUrls.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          announcement.imageUrls[0],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ]
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
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded, size: 28, color: textColor),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
        title: Column(
          children: [
            const Text(
              'ROOMIES',
              style: TextStyle(
                color: primaryColor,
                fontFamily: 'StackSansNotch',
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                fontSize: 20,
              ),
            ),
            Text(
              _groupName.isNotEmpty ? _groupName.toUpperCase() : '',
              style: const TextStyle(
                color: lightTextColor,
                fontFamily: appFontFamily,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.notifications_none_rounded,
        //         size: 28, color: textColor),
        //     onPressed: () {},
        //   ),
        // ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Column(
          children: [
            const Center(
              child: Text(
                'Updates',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                  fontFamily: appFontFamily,
                  letterSpacing: -1.0,
                ),
              ),
            ),
            const SizedBox(height: 20),
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
      drawer: mb.CustomDrawer(roomName: _groupName, groupId: _userGroupId, currentRoute: "announcements",),
    );
  }
}