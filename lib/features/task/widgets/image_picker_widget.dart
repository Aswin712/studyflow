import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Widget upload foto untuk form tugas.
/// Menangani: pilih dari kamera/galeri, simpan ke app documents,
/// tampilkan preview, dan hapus foto.
class ImagePickerWidget extends StatelessWidget {
  final String? imagePath;
  final ValueChanged<String> onImageSelected;
  final VoidCallback onImageRemoved;

  const ImagePickerWidget({
    super.key,
    required this.imagePath,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null && imagePath!.isNotEmpty;
    final file = hasImage ? File(imagePath!) : null;
    final fileExists = file?.existsSync() ?? false;

    if (hasImage && fileExists) {
      return _ImagePreview(
        file: file!,
        onRemove: onImageRemoved,
        onReplace: () => _showPicker(context),
      );
    }

    return _PickerButton(onTap: () => _showPicker(context));
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (_) => const _SourceSheet(),
    );
    if (picked == null) return;

    final picker = ImagePicker();
    final XFile? xfile = await picker.pickImage(
      source: picked,
      imageQuality: 80, // kompres agar tidak makan storage
      maxWidth: 1920,
    );
    if (xfile == null) return;

    // Salin ke folder permanen app agar tidak hilang setelah crop/temp cleanup
    final savedPath = await _saveToAppDir(xfile);
    if (savedPath != null) {
      onImageSelected(savedPath);
    }
  }

  /// Salin file dari temp ImagePicker ke app documents directory
  Future<String?> _saveToAppDir(XFile xfile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final taskImagesDir = Directory(p.join(appDir.path, 'task_images'));
      if (!taskImagesDir.existsSync()) {
        taskImagesDir.createSync(recursive: true);
      }

      final ext =
          p.extension(xfile.path).isNotEmpty ? p.extension(xfile.path) : '.jpg';
      final fileName = 'task_${DateTime.now().millisecondsSinceEpoch}$ext';
      final destPath = p.join(taskImagesDir.path, fileName);

      await File(xfile.path).copy(destPath);
      return destPath;
    } catch (_) {
      return null;
    }
  }
}

/// Bottom sheet pilih sumber foto
class _SourceSheet extends StatelessWidget {
  const _SourceSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Pilih sumber foto',
              style: theme.textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.camera_alt_outlined,
                  color: theme.colorScheme.onPrimaryContainer),
            ),
            title: const Text('Kamera'),
            subtitle: const Text('Foto langsung dari kamera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.photo_library_outlined,
                  color: theme.colorScheme.onSecondaryContainer),
            ),
            title: const Text('Galeri'),
            subtitle: const Text('Pilih dari foto tersimpan'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Tombol "tambah foto" saat belum ada foto
class _PickerButton extends StatelessWidget {
  final VoidCallback onTap;
  const _PickerButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 36,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tambah foto tugas',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Kamera atau galeri',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Preview foto yang sudah dipilih + tombol hapus/ganti
class _ImagePreview extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  final VoidCallback onReplace;

  const _ImagePreview({
    required this.file,
    required this.onRemove,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          // Foto
          SizedBox(
            width: double.infinity,
            height: 200,
            child: Image.file(
              file,
              fit: BoxFit.cover,
              cacheWidth: 600, // decode di resolusi lebih kecil → hemat RAM
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: frame != null
                      ? child
                      : Container(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.image_outlined,
                                size: 32, color: Colors.grey),
                          ),
                        ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: theme.colorScheme.surfaceContainerHighest,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined,
                        color: theme.colorScheme.outline, size: 36),
                    const SizedBox(height: 8),
                    Text('Foto tidak ditemukan',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.outline)),
                  ],
                ),
              ),
            ),
          ),

          // Overlay tombol aksi di pojok kanan atas
          Positioned(
            top: 8,
            right: 8,
            child: Row(
              children: [
                _ActionChip(
                  icon: Icons.swap_horiz,
                  label: 'Ganti',
                  onTap: onReplace,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                _ActionChip(
                  icon: Icons.delete_outline,
                  label: 'Hapus',
                  onTap: onRemove,
                  color: theme.colorScheme.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
