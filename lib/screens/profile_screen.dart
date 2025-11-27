import 'package:flutter/material.dart';
import 'dart:io';
import '../theme.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String _selectedCurrency = 'MXN';
  String _selectedLanguage = 'es';
  String _selectedTheme = 'dark';
  bool _loading = true;
  bool _saving = false;
  
  final List<Map<String, String>> _currencies = [
    {'code': 'MXN', 'name': 'Peso Mexicano', 'symbol': '\$'},
    {'code': 'USD', 'name': 'Dólar Estadounidense', 'symbol': '\$'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': '€'},
    {'code': 'GBP', 'name': 'Libra Esterlina', 'symbol': '£'},
    {'code': 'JPY', 'name': 'Yen Japonés', 'symbol': '¥'},
    {'code': 'CAD', 'name': 'Dólar Canadiense', 'symbol': '\$'},
    {'code': 'AUD', 'name': 'Dólar Australiano', 'symbol': '\$'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }
  
  Future<void> _loadProfile() async {
    final profile = await SupabaseService().getUserProfile();
    final user = AuthService().currentUser;
    
    if (profile != null && mounted) {
      setState(() {
        _nameController.text = profile['full_name'] ?? '';
        _selectedCurrency = profile['currency'] ?? 'MXN';
        _selectedLanguage = profile['language'] ?? 'es';
        _selectedTheme = profile['theme'] ?? 'dark';
        _loading = false;
      });
    } else if (user != null && mounted) {
      setState(() {
        _nameController.text = user.userMetadata?['full_name'] ?? '';
        _loading = false;
      });
    }
  }
  
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _saving = true);
    
    try {
      await SupabaseService().updateUserProfile(
        fullName: _nameController.text.trim(),
        currency: _selectedCurrency,
        language: _selectedLanguage,
        theme: _selectedTheme,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Perfil actualizado correctamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al actualizar perfil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
  
  Future<void> _changeAvatar() async {
    try {
      // Aquí puedes implementar la selección de imagen
      // Por ahora mostramos un mensaje
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📸 Función de cambio de avatar próximamente'),
          backgroundColor: FynceeColors.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FynceeColors.background,
      appBar: AppBar(
        backgroundColor: FynceeColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: FynceeColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            color: FynceeColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text(
                'Guardar',
                style: TextStyle(
                  color: FynceeColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Avatar
                    Center(
                      child: GestureDetector(
                        onTap: _changeAvatar,
                        child: Stack(
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                color: FynceeColors.primary.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 50,
                                color: FynceeColors.primary,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: const BoxDecoration(
                                  color: FynceeColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Nombre completo
                    const Text(
                      'Nombre completo',
                      style: TextStyle(
                        color: FynceeColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: FynceeColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Ingresa tu nombre',
                        hintStyle: TextStyle(
                          color: FynceeColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor: FynceeColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Por favor ingresa tu nombre';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Moneda
                    const Text(
                      'Moneda',
                      style: TextStyle(
                        color: FynceeColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: FynceeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          isExpanded: true,
                          dropdownColor: FynceeColors.surface,
                          style: const TextStyle(
                            color: FynceeColors.textPrimary,
                            fontSize: 16,
                          ),
                          items: _currencies.map((currency) {
                            return DropdownMenuItem<String>(
                              value: currency['code'],
                              child: Text(
                                '${currency['symbol']} ${currency['name']} (${currency['code']})',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Idioma
                    const Text(
                      'Idioma',
                      style: TextStyle(
                        color: FynceeColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: FynceeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          dropdownColor: FynceeColors.surface,
                          style: const TextStyle(
                            color: FynceeColors.textPrimary,
                            fontSize: 16,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'es', child: Text('🇲🇽 Español')),
                            DropdownMenuItem(value: 'en', child: Text('🇺🇸 English')),
                            DropdownMenuItem(value: 'pt', child: Text('🇧🇷 Português')),
                            DropdownMenuItem(value: 'fr', child: Text('🇫🇷 Français')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedLanguage = value);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Tema
                    const Text(
                      'Tema',
                      style: TextStyle(
                        color: FynceeColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: FynceeColors.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedTheme,
                          isExpanded: true,
                          dropdownColor: FynceeColors.surface,
                          style: const TextStyle(
                            color: FynceeColors.textPrimary,
                            fontSize: 16,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'dark', child: Text('🌙 Oscuro')),
                            DropdownMenuItem(value: 'light', child: Text('☀️ Claro')),
                            DropdownMenuItem(value: 'auto', child: Text('🔄 Automático')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedTheme = value);
                            }
                          },
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Email (solo lectura)
                    const Text(
                      'Correo electrónico',
                      style: TextStyle(
                        color: FynceeColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: FynceeColors.surface.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.email_rounded,
                            color: FynceeColors.textSecondary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AuthService().currentUser?.email ?? 'No disponible',
                              style: TextStyle(
                                color: FynceeColors.textSecondary.withValues(alpha: 0.8),
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
