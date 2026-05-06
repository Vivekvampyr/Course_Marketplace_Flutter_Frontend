import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/lecture_model.dart';
import '../../models/review_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/course_provider.dart';
import '../../services/cart_service.dart';
import '../../services/course_service.dart';
import '../../services/review_service.dart';
import '../../config/api_config.dart';
import '../player/video_player_screen.dart';

class CourseDetailScreen extends ConsumerStatefulWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends ConsumerState<CourseDetailScreen> {
  final CartService _cartService = CartService();
  final ReviewService _reviewService = ReviewService();
  final CourseService _courseService = CourseService();

  List<LectureModel> _lectures = [];
  List<ReviewModel> _reviews = [];
  double _avgRating = 0.0;
  int _totalReviews = 0;
  bool _isEnrolled = false;
  bool _inCart = false;
  bool _loading = false;
  bool _cartLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _courseService.isEnrolled(widget.courseId),
        _reviewService.getCourseRating(widget.courseId),
        _reviewService.getCourseReviews(widget.courseId),
      ]);

      setState(() {
        _isEnrolled = results[0] as bool;
        final rating = results[1] as Map<String, dynamic>;
        _avgRating = (rating['average_rating'] as num).toDouble();
        _totalReviews = rating['total_reviews'] as int;
        _reviews = results[2] as List<ReviewModel>;
      });
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _addToCart() async {
    setState(() => _cartLoading = true);
    try {
      await _cartService.addToCart(widget.courseId);
      setState(() => _inCart = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Added to cart!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    setState(() => _cartLoading = false);
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '';
    final m = (seconds / 60).floor();
    final s = (seconds % 60).floor();
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final courseAsync = ref.watch(selectedCourseProvider(widget.courseId));

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FA),
      body: courseAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
        error: (e, _) => Center(child: Text(e.toString())),
        data:
            (course) => CustomScrollView(
              slivers: [
                // ── App Bar with thumbnail ───────────────────
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: const Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  flexibleSpace: FlexibleSpaceBar(
                    background:
                        course.thumbnail != null
                            ? Image.network(
                              '${ApiConfig.baseUrl}/${course.thumbnail}',
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => _thumbnailPlaceholder(),
                            )
                            : _thumbnailPlaceholder(),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Category + Level ─────────────────
                        Row(
                          children: [
                            if (course.category != null)
                              _chip(course.category!, const Color(0xFF6C63FF)),
                            const SizedBox(width: 8),
                            _chip(course.level, Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ── Title ────────────────────────────
                        Text(
                          course.title,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // ── Rating ───────────────────────────
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (i) => Icon(
                                i < _avgRating.round()
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                color: Colors.amber,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_avgRating ($_totalReviews reviews)',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Description ──────────────────────
                        if (course.description != null) ...[
                          const Text(
                            'About this course',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            course.description!,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],

                        // ── Lectures ─────────────────────────
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Course Content',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_lectures.length} lectures',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        _lectures.isEmpty
                            ? Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'No lectures yet',
                                  style: TextStyle(color: Colors.grey.shade500),
                                ),
                              ),
                            )
                            : ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _lectures.length,
                              itemBuilder: (context, index) {
                                final lecture = _lectures[index];
                                final canWatch =
                                    _isEnrolled || lecture.isFreePreview;
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ListTile(
                                    onTap:
                                        canWatch
                                            ? () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => VideoPlayerScreen(
                                                      lectureId: lecture.id,
                                                      title: lecture.title,
                                                    ),
                                              ),
                                            )
                                            : null,
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          canWatch
                                              ? const Color(
                                                0xFF6C63FF,
                                              ).withOpacity(0.1)
                                              : Colors.grey.shade100,
                                      child: Icon(
                                        canWatch
                                            ? Icons.play_arrow_rounded
                                            : Icons.lock_outline,
                                        color:
                                            canWatch
                                                ? const Color(0xFF6C63FF)
                                                : Colors.grey,
                                      ),
                                    ),
                                    title: Text(
                                      lecture.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            canWatch
                                                ? const Color(0xFF1A1A2E)
                                                : Colors.grey,
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        if (lecture.isFreePreview)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Free',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                        if (lecture.duration != null) ...[
                                          const SizedBox(width: 6),
                                          Text(
                                            _formatDuration(lecture.duration),
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                        const SizedBox(height: 20),

                        // ── Reviews ──────────────────────────
                        if (_reviews.isNotEmpty) ...[
                          const Text(
                            'Student Reviews',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._reviews
                              .take(3)
                              .map(
                                (review) => Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < review.rating
                                                ? Icons.star_rounded
                                                : Icons.star_outline_rounded,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                      if (review.comment != null) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          review.comment!,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                        ],

                        const SizedBox(height: 100), // space for bottom button
                      ],
                    ),
                  ),
                ),
              ],
            ),
      ),

      // ── Bottom Buy / Enrolled Button ───────────────────
      bottomNavigationBar:
          courseAsync.whenData((course) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Price
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Price',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        course.price == 0
                            ? 'Free'
                            : '₹${course.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF6C63FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Action button
                  Expanded(
                    child:
                        _isEnrolled
                            ? ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.play_circle_outline),
                              label: const Text('Continue Learning'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                            : course.price == 0
                            ? ElevatedButton.icon(
                              onPressed: _cartLoading ? null : _addToCart,
                              icon: const Icon(Icons.download_outlined),
                              label: const Text('Enroll Free'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                            : ElevatedButton.icon(
                              onPressed:
                                  _inCart || _cartLoading ? null : _addToCart,
                              icon:
                                  _cartLoading
                                      ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Icon(
                                        _inCart
                                            ? Icons.check
                                            : Icons.shopping_cart_outlined,
                                      ),
                              label: Text(
                                _inCart ? 'Added to Cart' : 'Add to Cart',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    _inCart
                                        ? Colors.grey
                                        : const Color(0xFF6C63FF),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                  ),
                ],
              ),
            );
          }).valueOrNull ??
          const SizedBox(),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder() {
    return Container(
      color: const Color(0xFF6C63FF).withOpacity(0.8),
      child: const Center(
        child: Icon(Icons.play_lesson_rounded, size: 64, color: Colors.white),
      ),
    );
  }
}
