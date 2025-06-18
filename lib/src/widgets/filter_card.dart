import 'package:flutter/material.dart';

class FilterCardWidget extends StatelessWidget {
  final String label;

  final VoidCallback onTap;

  const FilterCardWidget({
    super.key,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                // BoxShadow(
                //   color: Colors.black45,
                //   blurRadius: 4,
                //   offset: Offset(2, 2),
                // ),
              ],
            ),
            child: Image.asset(
              "assets/$label.png",
              package: 'popil_clip_editor',
              height: 60,
              width: 60,
              fit: BoxFit.contain,
            )),
      ),
    );
  }
}
