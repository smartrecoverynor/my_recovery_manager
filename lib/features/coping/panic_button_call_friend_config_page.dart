import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PanicButtonCallFriendConfigPage extends StatefulWidget {
  const PanicButtonCallFriendConfigPage({super.key});

  @override
  State<PanicButtonCallFriendConfigPage> createState() =>
      _PanicButtonCallFriendConfigPageState();
}

class _PanicButtonCallFriendConfigPageState
    extends State<PanicButtonCallFriendConfigPage> {
  static const String _contactIdKey =
      'panic_button_call_friend_contact_id';

  List<Contact> _contacts = [];
  Contact? _selectedContact;

  bool _loading = true;
  bool _permissionDenied = false;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    try {
      final permission = await FlutterContacts.permissions.request(
        PermissionType.readWrite,
      );

      if (permission != PermissionStatus.granted) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
          _permissionDenied = true;
        });

        return;
      }

      final contacts = await FlutterContacts.getAll(
        properties: {
          ContactProperty.name,
          ContactProperty.phone,
        },
      );

      contacts.removeWhere(
            (contact) => _firstPhoneNumber(contact) == null,
      );

      contacts.sort(
            (a, b) => (a.displayName ?? '')
            .toLowerCase()
            .compareTo(
          (b.displayName ?? '').toLowerCase(),
        ),
      );

      final preferences = await SharedPreferences.getInstance();

      final savedContactId =
      preferences.getString(_contactIdKey);

      Contact? selectedContact;

      if (savedContactId != null) {
        for (final contact in contacts) {
          if (contact.id == savedContactId) {
            selectedContact = contact;
            break;
          }
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _contacts = contacts;
        _selectedContact = selectedContact;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke hente kontakter: $e',
          ),
        ),
      );
    }
  }

  Future<void> _selectContact(Contact contact) async {
    if (contact.id == null || contact.id!.isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Kontakten kunne ikke identifiseres.',
          ),
        ),
      );

      return;
    }

    final phoneNumber = _firstPhoneNumber(contact);

    if (phoneNumber == null || phoneNumber.trim().isEmpty) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Denne kontakten har ikke et telefonnummer.',
          ),
        ),
      );

      return;
    }

    try {
      final preferences =
      await SharedPreferences.getInstance();

      await preferences.setString(
        _contactIdKey,
        contact.id!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedContact = contact;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Kunne ikke lagre kontakten: $e',
          ),
        ),
      );
    }
  }

  String? _firstPhoneNumber(Contact contact) {
    if (contact.phones.isEmpty) {
      return null;
    }

    final number = contact.phones.first.number;

    if (number.trim().isEmpty) {
      return null;
    }

    return number;
  }

  String _contactName(Contact contact) {
    final name = contact.displayName;

    if (name == null || name.trim().isEmpty) {
      return 'Ukjent kontakt';
    }

    return name;
  }

  Future<void> _removeSelectedContact() async {
    final preferences =
    await SharedPreferences.getInstance();

    await preferences.remove(_contactIdKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _selectedContact = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ring en venn'),
      ),
      body: SafeArea(
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_permissionDenied) {
      final colors = Theme.of(context).colorScheme;

      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tilgang til kontakter',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              'MRM trenger tilgang til kontaktene dine '
                  'for å kunne la Panic Button ringe en venn.',
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.65),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 24),

            FilledButton(
              onPressed: () {
                FlutterContacts.permissions.openSettings();
              },
              child: const Text('Åpne innstillinger'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) {
              final colors =
                  Theme.of(context).colorScheme;

              return Text(
                'Ring en venn',
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
                'Velg personen du ønsker å kunne '
                    'ringe raskt når du bruker Panic Button.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withValues(alpha: 0.65),
                  height: 1.4,
                ),
              );
            },
          ),

          const SizedBox(height: 28),

          if (_selectedContact != null)
            _buildSelectedContact(),

          const SizedBox(height: 20),

          Builder(
            builder: (context) {
              final colors =
                  Theme.of(context).colorScheme;

              return Text(
                'Velg kontakt',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          if (_contacts.isEmpty)
            Builder(
              builder: (context) {
                final colors =
                    Theme.of(context).colorScheme;

                return Text(
                  'Ingen kontakter med telefonnummer ble funnet.',
                  style: TextStyle(
                    color: colors.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                );
              },
            )
          else
            ..._contacts.map(_buildContactTile),
        ],
      ),
    );
  }

  Widget _buildSelectedContact() {
    final colors = Theme.of(context).colorScheme;
    final contact = _selectedContact!;
    final phoneNumber = _firstPhoneNumber(contact);

    const accentColor = Color(0xFF7A5AF8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: accentColor.withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accentColor.withValues(
            alpha: 0.25,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: accentColor.withValues(
                alpha: 0.12,
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              size: 28,
              color: accentColor,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Valgt kontakt',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurface.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  _contactName(contact),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),

                if (phoneNumber != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      phoneNumber,
                      style: TextStyle(
                        color: colors.onSurface.withValues(
                          alpha: 0.6,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          IconButton(
            tooltip: 'Fjern kontakt',
            icon: Icon(
              Icons.close,
              color: colors.onSurface,
            ),
            onPressed: _removeSelectedContact,
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile(Contact contact) {
    final colors = Theme.of(context).colorScheme;
    final phoneNumber = _firstPhoneNumber(contact);

    const accentColor = Color(0xFF7A5AF8);

    if (phoneNumber == null) {
      return const SizedBox.shrink();
    }

    final isSelected =
        _selectedContact?.id == contact.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () => _selectContact(contact),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.35)
                    : colors.outline.withValues(alpha: 0.6),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(
                      alpha: 0.10,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    color: accentColor,
                  ),
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        _contactName(contact),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        phoneNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: colors.onSurface.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: accentColor,
                  )
                else
                  Icon(
                    Icons.chevron_right,
                    color: colors.onSurface.withValues(
                      alpha: 0.55,
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