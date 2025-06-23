import 'package:flutter/material.dart';

class AppToggleSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double height;
  final double width;
  final String assetPath;
  final String? assetPackage;

  const AppToggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.height = 40,
    this.width = 65,
    required this.assetPath,
    this.assetPackage,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        height: height,
        width: width,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: width - 5,
                height: height - 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.black26,
                ),
              ),
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: value ? 0 : null,
              right: value ? null : 0,
              child: Image.asset(
                assetPath,
                package: assetPackage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
