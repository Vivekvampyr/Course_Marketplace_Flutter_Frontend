import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../../providers/auth_provider.dart';
import '../../services/user_service.dart';
import '../../config/api_config.dart';
import '../auth/login_screen.dart';
import '../course/course_detail_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final UserService _userService = UserService();
  List<dynamic> _enrollments = [];
  bool _loading = true;
  bool _avatarLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEnrollments();
  }

  Future<void> _loadEnrollments() async {
    setState(() => _loading = true);
    try {
      _enrollments = await _userService.getEnrollments();
    } catch (_) {
      _enrollments = [];
    }
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );
      if (picked == null) return;

      setState(() => _avatarLoading = true);

      dynamic imageFile;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        imageFile = MultipartFile.fromBytes(bytes, filename: picked.name);
      } else {
        imageFile = await MultipartFile.fromFile(
          picked.path,
          filename: picked.name,
        );
      }

      await _userService.uploadAvatar(imageFile);

      // Refresh user profile
      await ref.read(authStateProvider.notifier).refreshProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update avatar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _avatarLoading = false);
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await ref.read(authStateProvider.notifier).logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: RefreshIndicator(
        color: const Color(0xFF6C63FF),
        onRefresh: _loadEnrollments,
        child: CustomScrollView(
          slivers: [
            // ── Profile Header ───────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: const Color(0xFF6C63FF),
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 30),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        GestureDetector(
                          onTap: _pickAndUploadAvatar,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              color: Colors.white,
                            ),
                            child:
                                _avatarLoading
                                    ? const CircularProgressIndicator(
                                      color: Color(0xFF6C63FF),
                                    )
                                    : ClipOval(
                                      child:
                                          user?.avatar != null
                                              ? Image.network(
                                                '${ApiConfig.baseUrl}/${user!.avatar}',
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) =>
                                                        _avatarPlaceholder(
                                                          user.name,
                                                        ),
                                              )
                                              : _avatarPlaceholder(
                                                user?.name ?? 'U',
                                              ),
                                    ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndUploadAvatar,
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_outlined,
                                size: 16,
                                color: Color(0xFF6C63FF),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Name
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Email
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        user?.role.toUpperCase() ?? '',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Stats Row ────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  children: [
                    _statItem(
                      _enrollments.length.toString(),
                      'Enrolled',
                      Icons.school_outlined,
                    ),
                    _divider(),
                    _statItem('0', 'Completed', Icons.check_circle_outline),
                    _divider(),
                    _statItem('0', 'Reviews', Icons.star_outline),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── My Courses ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Courses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    Text(
                      '${_enrollments.length} courses',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            // ── Enrolled Courses List ────────────────────
            _loading
                ? const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        color: Color(0xFF6C63FF),
                      ),
                    ),
                  ),
                )
                : _enrollments.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyEnrollments())
                : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final enrollment = _enrollments[index];
                    final course = enrollment['course'];
                    return _buildEnrolledCourseCard(course);
                  }, childCount: _enrollments.length),
                ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // ── Settings Section ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 12)),

            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    _settingsTile(
                      icon: Icons.person_outline,
                      label: 'Edit Profile',
                      onTap: () {},
                    ),
                    _dividerLine(),
                    _settingsTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    _dividerLine(),
                    _settingsTile(
                      icon: Icons.lock_outline,
                      label: 'Change Password',
                      onTap: () {},
                    ),
                    _dividerLine(),
                    _settingsTile(
                      icon: Icons.help_outline,
                      label: 'Help & Support',
                      onTap: () {},
                    ),
                    _dividerLine(),
                    _settingsTile(
                      icon: Icons.logout,
                      label: 'Logout',
                      color: Colors.red,
                      onTap: _logout,
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrolledCourseCard(dynamic course) {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CourseDetailScreen(courseId: course['id']),
            ),
          ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(14),
              ),
              child:
                  course['thumbnail'] != null
                      ? Image.network(
                        '${ApiConfig.baseUrl}/${course['thumbnail']}',
                        width: 90,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _thumbPlaceholder(),
                      )
                      : _thumbPlaceholder(),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course['title'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course['category'] ?? '',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Enrolled',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyEnrollments() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(Icons.school_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'No enrolled courses yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Purchase a course to start learning',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      color: const Color(0xFF6C63FF).withOpacity(0.2),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: Color(0xFF6C63FF),
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF6C63FF), size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A2E),
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }

  Widget _dividerLine() {
    return Divider(
      height: 1,
      color: Colors.grey.shade100,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? Colors.grey.shade600, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? const Color(0xFF1A1A2E),
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Colors.grey.shade400,
      ),
    );
  }

  Widget _thumbPlaceholder() {
    return Container(
      width: 90,
      height: 80,
      color: const Color(0xFF6C63FF).withOpacity(0.1),
      child: const Icon(Icons.play_lesson_rounded, color: Color(0xFF6C63FF)),
    );
  }
}
