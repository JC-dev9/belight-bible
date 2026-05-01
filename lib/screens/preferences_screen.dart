import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart' show HiveKeys, appThemeNotifier;
import '../services/notification_service.dart';

/// Tela de preferências — permite alterar o tema global da aplicação.
class PreferencesScreen extends StatefulWidget {
  const PreferencesScreen({super.key});

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  late ThemeMode _selectedTheme;
  late bool _dailyVerseEnabled;
  late TimeOfDay _dailyVerseTime;

  @override
  void initState() {
    super.initState();
    _selectedTheme = appThemeNotifier.value;
    final box = Hive.box(HiveKeys.settingsBox);
    _dailyVerseEnabled =
        box.get(HiveKeys.dailyVerseEnabled, defaultValue: false) == true;
    final hour = box.get(HiveKeys.dailyVerseHour, defaultValue: 8) as int;
    final minute = box.get(HiveKeys.dailyVerseMinute, defaultValue: 0) as int;
    _dailyVerseTime = TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _setThemeMode(ThemeMode mode) async {
    setState(() => _selectedTheme = mode);
    appThemeNotifier.value = mode;

    final box = Hive.box(HiveKeys.settingsBox);
    await box.put(HiveKeys.themeMode, mode.name);
  }

  Future<void> _toggleDailyVerse(bool value) async {
    final box = Hive.box(HiveKeys.settingsBox);

    if (value) {
      final granted =
          await NotificationService.instance.requestPermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissão de notificações negada.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
      await NotificationService.instance.scheduleDailyVerse(
        hour: _dailyVerseTime.hour,
        minute: _dailyVerseTime.minute,
      );
    } else {
      await NotificationService.instance.cancelDailyVerse();
    }

    await box.put(HiveKeys.dailyVerseEnabled, value);
    if (mounted) setState(() => _dailyVerseEnabled = value);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _dailyVerseTime,
    );
    if (picked == null) return;

    final box = Hive.box(HiveKeys.settingsBox);
    await box.put(HiveKeys.dailyVerseHour, picked.hour);
    await box.put(HiveKeys.dailyVerseMinute, picked.minute);

    if (_dailyVerseEnabled) {
      await NotificationService.instance
          .scheduleDailyVerse(hour: picked.hour, minute: picked.minute);
    }
    if (mounted) setState(() => _dailyVerseTime = picked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = Colors.yellow.shade800;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Preferências',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Secção: Aparência
          Text(
            'APARÊNCIA',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),

          // Cards de seleção de tema
          _buildThemeOption(
            context,
            icon: Icons.brightness_auto_outlined,
            title: 'Sistema',
            subtitle: 'Segue o tema do dispositivo',
            mode: ThemeMode.system,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            icon: Icons.light_mode_outlined,
            title: 'Claro',
            subtitle: 'Fundo branco, texto escuro',
            mode: ThemeMode.light,
            accent: accent,
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _buildThemeOption(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Escuro',
            subtitle: 'Fundo escuro, texto claro',
            mode: ThemeMode.dark,
            accent: accent,
            isDark: isDark,
          ),

          const SizedBox(height: 32),

          // Secção: Notificações
          Text(
            'NOTIFICAÇÕES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: _dailyVerseEnabled,
                  onChanged: _toggleDailyVerse,
                  activeColor: accent,
                  title: const Text(
                    'Versículo do dia',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Lembrete diário com a Palavra',
                    style: TextStyle(fontSize: 12),
                  ),
                  secondary: Icon(Icons.notifications_outlined,
                      color: _dailyVerseEnabled ? accent : theme.hintColor),
                ),
                Divider(height: 1, color: theme.dividerColor.withOpacity(0.2)),
                ListTile(
                  enabled: _dailyVerseEnabled,
                  leading: Icon(
                    Icons.access_time,
                    color: _dailyVerseEnabled ? accent : theme.hintColor,
                  ),
                  title: const Text('Hora do lembrete'),
                  trailing: Text(
                    _formatTime(_dailyVerseTime),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _dailyVerseEnabled ? accent : theme.hintColor,
                    ),
                  ),
                  onTap: _dailyVerseEnabled ? _pickTime : null,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Secção: Sobre
          Text(
            'SOBRE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.hintColor,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: theme.hintColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'BeLight Bible',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Versão 1.0.0',
                            style: TextStyle(
                              color: theme.hintColor,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeMode mode,
    required Color accent,
    required bool isDark,
  }) {
    final isSelected = _selectedTheme == mode;
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => _setThemeMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? accent.withOpacity(0.08) : theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? accent : theme.dividerColor.withOpacity(0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? accent.withOpacity(0.15)
                    : theme.hintColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? accent : theme.hintColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: isSelected ? accent : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: accent, size: 22)
            else
              Icon(Icons.circle_outlined,
                  color: theme.hintColor.withOpacity(0.3), size: 22),
          ],
        ),
      ),
    );
  }
}
