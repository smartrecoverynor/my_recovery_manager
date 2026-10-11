import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/situation_experience.dart';
import '../../data/repositories/situation_experience_repository.dart';
import 'situation.dart';

class SituationExperiencePage extends StatefulWidget {
  final Situation situation;

  const SituationExperiencePage({super.key, required this.situation});

  @override
  State<SituationExperiencePage> createState() =>
      _SituationExperiencePageState();
}

class _SituationExperiencePageState extends State<SituationExperiencePage> {
  final SituationExperienceRepository _repository =
  SituationExperienceRepository();

  final TextEditingController _workedController = TextEditingController();
  final TextEditingController _didNotWorkController = TextEditingController();
  final TextEditingController _learningController = TextEditingController();

  List<SituationExperience> _experiences = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadExperiences();
  }

  @override
  void dispose() {
    _workedController.dispose();
    _didNotWorkController.dispose();
    _learningController.dispose();
    super.dispose();
  }

  Future<void> _loadExperiences() async {
    try {
      final experiences = await _repository.getForSituation(
        situationId: widget.situation.id,
        userId: 'local-user',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _experiences = experiences;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fant ${experiences.length} erfaring(er).')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Feil ved henting: $e')));
    }
  }

  Future<void> _saveExperience() async {
    final worked = _workedController.text.trim();
    final didNotWork = _didNotWorkController.text.trim();
    final learning = _learningController.text.trim();

    if (worked.isEmpty && didNotWork.isEmpty && learning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skriv inn minst én erfaring før du lagrer.'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final now = DateTime.now();

    final experience = SituationExperience(
      id: const Uuid().v4(),
      situationId: widget.situation.id,
      userId: 'local-user',
      whatWorked: worked.isEmpty ? null : worked,
      whatDidNotWork: didNotWork.isEmpty ? null : didNotWork,
      learning: learning.isEmpty ? null : learning,
      createdAt: now,
      updatedAt: now,
    );

    try {
      await _repository.save(experience);

      _workedController.clear();
      _didNotWorkController.clear();
      _learningController.clear();

      await _loadExperiences();

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erfaringen er lagret.')));
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke lagre erfaringen: $e')),
      );
    }
  }

  Future<void> _deleteExperience(SituationExperience experience) async {
    final colors = Theme.of(context).colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Slett erfaring?'),
          content: const Text('Vil du slette denne erfaringen?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Avbryt'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(
                'Slett',
                style: TextStyle(color: colors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await _repository.delete(experience.id);

      await _loadExperiences();
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kunne ikke slette erfaringen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Erfaringer')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.situation.text,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Hva har du erfart fra tidligere lignende situasjoner?',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 28),

              _buildTextField(
                controller: _workedController,
                label: 'Hva har fungert?',
                hint: 'Hva har hjulpet deg i lignende situasjoner?',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _didNotWorkController,
                label: 'Hva har ikke fungert?',
                hint: 'Hva har vært vanskelig eller lite nyttig?',
              ),

              const SizedBox(height: 16),

              _buildTextField(
                controller: _learningController,
                label: 'Hva lærte jeg?',
                hint: 'Hva tar du med deg videre?',
              ),

              const SizedBox(height: 28),

              if (_experiences.isNotEmpty) ...[
                Text(
                  'Tidligere erfaringer',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 16),

                ..._experiences.map(_buildExperienceCard),

                const SizedBox(height: 20),
              ],

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveExperience,
                  child: _isSaving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : const Text(
                    'Lagre erfaring',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  Widget _buildExperienceCard(SituationExperience experience) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Erfaring',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),
              ),

              IconButton(
                onPressed: () => _deleteExperience(experience),
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.error,
                ),
              ),
            ],
          ),

          if (experience.whatWorked != null &&
              experience.whatWorked!.isNotEmpty)
            _buildExperienceSection(
              title: 'Hva fungerte?',
              text: experience.whatWorked!,
            ),

          if (experience.whatDidNotWork != null &&
              experience.whatDidNotWork!.isNotEmpty)
            _buildExperienceSection(
              title: 'Hva fungerte ikke?',
              text: experience.whatDidNotWork!,
            ),

          if (experience.learning != null && experience.learning!.isNotEmpty)
            _buildExperienceSection(
              title: 'Hva lærte jeg?',
              text: experience.learning!,
            ),

          const SizedBox(height: 4),

          Text(
            _formatDate(experience.createdAt),
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceSection({
    required String title,
    required String text,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            text,
            style: TextStyle(
              height: 1.4,
              color: colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.'
        '${date.month.toString().padLeft(2, '0')}.'
        '${date.year}';
  }
}