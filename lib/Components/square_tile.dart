import 'package:flutter/material.dart';

class Square extends StatelessWidget {
  final String path;
  final Function()? onTap;
 
  const Square({super.key, 
    required this.onTap,
    required this.path,
    
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(16),
          color: Colors.grey[200],
        ),
        child: Image.asset(
          path,
          height: 40,
        ),
      ),
    );
  }
}
