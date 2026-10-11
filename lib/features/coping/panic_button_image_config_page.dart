import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanicButtonImageConfigPage extends StatefulWidget {
  const PanicButtonImageConfigPage({super.key});

  @override
  State<PanicButtonImageConfigPage> createState() =>
      _PanicButtonImageConfigPageState();
}

class _PanicButtonImageConfigPageState
    extends State<PanicButtonImageConfigPage> {
  static const String _imagePathKey =
      'panic_button_selected_image_path';

  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;

  bool _loadingImage = true;
  bool _savingImage = false;

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
  }

  Future<void> _loadSavedImage() async {
    try {
      final preferences =
      await SharedPreferences.getInstance();

      final savedPath =
      preferences.getString(_imagePathKey);

      if (savedPath == null || savedPath.trim().isEmpty) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loadingImage = false;
        });

        return;
      }

      final file = File(savedPath);

      if (!await file.exists()) {
        await preferences.remove(_imagePathKey);

        if (!mounted) {
          return;
        }

        setState(() {
          _loadingImage = false;
        });

        return;
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = XFile(savedPath);
        _loadingImage = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke laste valgt bilde: $e',
          ),
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    if (_savingImage) {
      return;
    }

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image == null || !mounted) {
        return;
      }

      setState(() {
        _savingImage = true;
      });

      final directory =
      await getApplicationDocumentsDirectory();

      final extension =
      _getFileExtension(image.path);

      final imageFile = File(
        '${directory.path}/panic_button_image$extension',
      );

      final previousPath =
          _selectedImage?.path;

      await File(image.path).copy(
        imageFile.path,
      );

      final preferences =
      await SharedPreferences.getInstance();

      await preferences.setString(
        _imagePathKey,
        imageFile.path,
      );

      if (previousPath != null &&
          previousPath != imageFile.path) {
        final previousFile = File(previousPath);

        if (await previousFile.exists()) {
          await previousFile.delete();
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImage = XFile(imageFile.path);
        _savingImage = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _savingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke lagre bildet: $e',
          ),
        ),
      );
    }
  }

  String _getFileExtension(String path) {
    final lastDot = path.lastIndexOf('.');

    if (lastDot == -1 ||
        lastDot == path.length - 1) {
      return '.jpg';
    }

    return path.substring(lastDot);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vis et bilde'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Builder(
                builder: (context) {
                  final colors =
                      Theme.of(context).colorScheme;

                  return Text(
                    'Bilde',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  );
                },
              ),

              const SizedBox(height: 12),

              Builder(
                builder: (context) {
                  final colors =
                      Theme.of(context).colorScheme;

                  return Text(
                    'Velg et bilde fra Bilder som skal '
                        'vises når du bruker panic button.',
                    style: TextStyle(
                      fontSize: 16,
                      color: colors.onSurface.withValues(
                        alpha: 0.65,
                      ),
                      height: 1.4,
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              if (_loadingImage)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (_selectedImage == null)
                _buildEmptyState()
              else
                _buildSelectedImage(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: 0.6,
          ),
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.image_outlined,
            size: 52,
            color: colors.onSurface.withValues(
              alpha: 0.5,
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Ingen bilde valgt',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Velg et bilde som betyr noe for deg '
                'eller minner deg på hvorfor du ønsker endring.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.onSurface.withValues(
                alpha: 0.6,
              ),
              height: 1.4,
            ),
          ),

          const SizedBox(height: 16),

          FilledButton.icon(
            onPressed:
            _savingImage ? null : _pickImage,
            icon: const Icon(
              Icons.photo_library_outlined,
            ),
            label: const Text('Velg bilde'),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedImage() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: colors.outline.withValues(
                alpha: 0.6,
              ),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.file(
            File(_selectedImage!.path),
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        ),

        const SizedBox(height: 16),

        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed:
            _savingImage ? null : _pickImage,
            icon: const Icon(
              Icons.swap_horiz,
            ),
            label: Text(
              _savingImage
                  ? 'Lagrer...'
                  : 'Bytt bilde',
            ),
          ),
        ),
      ],
    );
  }
}