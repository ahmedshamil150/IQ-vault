import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/sound_service.dart';
import 'help_screen.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SoundService _soundService = SoundService();
  bool _isGameMechanicsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('iqVaultBox');
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('SETTINGS'),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _soundService.playClick();
            Navigator.pop(context);
          },
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(keys: ['isDarkMode']),
        builder: (context, Box box, _) {
          final darkEnabled = box.get('isDarkMode', defaultValue: false);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              const SizedBox(height: 10),
              _buildModernSection(context, 'Game Mechanics', [
                _buildExpandableRow(
                  context,
                  title: 'How the game works',
                  isExpanded: _isGameMechanicsExpanded,
                  onTap: () => setState(() => _isGameMechanicsExpanded = !_isGameMechanicsExpanded),
                  content: Text(
                    'IQ Vault is designed to provide a comprehensive cognitive workout. Each puzzle category targets specific mental faculties:\n\n'
                    '• Sudoku: Logic & Elimination\n'
                    '• Sequence: Pattern Recognition\n'
                    '\n'
                    'Complete levels to track your progress and unlock random daily challenges!',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: darkEnabled ? Colors.grey[400] : Colors.grey[700],
                    ),
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildModernSection(context, 'Appearance', [
                _buildSettingRow(
                  context,
                  icon: darkEnabled ? Icons.dark_mode : Icons.light_mode,
                  title: 'Dark Mode',
                  subtitle: 'Easier on the eyes',
                  trailing: Switch.adaptive(
                    value: darkEnabled,
                    onChanged: (val) {
                      _soundService.playToggle();
                      box.put('isDarkMode', val);
                    },
                    activeTrackColor: Colors.indigoAccent,
                  ),
                ),
                _buildSettingRow(
                  context,
                  icon: Icons.volume_up_rounded,
                  title: 'Sound Effects',
                  subtitle: 'Audio and haptic feedback',
                  trailing: ValueListenableBuilder(
                    valueListenable: box.listenable(keys: ['isSoundEnabled']),
                    builder: (context, Box box, _) {
                      final soundEnabled = box.get('isSoundEnabled', defaultValue: true);
                      return Switch.adaptive(
                        value: soundEnabled,
                        onChanged: (val) {
                          _soundService.playToggle();
                          box.put('isSoundEnabled', val);
                        },
                        activeTrackColor: Colors.indigoAccent,
                      );
                    },
                  ),
                ),
              ]),
              const SizedBox(height: 24),
              _buildModernSection(context, 'Knowledge', [
                _buildSettingRow(
                  context,
                  icon: Icons.help_outline_rounded,
                  title: 'Help Center',
                  subtitle: 'Learn how to play',
                  onTap: () {
                    _soundService.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildModernSection(context, 'Information', [
                _buildSettingRow(
                  context,
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  subtitle: '1.1.0 (Build 5)',
                ),
                _buildSettingRow(
                  context,
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy',
                  subtitle: 'How we handle data',
                  onTap: () {
                    _soundService.playClick();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PrivacyPolicyScreen(),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'MADE WITH ❤️ BY IQ VAULT TEAM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildExpandableRow(
    BuildContext context, {
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
    required Widget content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.grey[500] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Container(
            width: double.infinity,
            height: isExpanded ? null : 0,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: content,
          ),
        ),
      ],
    );
  }

  Widget _buildModernSection(
    BuildContext context,
    String title,
    List<Widget> children,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: isDark ? Colors.indigoAccent : Colors.indigo,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E2125) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.indigo.withValues(alpha: 0.05),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.indigoAccent, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing
              else if (onTap != null)
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
