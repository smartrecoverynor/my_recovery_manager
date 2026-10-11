import 'package:flutter/material.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/primary_text_form_field.dart';
import 'package:go_router/go_router.dart';

class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  String? _selectedGender;
  int? _selectedBirthYear;

  final List<int> birthYears = List.generate(
    100,
        (index) => DateTime.now().year - 18 - index,
  );

  @override
  void dispose() {
    _usernameController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fortell litt om deg selv',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Denne informasjonen brukes til å tilpasse appen.',
                  style: TextStyle(
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                PrimaryTextFormField(
                  controller: _usernameController,
                  label: 'Brukernavn',
                  hint: 'Velg et brukernavn',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Skriv inn et brukernavn';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                PrimaryTextFormField(
                  controller: _displayNameController,
                  label: 'Fornavn eller kallenavn',
                  hint: 'Hva vil du at vi skal kalle deg?',
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Skriv inn et fornavn eller kallenavn';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<int>(
                  initialValue: _selectedBirthYear,
                  decoration: const InputDecoration(
                    labelText: 'Fødselsår',
                    border: OutlineInputBorder(),
                  ),
                  items: birthYears.map((year) {
                    return DropdownMenuItem<int>(
                      value: year,
                      child: Text(year.toString()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBirthYear = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Velg fødselsår';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Kjønn',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Mann',
                      child: Text('Mann'),
                    ),
                    DropdownMenuItem(
                      value: 'Kvinne',
                      child: Text('Kvinne'),
                    ),
                    DropdownMenuItem(
                      value: 'Annet',
                      child: Text('Annet/vil ikke oppgi'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedGender = value;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Velg kjønn';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  text: 'Neste',
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      context.go('/assessment');
                    }
                  },
                ),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('OBS!'),
                              content: const Text(
                                'Kartleggingen gir appen mulighet til å gi deg en '
                                    'personlig anbefaling om målsetning. Du kan når som '
                                    'helst gjennomføre kartleggingen i appen senere.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Tilbake'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    context.go(
                                      '/goal-selection',
                                      extra: false,
                                    );
                                  },
                                  child: const Text('Hopp over'),
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                    child: Text(
                      'Hopp over kartlegging og velg mål',
                      style: TextStyle(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}