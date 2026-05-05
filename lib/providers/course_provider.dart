import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/course_model.dart';
import '../services/course_service.dart';

final courseServiceProvider = Provider((ref) => CourseService());

// ── All courses state ──────────────────────────────────
final coursesProvider =
    StateNotifierProvider<CoursesNotifier, AsyncValue<List<CourseModel>>>(
      (ref) => CoursesNotifier(ref.read(courseServiceProvider)),
    );

class CoursesNotifier extends StateNotifier<AsyncValue<List<CourseModel>>> {
  final CourseService _service;
  CoursesNotifier(this._service) : super(const AsyncValue.loading()) {
    fetchCourses();
  }

  Future<void> fetchCourses({String? search, String? category}) async {
    state = const AsyncValue.loading();
    try {
      final courses = await _service.getCourses(
        search: search,
        category: category,
      );
      state = AsyncValue.data(courses);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

// ── Selected course detail ─────────────────────────────
final selectedCourseProvider = FutureProvider.family<CourseModel, int>(
  (ref, id) => ref.read(courseServiceProvider).getCourse(id),
);
