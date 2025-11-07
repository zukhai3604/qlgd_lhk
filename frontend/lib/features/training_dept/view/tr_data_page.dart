import 'package:flutter/material.dart';
import 'package:qlgd_lhk/features/training_dept/view/tr_classes_list_page.dart';
import 'package:qlgd_lhk/features/training_dept/view/tr_subjects_list_page.dart';
import 'package:qlgd_lhk/features/training_dept/view/tr_instructors_list_page.dart';
import 'package:qlgd_lhk/features/training_dept/view/tr_classrooms_list_page.dart';

/// Training Department Data page
/// UI replicated to match the provided Figma-to-code reference
class TrainingDepartmentDataPage extends StatelessWidget {
  const TrainingDepartmentDataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header with back button and school name
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, color: Colors.black, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'TRƯỜNG ĐẠI HỌC THUỶ LỢI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xFF1A2EB0),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 40),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Text(
                      'Dữ liệu',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF545454),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // First row: Lớp and Môn
                        Row(
                          children: [
                            _DataCard(
                              label: 'Lớp',
                              icon: Icons.class_,
                              color: const Color(0xFF46B285),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ClassesListPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _DataCard(
                              label: 'Môn',
                              icon: Icons.book,
                              color: const Color(0xFF648DDB),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SubjectsListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Second row: Giảng viên and Phòng học
                        Row(
                          children: [
                            _DataCard(
                              label: 'Giảng viên',
                              icon: Icons.people,
                              color: const Color(0xFFD22E2E),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const InstructorsListPage(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 12),
                            _DataCard(
                              label: 'Phòng học',
                              icon: Icons.meeting_room,
                              color: const Color(0xFFE7983D),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ClassroomsListPage(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_outlined),
            label: 'Thông báo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

class _DataCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DataCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 56),
              const SizedBox(height: 16),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
