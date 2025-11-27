import 'package:flutter/material.dart';
import '../theme.dart';
import '../models/app_settings.dart';
import '../services/supabase_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  AppSettings _settings = AppSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settingsMap = await SupabaseService().getAppSettings();
    setState(() {
      if (settingsMap.isNotEmpty) {
        _settings = AppSettings.fromMap(settingsMap);
      }
      _loading = false;
    });
  }

  Future<void> _saveSettings() async {
    await SupabaseService().saveAppSettings(_settings.toMap());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración guardada'),
          backgroundColor: FynceeColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynceeColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: FynceeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Configuración',
          style: TextStyle(
            color: FynceeColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildSection(
                  'Balance',
                  [
                    _buildSwitchTile(
                      title: 'Continuar con saldo del mes anterior',
                      subtitle: 'El saldo del mes se arrastra al siguiente mes',
                      value: _settings.carryOverBalance,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(carryOverBalance: value);
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Presupuestos',
                  [
                    _buildSwitchTile(
                      title: 'Reiniciar presupuestos cada mes',
                      subtitle: 'Los presupuestos se reinician automáticamente cada mes',
                      value: _settings.resetBudgetsMonthly,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(resetBudgetsMonthly: value);
                        });
                        _saveSettings();
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Notificaciones de presupuesto',
                      subtitle: 'Recibe alertas cuando alcances el 80% o superes tu presupuesto',
                      value: _settings.showBudgetNotifications,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(showBudgetNotifications: value);
                        });
                        _saveSettings();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Visualización',
                  [
                    _buildSwitchTile(
                      title: 'Agrupar transacciones por fecha',
                      subtitle: 'Organiza los movimientos por día',
                      value: _settings.groupTransactionsByDate,
                      onChanged: (value) {
                        setState(() {
                          _settings = _settings.copyWith(groupTransactionsByDate: value);
                        });
                        _saveSettings();
                      },
                    ),
                    _buildDropdownTile(
                      title: 'Período predeterminado',
                      subtitle: 'Vista inicial al abrir la app',
                      value: _settings.defaultPeriod,
                      items: const [
                        DropdownMenuItem(value: 'current_month', child: Text('Mes actual')),
                        DropdownMenuItem(value: 'previous_month', child: Text('Mes anterior')),
                        DropdownMenuItem(value: 'current_year', child: Text('Año actual')),
                        DropdownMenuItem(value: 'all_time', child: Text('Todo el tiempo')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(defaultPeriod: value);
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildSection(
                  'Regional',
                  [
                    _buildDropdownTile(
                      title: 'Moneda',
                      subtitle: 'Moneda para mostrar importes',
                      value: _settings.currency,
                      items: const [
                        DropdownMenuItem(value: 'MXN', child: Text('MXN - Peso Mexicano')),
                        DropdownMenuItem(value: 'USD', child: Text('USD - Dólar')),
                        DropdownMenuItem(value: 'EUR', child: Text('EUR - Euro')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _settings = _settings.copyWith(currency: value);
                          });
                          _saveSettings();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(
              color: FynceeColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: FynceeColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: FynceeColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: FynceeColors.textSecondary.withValues(alpha: 0.8),
          fontSize: 13,
        ),
      ),
      value: value,
      onChanged: onChanged,
      activeColor: FynceeColors.primary,
    );
  }

  Widget _buildDropdownTile({
    required String title,
    required String subtitle,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      title: Text(
        title,
        style: const TextStyle(
          color: FynceeColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: FynceeColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: value,
            items: items,
            onChanged: onChanged,
            decoration: InputDecoration(
              filled: true,
              fillColor: FynceeColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            dropdownColor: FynceeColors.surface,
            style: const TextStyle(
              color: FynceeColors.textPrimary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: FynceeColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: FynceeColors.primary, size: 22),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: FynceeColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: FynceeColors.textSecondary.withValues(alpha: 0.8),
          fontSize: 13,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: FynceeColors.textSecondary.withValues(alpha: 0.5),
      ),
      onTap: onTap,
    );
  }
}
