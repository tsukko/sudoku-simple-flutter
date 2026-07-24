import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'services/game_service.dart';
import 'l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _hintLimit = 3;
  int _lifeLimit = 5;
  bool _unlockAll = false;
  bool _vibrationEnabled = true;
  bool _bgmEnabled = true;
  bool _seEnabled = true;
  bool _highlightEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hint = await SettingsService.getHintLimit();
    final life = await SettingsService.getLifeLimit();
    final unlock = await SettingsService.isUnlockAll();
    final vibration = await SettingsService.isVibrationEnabled();
    final bgm = await SettingsService.isBgmEnabled();
    final se = await SettingsService.isSeEnabled();
    final highlight = await SettingsService.isHighlightEnabled();

    if (mounted) {
      setState(() {
        _hintLimit = hint;
        _lifeLimit = life;
        _unlockAll = unlock;
        _vibrationEnabled = vibration;
        _bgmEnabled = bgm;
        _seEnabled = se;
        _highlightEnabled = highlight;
      });
    }
  }

  // 和風カラーパレット
  static const Color tokiwa = Color(0xFF2D5A27); // 常盤色
  static const Color kurumi = Color(0xFF5D4037); // 胡桃色
  static const Color enji = Color(0xFFB22D35);   // 臙脂

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.settings, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: tokiwa,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        children: [
          _buildSectionHeader(L10n.soundSettings),
          _buildSwitchTile(
            title: L10n.vibration,
            subtitle: L10n.vibrationSub,
            value: _vibrationEnabled,
            onChanged: (val) async {
              await SettingsService.setVibrationEnabled(val);
              _loadSettings();
            },
          ),
          _buildSwitchTile(
            title: L10n.bgm,
            value: _bgmEnabled,
            onChanged: (val) async {
              await SettingsService.setBgmEnabled(val);
              _loadSettings();
            },
          ),
          _buildSwitchTile(
            title: L10n.se,
            value: _seEnabled,
            onChanged: (val) async {
              await SettingsService.setSeEnabled(val);
              _loadSettings();
            },
          ),

          _buildSectionHeader(L10n.gameDisplaySettings),
          _buildSwitchTile(
            title: L10n.highlightSameNumbers,
            subtitle: L10n.highlightSameNumbersSub,
            value: _highlightEnabled,
            onChanged: (val) async {
              await SettingsService.setHighlightEnabled(val);
              _loadSettings();
            },
          ),

          _buildSectionHeader(L10n.appInfo),
          ListTile(
            title: Text(L10n.version),
            trailing: const Text('1.0.0', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: Text(L10n.license),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: L10n.appTitle,
                applicationVersion: '1.0.0',
              );
            },
          ),

          _buildSectionHeader(L10n.dataManagement),
          ListTile(
            title: Text(L10n.resetAllData, style: const TextStyle(color: enji, fontWeight: FontWeight.bold)),
            onTap: _showResetConfirmDialog,
          ),

          // デバッグモード時のみ表示
          if (kDebugMode) ...[
            _buildSectionHeader(L10n.developerSettings, color: Colors.orange[800]),
            ListTile(
              title: Text(L10n.hintLimit),
              subtitle: Text(_hintLimit == 0 ? L10n.unlimited : '$_hintLimit ${L10n.times}'),
              trailing: DropdownButton<int>(
                value: _hintLimit,
                items: [0, 1, 3, 5, 10].map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text(e == 0 ? L10n.unlimited : e.toString()),
                )).toList(),
                onChanged: (val) async {
                  if (val != null) {
                    await SettingsService.setHintLimit(val);
                    _loadSettings();
                  }
                },
              ),
            ),
            ListTile(
              title: Text(L10n.lifeLimit),
              subtitle: Text(_lifeLimit == 0 ? L10n.unlimited : '$_lifeLimit ${L10n.times}'),
              trailing: DropdownButton<int>(
                value: _lifeLimit,
                items: [0, 1, 3, 5, 10].map((e) => DropdownMenuItem(
                  value: e, 
                  child: Text(e == 0 ? L10n.unlimited : e.toString()),
                )).toList(),
                onChanged: (val) async {
                  if (val != null) {
                    await SettingsService.setLifeLimit(val);
                    _loadSettings();
                  }
                },
              ),
            ),
            SwitchListTile(
              title: Text(L10n.unlockAll),
              subtitle: Text(L10n.unlockAllSub),
              value: _unlockAll,
              onChanged: (val) async {
                await SettingsService.setUnlockAll(val);
                _loadSettings();
              },
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color? color}) {
    return Container(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: color ?? tokiwa,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: subtitle != null ? Text(subtitle, style: const TextStyle(fontSize: 12)) : null,
      value: value,
      onChanged: onChanged,
      activeThumbColor: tokiwa,
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(L10n.resetAllData, style: const TextStyle(color: enji, fontWeight: FontWeight.bold)),
        content: Text(L10n.resetAllDataConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.cancel, style: const TextStyle(color: kurumi))),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await GameService.resetAllData();
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(L10n.resetCompleted)),
              );
              if (mounted) {
                _loadSettings();
              }
            },
            child: Text(L10n.reset, style: const TextStyle(color: enji)),
          ),
        ],
      ),
    );
  }
}
