import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'services/settings_service.dart';
import 'services/game_service.dart';
import 'theme/app_colors.dart';
import 'widgets/zen_app_bar.dart';
import 'main.dart';
import 'l10n.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late int _hintLimit;
  late int _lifeLimit;
  late bool _unlockAll;
  late bool _vibrationEnabled;
  late bool _bgmEnabled;
  late bool _seEnabled;
  late bool _highlightEnabled;
  late String _appVersion;

  @override
  void initState() {
    super.initState();
    // 同期的に初期値をセット
    _hintLimit = SettingsService.hintLimitSync;
    _lifeLimit = SettingsService.lifeLimitSync;
    _unlockAll = SettingsService.isUnlockAllSync;
    _vibrationEnabled = SettingsService.isVibrationEnabledSync;
    _bgmEnabled = SettingsService.isBgmEnabledSync;
    _seEnabled = SettingsService.isSeEnabledSync;
    _highlightEnabled = SettingsService.isHighlightEnabledSync;
    _appVersion = AppConfig.version;
  }

  void _syncSettings() {
    if (mounted) {
      setState(() {
        _hintLimit = SettingsService.hintLimitSync;
        _lifeLimit = SettingsService.lifeLimitSync;
        _unlockAll = SettingsService.isUnlockAllSync;
        _vibrationEnabled = SettingsService.isVibrationEnabledSync;
        _bgmEnabled = SettingsService.isBgmEnabledSync;
        _seEnabled = SettingsService.isSeEnabledSync;
        _highlightEnabled = SettingsService.isHighlightEnabledSync;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ZenAppBar(
        title: Text(L10n.settings),
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
              _syncSettings();
            },
          ),
          _buildSwitchTile(
            title: L10n.bgm,
            value: _bgmEnabled,
            onChanged: (val) async {
              await SettingsService.setBgmEnabled(val);
              _syncSettings();
            },
          ),
          _buildSwitchTile(
            title: L10n.se,
            value: _seEnabled,
            onChanged: (val) async {
              await SettingsService.setSeEnabled(val);
              _syncSettings();
            },
          ),

          _buildSectionHeader(L10n.gameDisplaySettings),
          _buildSwitchTile(
            title: L10n.highlightSameNumbers,
            subtitle: L10n.highlightSameNumbersSub,
            value: _highlightEnabled,
            onChanged: (val) async {
              await SettingsService.setHighlightEnabled(val);
              _syncSettings();
            },
          ),

          _buildSectionHeader(L10n.appInfo),
          ListTile(
            title: Text(L10n.version),
            trailing: Text(_appVersion, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            title: Text(L10n.license),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              showLicensePage(
                context: context,
                applicationName: L10n.appTitle,
                applicationVersion: _appVersion,
              );
            },
          ),

          _buildSectionHeader(L10n.dataManagement),
          ListTile(
            title: Text(L10n.resetAllData, style: const TextStyle(color: AppColors.enji, fontWeight: FontWeight.bold)),
            onTap: _showResetConfirmDialog,
          ),

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
                    _syncSettings();
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
                    _syncSettings();
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
                _syncSettings();
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
          color: color ?? AppColors.tokiwa,
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
      activeThumbColor: AppColors.tokiwa,
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.washi,
        title: Text(L10n.resetAllData, style: const TextStyle(color: AppColors.enji, fontWeight: FontWeight.bold)),
        content: Text(L10n.resetAllDataConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(L10n.cancel, style: const TextStyle(color: AppColors.kurumi))),
          TextButton(
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              
              await GameService.resetAllData();
              scaffoldMessenger.showSnackBar(
                SnackBar(content: Text(L10n.resetCompleted)),
              );
              
              navigator.pop();
              _syncSettings();
            },
            child: Text(L10n.reset, style: const TextStyle(color: AppColors.enji)),
          ),
        ],
      ),
    );
  }
}
