import 'dart:io';
import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/toast.dart';
import 'package:blog_app/core/widgets/back_to_homescreen_button.dart';
import 'package:blog_app/core/widgets/loading_submit_button.dart';
import 'package:blog_app/features/posts/data/post_model.dart';
import 'package:blog_app/features/posts/providers/update_post_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/add_image_tile.dart';
import 'package:blog_app/features/posts/screens/widgets/post_image_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class UpdatePostPage extends StatelessWidget {
  final PostModel post;
  const UpdatePostPage({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => UpdatePostProvider()..loadPost(post),
      child: const _UpdatePostView(),
    );
  }
}

class _UpdatePostView extends StatelessWidget {
  const _UpdatePostView();

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty && context.mounted) {
      context.read<UpdatePostProvider>().addNewImages(images);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final provider = context.read<UpdatePostProvider>();
    final updatedPost = await provider.submit();

    if (updatedPost != null && context.mounted) {
      DevlogToast.show(
        context,
        'Post updated successfully.',
        type: ToastType.success,
      );
      context.pop(updatedPost);
    } else if (provider.error != null && context.mounted) {
      DevlogToast.show(context, provider.error!, type: ToastType.error);
      debugPrint(provider.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<UpdatePostProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('Edit post'),
        automaticallyImplyLeading: false,
        leading: BackToHomeButton(),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: provider.contentController,
                        maxLines: 6,
                        minLines: 3,
                        enabled: !provider.isSubmitting,
                        onChanged: (_) => context
                            .read<UpdatePostProvider>()
                            .notifyListeners(),
                        decoration: const InputDecoration(
                          hintText: "What's on your mind?",
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ...provider.visibleExistingImages.map(
                            (img) => PostImageTile(
                              key: ValueKey(img.id),
                              networkUrl: img.publicUrl,
                              onRemove: () => context
                                  .read<UpdatePostProvider>()
                                  .markExistingImageForRemoval(img.id),
                            ),
                          ),
                          ...provider.newImages.asMap().entries.map(
                            (e) => PostImageTile(
                              key: ValueKey('new-${e.value.path}'),
                              localFile: File(e.value.path),
                              onRemove: () => context
                                  .read<UpdatePostProvider>()
                                  .removeNewImageAt(e.key),
                            ),
                          ),
                          if (!provider.isSubmitting)
                            AddImageTile(onTap: () => _pickImages(context)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              LoadingSubmitButton(
                enabled: provider.canSubmit,
                isLoading: provider.isSubmitting,
                label: 'Save changes',
                loadingLabel: 'Saving…',
                onTap: () => _submit(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
