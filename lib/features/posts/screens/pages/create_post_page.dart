import 'package:blog_app/core/theme/app_theme.dart';
import 'package:blog_app/core/utils/toast.dart';
import 'package:blog_app/core/widgets/back_to_homescreen_button.dart';
import 'package:blog_app/core/widgets/loading_submit_button.dart';
import 'package:blog_app/features/posts/providers/create_post_provider.dart';
import 'package:blog_app/features/posts/screens/widgets/add_image_tile.dart';
import 'package:blog_app/features/posts/screens/widgets/post_image_tile.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CreatePostProvider(),
      child: const _CreatePostView(),
    );
  }
}

class _CreatePostView extends StatefulWidget {
  const _CreatePostView();

  @override
  State<_CreatePostView> createState() => _CreatePostViewState();
}

class _CreatePostViewState extends State<_CreatePostView> {
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    if (images.isNotEmpty && context.mounted) {
      context.read<CreatePostProvider>().addImages(images);
    }
  }

  Future<void> _submit(BuildContext context) async {
    final provider = context.read<CreatePostProvider>();
    final success = await provider.submit(_contentController.text);

    if (success && context.mounted) {
      context.pop(true);
    } else if (provider.error != null && context.mounted) {
      DevlogToast.show(context, provider.error!, type: ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<DevlogColors>()!;
    final provider = context.watch<CreatePostProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        title: const Text('New Post'),
        automaticallyImplyLeading: false,
        leading: BackToHomeButton(),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _contentController,
                      maxLines: null,
                      minLines: 3,
                      enabled: !provider.isSubmitting,
                      decoration: const InputDecoration(
                        hintText: "What's on your mind?",
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 16, height: 1.4),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ...provider.selectedImages.asMap().entries.map(
                          (e) => PostImageTile(
                            key: ValueKey(e.value.path),
                            localXFile: e.value,
                            onRemove: () => context
                                .read<CreatePostProvider>()
                                .removeImageAt(e.key),
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
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: IntrinsicWidth(
                  child: LoadingSubmitButton(
                    enabled: provider.canSubmit(_contentController.text),
                    isLoading: provider.isSubmitting,
                    label: 'Post',
                    loadingLabel: 'Posting...',
                    onTap: () => _submit(context),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
