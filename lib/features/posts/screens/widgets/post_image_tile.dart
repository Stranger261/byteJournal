import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class PostImageTile extends StatelessWidget {
  final String? networkUrl;
  final File? localFile;
  final VoidCallback onRemove;

  const PostImageTile({
    super.key,
    this.localFile,
    this.networkUrl,
    required this.onRemove,
  }) : assert(networkUrl != null || localFile != null);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 90,
            height: 90,
            child: localFile != null
                ? Image.file(localFile!, fit: BoxFit.cover)
                : Image.network(networkUrl!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.black87,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
