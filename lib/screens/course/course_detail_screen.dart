import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/course_provider.dart';

class CourseDetailScreen extends ConsumerWidget {
  final int courseId;
  const CourseDetailScreen({super.key, required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final courseAsync = ref.watch(selectedCourseProvider(courseId));

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        foregroundColor: Colors.white,
        title: const Text('Course Detail'),
      ),
      body: courseAsync.when(
        loading:
            () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
            ),
        error: (e, _) => Center(child: Text(e.toString())),
        data:
            (course) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹${course.price}',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Color(0xFF6C63FF),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(course.description ?? 'No description available'),
                ],
              ),
            ),
      ),
    );
  }
}
