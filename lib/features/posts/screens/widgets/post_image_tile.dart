import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PostImageTile extends StatelessWidget {
  final String? networkUrl;
  final XFile? localXFile;
  final VoidCallback onRemove;

  const PostImageTile({
    super.key,
    this.networkUrl,
    this.localXFile,
    required this.onRemove,
  }) : assert(networkUrl != null || localXFile != null);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 90,
            height: 90,
            child: localXFile != null
                ? FutureBuilder<Uint8List>(
                    future: localXFile!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return Container(
                          color: Colors.grey.withValues(alpha: .15),
                        );
                      }
                      return Image.memory(snapshot.data!, fit: BoxFit.cover);
                    },
                  )
                : Image.network(networkUrl!, fit: BoxFit.cover),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
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
