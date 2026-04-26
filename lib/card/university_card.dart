import 'package:flutter/material.dart';

class UniversityCard extends StatelessWidget {
  final String university;
  final VoidCallback onTap;

  const UniversityCard({
    super.key,
    required this.university,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Center(
          child: Text(
            university,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ),
      ),
    );
  }
}
