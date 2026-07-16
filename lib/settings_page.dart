import 'package:flutter/material.dart';
import 'services/settings_service.dart';
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
    setState(() {
      _hintLimit = hint;
      _lifeLimit = life;
      _unlockAll = unlock;
      _vibrationEnabled = vibration;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(L10n.settings)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
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
          const Divider(),
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
          const Divider(),
          SwitchListTile(
            title: Text(L10n.unlockAll),
            subtitle: Text(L10n.unlockAllSub),
            value: _unlockAll,
            onChanged: (val) async {
              await SettingsService.setUnlockAll(val);
              _loadSettings();
            },
          ),
          const Divider(),
          SwitchListTile(
            title: Text(L10n.vibration),
            subtitle: Text(L10n.vibrationSub),
            value: _vibrationEnabled,
            onChanged: (val) async {
              await SettingsService.setVibrationEnabled(val);
              _loadSettings();
            },
          ),
        ],
      ),
    );
  }
}
