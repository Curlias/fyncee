import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:io';

import '../models/transaction.dart';
import '../models/goal.dart';
import '../models/date_period.dart';
import '../theme.dart';
import '../main.dart';
import '../widgets/transaction_item.dart';
import '../services/auth_service.dart';
import '../services/supabase_service.dart';
import '../services/database_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/theme_service.dart';
import '../services/profile_image_service.dart';
import 'add_transaction_page.dart';
import 'categories_page.dart';
import 'goals_page.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'budgets_screen.dart';
import 'settings_screen.dart';
import 'profile_info_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  final List<Transaction> _transactions = [];
  final List<Goal> _goals = [];
  List<Map<String, dynamic>> _budgets = [];
  
  // Datos del perfil del usuario
  String _userName = 'Usuario';
  String _userEmail = 'usuario@fyncee.app';
  bool _loadingProfile = true;
  String? _profileImagePath;

  // Método helper para determinar si es una URL o un archivo local
  bool _isUrl(String? path) {
    if (path == null) return false;
    return path.startsWith('http://') || path.startsWith('https://');
  }

  // Método helper para obtener el ImageProvider correcto
  ImageProvider? _getImageProvider(String? path) {
    if (path == null) return null;
    if (_isUrl(path)) {
      return NetworkImage(path);
    } else {
      return FileImage(File(path));
    }
  }

  // Filtros y búsqueda para movimientos
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DatePeriod _selectedPeriod = DatePeriod.currentMonth();
  int? _filterCategory;
  String? _filterType; // null (todos), 'income', 'expense'
  double _carryOverBalance = 0.0;
  
  // Método helper para obtener colores según el tema
  Color get backgroundColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.background 
      : FynceeColors.lightBackground;
  
  Color get surfaceColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.surface 
      : FynceeColors.lightSurface;
  
  Color get surfaceLightColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.surfaceLight 
      : FynceeColors.lightSurfaceLight;
  
  Color get textPrimaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textPrimary 
      : FynceeColors.lightTextPrimary;
  
  Color get textSecondaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textSecondary 
      : FynceeColors.lightTextSecondary;
  
  Color get textTertiaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textTertiary 
      : FynceeColors.lightTextTertiary;
  
  bool get isDarkMode => Theme.of(context).brightness == Brightness.dark;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadCarryOverBalance();
    _loadTransactions();
    _loadGoals();
    _loadBudgets();
  }
  
  Future<void> _loadUserProfile() async {
    final profile = await SupabaseService().getUserProfile();
    final user = AuthService().currentUser;
    final imagePath = await ProfileImageService().getProfileImagePath();
    
    print('👤 Perfil cargado: ${profile?['full_name']}');
    print('🖼️  Ruta de imagen: $imagePath');
    
    setState(() {
      if (profile != null) {
        _userName = profile['full_name'] ?? 'Usuario';
      }
      _userEmail = user?.email ?? 'usuario@fyncee.app';
      _profileImagePath = imagePath;
      _loadingProfile = false;
    });
  }

  Future<void> _loadCarryOverBalance() async {
    final balance = await SupabaseService().getCarryOverBalance();
    setState(() {
      _carryOverBalance = balance;
    });
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await SupabaseService().getTransactionsByDateRange(
        _selectedPeriod.startDate,
        _selectedPeriod.endDate,
      );
      setState(() {
        _transactions.clear();
        _transactions.addAll(transactions);
      });
      print('✅ ${transactions.length} transacciones cargadas de Supabase');
      // Recargar presupuestos después de cargar transacciones
      _loadBudgets();
    } catch (e) {
      print('❌ Error cargando transacciones: $e');
    }
  }

  Future<void> _loadGoals() async {
    try {
      final goals = await DatabaseService().getAllGoals();
      setState(() {
        _goals.clear();
        _goals.addAll(goals);
      });
      print('✅ ${goals.length} metas cargadas');
    } catch (e) {
      print('❌ Error cargando metas: $e');
    }
  }

  Future<void> _loadBudgets() async {
    try {
      final budgets = await SupabaseService().getAllBudgets();
      if (mounted) {
        setState(() {
          _budgets = budgets;
        });
      }
      // Verificar presupuestos cada vez que se cargan
      await SupabaseService().checkBudgets();
    } catch (e) {
      print('❌ Error cargando presupuestos: $e');
    }
  }

  double get _totalIncome => _transactions
      .where((t) => t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _totalExpense => _transactions
      .where((t) => !t.isIncome)
      .fold(0.0, (sum, t) => sum + t.amount);

  double get _balance => (_totalIncome - _totalExpense) + _carryOverBalance;

  String get _currentPeriodLabel {
    return _selectedPeriod.label;
  }

  Future<void> _openAddTransaction() async {
    final created = await Navigator.of(context).push<Transaction>(
      MaterialPageRoute<Transaction>(
        builder: (_) => const AddTransactionPage(),
      ),
    );

    if (created != null) {
      // Guardar en Supabase y obtener el ID generado
      try {
        final response = await SupabaseService().createTransaction(created);
        
        if (response != null) {
          // Crear una nueva transacción con el ID real de Supabase
          final savedTransaction = Transaction(
            id: response['id'] as int,
            type: created.type,
            amount: created.amount,
            categoryId: created.categoryId,
            note: created.note,
            date: created.date,
          );
          
          // Actualizar UI con la transacción que tiene el ID correcto
          setState(() => _transactions.insert(0, savedTransaction));
          print('✅ Transacción guardada con ID: ${savedTransaction.id}');
        }
      } catch (e) {
        print('❌ Error guardando transacción: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al guardar la transacción'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: backgroundColor,
      drawer: _buildDrawer(),
      appBar: _currentIndex == 2 ? _buildGoalsAppBar() : null,
      body: SafeArea(child: _buildCurrentPage()),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddTransaction,
        child: Icon(Icons.add_rounded, size: 32),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildGoalsAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(Icons.menu_rounded, color: textPrimaryColor),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Text(
        'Metas de ahorro',
        style: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }
  
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: surfaceColor,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Header del drawer
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    FynceeColors.primary,
                    FynceeColors.primary.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Foto de perfil o ícono
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: _profileImagePath == null
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white,
                      shape: BoxShape.circle,
                      image: _getImageProvider(_profileImagePath) != null
                          ? DecorationImage(
                              image: _getImageProvider(_profileImagePath)!,
                              fit: BoxFit.cover,
                            )
                          : null,
                      border: _profileImagePath != null
                          ? Border.all(
                              color: Colors.white,
                              width: 2,
                            )
                          : null,
                    ),
                    child: _profileImagePath == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 30,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userEmail,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Menú principal
            _buildDrawerItem(
              icon: Icons.home_rounded,
              title: 'Inicio',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),
            _buildDrawerItem(
              icon: Icons.list_rounded,
              title: 'Movimientos',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),
            _buildDrawerItem(
              icon: Icons.flag_rounded,
              title: 'Metas de Ahorro',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),
            
            const Divider(height: 1, color: FynceeColors.background),
            const SizedBox(height: 8),
            
            _buildDrawerItem(
              icon: Icons.category_rounded,
              title: 'Categorías',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CategoriesPage()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.pie_chart_rounded,
              title: 'Presupuestos',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.notifications_rounded,
              title: 'Notificaciones',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                );
              },
            ),
            
            const Divider(height: 1, color: FynceeColors.background),
            const SizedBox(height: 8),
            
            _buildDrawerItem(
              icon: Icons.share_rounded,
              title: 'Compartir App',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función de compartir próximamente'),
                    backgroundColor: FynceeColors.primary,
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.file_download_rounded,
              title: 'Exportar Datos',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Función de exportar próximamente'),
                    backgroundColor: FynceeColors.primary,
                  ),
                );
              },
            ),
            _buildDrawerItem(
              icon: Icons.settings_rounded,
              title: 'Configuración',
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 3);
              },
            ),
            
            const Divider(height: 1, color: FynceeColors.background),
            const SizedBox(height: 8),
            
            _buildDrawerItem(
              icon: Icons.logout_rounded,
              title: 'Cerrar Sesión',
              titleColor: Colors.red,
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: surfaceColor,
                    title: Text(
                      '¿Cerrar sesión?',
                      style: TextStyle(color: textPrimaryColor),
                    ),
                    content: Text(
                      '¿Estás seguro que deseas cerrar sesión?',
                      style: TextStyle(color: textSecondaryColor),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: Text('Cerrar sesión'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && mounted) {
                  // Limpiar datos locales
                  await DatabaseService().clearAllData();
                  
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? textPrimaryColor),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor ?? textPrimaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentIndex) {
      case 0:
        return _buildHomePage();
      case 1:
        return _buildMovementsPage();
      case 2:
        return _buildGoalsPage();
      case 3:
        return _buildProfilePage();
      default:
        return _buildHomePage();
    }
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: surfaceColor,
      elevation: 8,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.home_rounded, 'Home', 0),
            _buildNavItem(Icons.swap_vert_rounded, 'Movimientos', 1),
            const SizedBox(width: 60), // Espacio para el botón flotante
            _buildNavItem(Icons.bookmark_rounded, 'Metas', 2),
            _buildNavItem(Icons.person_rounded, 'Perfil', 3),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? FynceeColors.primary : textSecondaryColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? FynceeColors.primary : textSecondaryColor,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomePage() {
    final now = DateTime.now();
    String greeting = 'Buenos días';
    if (now.hour >= 12 && now.hour < 19) {
      greeting = 'Buenas tardes';
    } else if (now.hour >= 19) {
      greeting = 'Buenas noches';
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Header con saludo
              InkWell(
                onTap: () {
                  _scaffoldKey.currentState?.openDrawer(); // Abrir menú lateral
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      // Foto de perfil o ícono
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _profileImagePath == null
                              ? FynceeColors.primary.withValues(alpha: 0.2)
                              : null,
                          shape: BoxShape.circle,
                          image: _getImageProvider(_profileImagePath) != null
                              ? DecorationImage(
                                  image: _getImageProvider(_profileImagePath)!,
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImagePath == null
                            ? Icon(
                                Icons.person_rounded,
                                color: FynceeColors.primary,
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '$greeting!',
                              style: TextStyle(
                                color: textSecondaryColor.withValues(
                                  alpha: 0.8,
                                ),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _userName,
                              style: TextStyle(
                                color: textPrimaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('No hay notificaciones nuevas'),
                              backgroundColor: FynceeColors.primary,
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.notifications_outlined,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildBalanceCard(),
              const SizedBox(height: 24),
              _buildSummaryRow(),
              const SizedBox(height: 32),
              // Sección de Metas de ahorro (solo si hay metas)
              if (_goals.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Metas de ahorro',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() => _currentIndex = 2);
                      },
                      child: Text(
                        'Ver mas',
                        style: TextStyle(
                          color: FynceeColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Lista de metas reales
                SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _goals.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final goal = _goals[index];
                      return _buildGoalCardFromGoal(goal);
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
              // Sección de Presupuestos (solo si hay presupuestos)
              if (_budgets.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Presupuestos',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const BudgetsScreen()),
                        ).then((_) => _loadBudgets());
                      },
                      child: Text(
                        'Ver más',
                        style: TextStyle(
                          color: FynceeColors.primary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Lista de presupuestos
                SizedBox(
                  height: 120,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _budgets.length > 3 ? 3 : _budgets.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final budget = _budgets[index];
                      return _buildBudgetCard(budget);
                    },
                  ),
                ),
                const SizedBox(height: 32),
              ],
              // Sección de Movimientos - Más prominente
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: FynceeColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: FynceeColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.swap_vert_rounded,
                                color: FynceeColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Movimientos',
                              style: TextStyle(
                                color: textPrimaryColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _currentIndex = 1);
                          },
                          child: Text(
                            'Ver todos',
                            style: TextStyle(
                              color: FynceeColors.primary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_transactions.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        '${_transactions.length} transacciones este mes',
                        style: TextStyle(
                          color: textSecondaryColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ]),
          ),
        ),
        _transactions.isEmpty
            ? SliverFillRemaining(child: _buildEmptyState(context))
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction = _transactions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TransactionItem(
                          transaction: transaction,
                          onEdit: () => _editTransaction(transaction),
                          onDelete: () => _deleteTransaction(transaction),
                        ),
                      );
                    },
                    childCount: _transactions.length > 5
                        ? 5
                        : _transactions.length,
                  ),
                ),
              ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ],
    );
  }

  Widget _buildGoalCard(
    String title,
    double target,
    double current,
    Color color,
  ) {
    final progress = current / target;
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(
              locale: 'es_MX',
              symbol: '\$',
              decimalDigits: 0,
            ).format(target),
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: FynceeColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCardFromGoal(Goal goal) {
    final progress = goal.currentAmount / goal.targetAmount;
    final color = Color(goal.colorValue);
    
    return Container(
      width: 150,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                goal.emoji,
                style: TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.name,
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(
              locale: 'es_MX',
              symbol: '\$',
              decimalDigits: 0,
            ).format(goal.targetAmount),
            style: TextStyle(
              color: textPrimaryColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: FynceeColors.background,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetCard(Map<String, dynamic> budget) {
    final amount = (budget['amount'] as num).toDouble();
    final spent = (budget['spent'] as num?)?.toDouble() ?? 0.0;
    final percentage = (spent / amount * 100).clamp(0.0, 100.0);
    final remaining = (amount - spent).clamp(0.0, double.infinity);
    final isExceeded = spent > amount;
    final isWarning = spent >= amount * 0.8 && !isExceeded;
    
    final categoryName = budget['category_name'] as String? ?? 'Sin categoría';
    final categoryIcon = budget['category_icon'] as String? ?? 'category';
    final categoryColor = budget['category_color'] as int? ?? 0xFF6B7280;
    
    Color statusColor = FynceeColors.primary;
    if (isExceeded) {
      statusColor = FynceeColors.error;
    } else if (isWarning) {
      statusColor = Colors.orange;
    }
    
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BudgetsScreen()),
        ).then((_) => _loadBudgets());
      },
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: isExceeded
              ? Border.all(color: FynceeColors.error.withValues(alpha: 0.3), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getIconData(categoryIcon),
                  color: Color(categoryColor),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  NumberFormat.currency(
                    locale: 'es_MX',
                    symbol: '\$',
                    decimalDigits: 0,
                  ).format(spent),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '/ ${NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0).format(amount)}',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const Spacer(),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (percentage / 100).clamp(0.0, 1.0),
                backgroundColor: FynceeColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isExceeded
                  ? 'Excedido por ${NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0).format(spent - amount)}'
                  : 'Quedan ${NumberFormat.currency(locale: 'es_MX', symbol: '\$', decimalDigits: 0).format(remaining)}',
              style: TextStyle(
                color: statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    final iconMap = {
      'restaurant': Icons.restaurant,
      'directions_car': Icons.directions_car,
      'movie': Icons.movie,
      'shopping_bag': Icons.shopping_bag,
      'local_hospital': Icons.local_hospital,
      'school': Icons.school,
      'build': Icons.build,
      'home': Icons.home,
      'more_horiz': Icons.more_horiz,
      'account_balance_wallet': Icons.account_balance_wallet,
      'trending_up': Icons.trending_up,
      'sell': Icons.sell,
      'computer': Icons.computer,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'flight': Icons.flight,
      'sports_soccer': Icons.sports_soccer,
      'local_cafe': Icons.local_cafe,
      'pets': Icons.pets,
      'fitness_center': Icons.fitness_center,
      'phone_android': Icons.phone_android,
      'laptop': Icons.laptop,
      'games': Icons.games,
      'music_note': Icons.music_note,
      'brush': Icons.brush,
      'beach_access': Icons.beach_access,
      'spa': Icons.spa,
      'hotel': Icons.hotel,
      'local_gas_station': Icons.local_gas_station,
      'shopping_cart': Icons.shopping_cart,
      'fastfood': Icons.fastfood,
      'local_pizza': Icons.local_pizza,
      'cake': Icons.cake,
      'wine_bar': Icons.wine_bar,
    };
    return iconMap[iconName] ?? Icons.category;
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Botón anterior
          IconButton(
            icon: Icon(Icons.chevron_left, color: textPrimaryColor),
            onPressed: () {
              setState(() {
                if (_selectedPeriod.id == 'current_month') {
                  _selectedPeriod = DatePeriod.previousMonth();
                } else if (_selectedPeriod.id == 'previous_month') {
                  final now = DateTime.now();
                  final twoMonthsAgo = DateTime(now.year, now.month - 2, 1);
                  _selectedPeriod = DatePeriod.custom(
                    DateTime(twoMonthsAgo.year, twoMonthsAgo.month, 1),
                    DateTime(twoMonthsAgo.year, twoMonthsAgo.month + 1, 0, 23, 59, 59),
                  );
                }
              });
              _loadTransactions();
            },
          ),
          // Dropdown de períodos
          Expanded(
            child: GestureDetector(
              onTap: () => _showPeriodPicker(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _selectedPeriod.label,
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.keyboard_arrow_down,
                      color: textSecondaryColor,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Botón siguiente
          IconButton(
            icon: Icon(Icons.chevron_right, color: textPrimaryColor),
            onPressed: () {
              setState(() {
                if (_selectedPeriod.id == 'previous_month') {
                  _selectedPeriod = DatePeriod.currentMonth();
                } else if (_selectedPeriod.id != 'current_month') {
                  _selectedPeriod = DatePeriod.currentMonth();
                }
              });
              _loadTransactions();
            },
          ),
        ],
      ),
    );
  }

  void _showPeriodPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seleccionar período',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Períodos predefinidos
                  ...DatePeriod.defaultPeriods().map((period) {
                    final isSelected = _selectedPeriod.id == period.id;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: FynceeColors.primary.withValues(alpha: 0.1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: Text(
                        period.label,
                        style: TextStyle(
                          color: isSelected ? FynceeColors.primary : textPrimaryColor,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: FynceeColors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedPeriod = period;
                        });
                        _loadTransactions();
                        Navigator.pop(context);
                      },
                    );
                  }),
                  
                  const SizedBox(height: 8),
                  Divider(color: textSecondaryColor.withValues(alpha: 0.2)),
                  const SizedBox(height: 8),
                  
                  // Opción: Mes específico
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.calendar_month, color: FynceeColors.primary),
                    title: Text(
                      'Seleccionar mes',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Elige un mes específico',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showMonthPicker();
                    },
                  ),
                  
                  // Opción: Rango personalizado
                  ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    leading: const Icon(Icons.date_range, color: FynceeColors.primary),
                    title: Text(
                      'Rango personalizado',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Desde - Hasta',
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showCustomRangePicker();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMonthPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Seleccionar mes',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: textSecondaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: 24, // 2 años de meses
                itemBuilder: (context, index) {
                  final now = DateTime.now();
                  final date = DateTime(now.year, now.month - index, 1);
                  final monthName = DateFormat('MMMM yyyy', 'es').format(date);
                  
                  return ListTile(
                    title: Text(
                      monthName,
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 16,
                      ),
                    ),
                    onTap: () {
                      final firstDay = DateTime(date.year, date.month, 1);
                      final lastDay = DateTime(date.year, date.month + 1, 0, 23, 59, 59);
                      
                      setState(() {
                        _selectedPeriod = DatePeriod.custom(firstDay, lastDay);
                      });
                      _loadTransactions();
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showCustomRangePicker() async {
    final now = DateTime.now();
    
    final startDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: FynceeColors.primary,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (startDate == null) return;
    
    final endDate = await showDatePicker(
      context: context,
      initialDate: startDate.add(const Duration(days: 1)),
      firstDate: startDate,
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: FynceeColors.primary,
              onPrimary: Colors.white,
              surface: surfaceColor,
              onSurface: textPrimaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (endDate == null) return;
    
    setState(() {
      _selectedPeriod = DatePeriod.custom(
        startDate,
        DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
      );
    });
    _loadTransactions();
  }

  Widget _buildBalanceCard() {
    final currencyFormatter = NumberFormat.currency(
      locale: Intl.getCurrentLocale(),
      symbol: '\$',
      decimalDigits: 2,
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [FynceeColors.primary, FynceeColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: FynceeColors.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Saldo',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _currentPeriodLabel,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormatter.format(_balance),
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow() {
    final currencyFormatter = NumberFormat.currency(
      locale: Intl.getCurrentLocale(),
      symbol: '\$',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Ingresos',
              currencyFormatter.format(_totalIncome),
              FynceeColors.incomeGreen,
              Icons.arrow_downward_rounded,
            ),
          ),
          Container(width: 1, height: 40, color: surfaceLightColor),
          Expanded(
            child: _buildSummaryItem(
              'Egresos',
              currencyFormatter.format(_totalExpense),
              FynceeColors.expenseRed,
              Icons.arrow_upward_rounded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String amount,
    Color color,
    IconData icon,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          amount,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet_rounded,
              size: 40,
              color: FynceeColors.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Registra tus primeros movimientos',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Transaction> get _filteredTransactions {
    var filtered = _transactions.where((t) {
      // Filtro de búsqueda
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final note = t.note?.toLowerCase() ?? '';
        if (!note.contains(query) && !t.amount.toString().contains(query)) {
          return false;
        }
      }

      // Filtro de categoría
      if (_filterCategory != null && t.categoryId != _filterCategory) {
        return false;
      }

      // Filtro de tipo
      if (_filterType == 'income' && !t.isIncome) return false;
      if (_filterType == 'expense' && t.isIncome) return false;

      return true;
    }).toList();

    return filtered;
  }

  Widget _buildMovementsPage() {
    // Calcular totales de la semana
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekTransactions = _transactions.where((t) {
      return t.date.isAfter(startOfWeek.subtract(const Duration(days: 1)));
    }).toList();

    final weekIncome = weekTransactions
        .where((t) => t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final weekExpense = weekTransactions
        .where((t) => !t.isIncome)
        .fold(0.0, (sum, t) => sum + t.amount);

    return CustomScrollView(
      slivers: [
        // AppBar
        SliverAppBar(
          expandedHeight: 60,
          floating: true,
          pinned: true,
          backgroundColor: backgroundColor,
          elevation: 0,
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.menu_rounded, color: textPrimaryColor),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.symmetric(
              horizontal: 60,
              vertical: 16,
            ),
            title: Text(
              'Movimientos',
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Barra de búsqueda
              Container(
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar movimientos...',
                    hintStyle: TextStyle(
                      color: textSecondaryColor.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: textSecondaryColor,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: textSecondaryColor,
                            ),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Selector de períodos
              _buildPeriodSelector(),

              const SizedBox(height: 16),

              // Chips de filtros
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      '💰 Ingresos',
                      _filterType == 'income',
                      () => setState(() {
                        _filterType = _filterType == 'income' ? null : 'income';
                      }),
                      color: FynceeColors.incomeGreen,
                    ),
                    const SizedBox(width: 8),
                    _buildFilterChip(
                      '💸 Egresos',
                      _filterType == 'expense',
                      () => setState(() {
                        _filterType = _filterType == 'expense'
                            ? null
                            : 'expense';
                      }),
                      color: FynceeColors.expenseRed,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Resumen de ingresos/egresos de la semana
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildWeekSummaryItem(
                        'Ingresos',
                        weekIncome,
                        Icons.arrow_downward_rounded,
                        FynceeColors.incomeGreen,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: FynceeColors.background,
                    ),
                    Expanded(
                      child: _buildWeekSummaryItem(
                        'Egresos',
                        weekExpense,
                        Icons.arrow_upward_rounded,
                        FynceeColors.expenseRed,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Gráfica semanal
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Balance de ${_selectedPeriod.label.toLowerCase()}',
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      NumberFormat.currency(
                        locale: 'es_MX',
                        symbol: '\$',
                        decimalDigits: 2,
                      ).format(_balance),
                      style: TextStyle(
                        color: textPrimaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(height: 180, child: _buildWeekChart()),
                    const SizedBox(height: 16),
                    // Leyenda
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem('Ingresos', FynceeColors.incomeGreen),
                        const SizedBox(width: 24),
                        _buildLegendItem('Egresos', FynceeColors.expenseRed),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Lista de todas las transacciones
              if (_filteredTransactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 64,
                          color: textSecondaryColor.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _transactions.isEmpty
                              ? 'No hay movimientos'
                              : 'No se encontraron resultados',
                          style: TextStyle(
                            color: textSecondaryColor.withValues(
                              alpha: 0.8,
                            ),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ..._filteredTransactions.map((transaction) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: TransactionItem(
                      transaction: transaction,
                      onEdit: () => _editTransaction(transaction),
                      onDelete: () => _deleteTransaction(transaction),
                    ),
                  );
                }),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekSummaryItem(
    String label,
    double amount,
    IconData icon,
    Color color,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: textSecondaryColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              NumberFormat.currency(
                locale: 'es_MX',
                symbol: '\$',
                decimalDigits: 0,
              ).format(amount),
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: textSecondaryColor.withValues(alpha: 0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (color ?? FynceeColors.primary)
              : FynceeColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? (color ?? FynceeColors.primary)
                : FynceeColors.surface,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : FynceeColors.textSecondary.withValues(alpha: 0.8),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildWeekChart() {
    // Usar el período seleccionado
    final startDate = _selectedPeriod.startDate;
    final endDate = _selectedPeriod.endDate;
    final daysDiff = endDate.difference(startDate).inDays + 1;
    
    // Determinar el intervalo y número de puntos según el período
    int maxPoints;
    int intervalDays;
    
    if (daysDiff <= 7) {
      // Semana: 1 punto por día
      maxPoints = daysDiff;
      intervalDays = 1;
    } else if (daysDiff <= 31) {
      // Mes: 1 punto por día
      maxPoints = daysDiff;
      intervalDays = 1;
    } else if (daysDiff <= 90) {
      // 3 meses: 1 punto cada 3 días
      maxPoints = (daysDiff / 3).ceil();
      intervalDays = 3;
    } else if (daysDiff <= 180) {
      // 6 meses: 1 punto cada 6 días
      maxPoints = (daysDiff / 6).ceil();
      intervalDays = 6;
    } else {
      // Año o más: 1 punto cada 10 días
      maxPoints = (daysDiff / 10).ceil();
      intervalDays = 10;
    }

    final Map<int, double> incomeData = {};
    final Map<int, double> expenseData = {};

    for (int i = 0; i < maxPoints; i++) {
      final periodStart = startDate.add(Duration(days: i * intervalDays));
      final periodEnd = i < maxPoints - 1
          ? startDate.add(Duration(days: (i + 1) * intervalDays))
          : endDate.add(const Duration(days: 1));

      final periodTransactions = _transactions.where((t) {
        return t.date.isAfter(periodStart.subtract(const Duration(seconds: 1))) &&
            t.date.isBefore(periodEnd);
      });

      incomeData[i] = periodTransactions
          .where((t) => t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
      expenseData[i] = periodTransactions
          .where((t) => !t.isIncome)
          .fold(0.0, (sum, t) => sum + t.amount);
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getMaxValue(incomeData, expenseData) > 0 
              ? (_getMaxValue(incomeData, expenseData) / 4) 
              : 500,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: FynceeColors.background, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxPoints > 6 ? (maxPoints / 6).ceil().toDouble() : 1,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < maxPoints) {
                  final date = startDate.add(Duration(days: value.toInt() * intervalDays));
                  
                  String label;
                  if (daysDiff <= 7) {
                    // Semana: mostrar día de la semana
                    label = DateFormat('EEE', 'es').format(date).substring(0, 3);
                  } else if (daysDiff <= 31) {
                    // Mes: mostrar día del mes
                    label = DateFormat('d', 'es').format(date);
                  } else {
                    // Más de un mes: mostrar día/mes
                    label = DateFormat('d/M', 'es').format(date);
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label,
                      style: TextStyle(
                        color: textSecondaryColor.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: (maxPoints - 1).toDouble(),
        minY: 0,
        maxY: _getMaxValue(incomeData, expenseData) * 1.2,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (touchedSpot) => FynceeColors.surface.withValues(alpha: 0.95),
            tooltipRoundedRadius: 8,
            tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            tooltipMargin: 8,
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              if (touchedBarSpots.isEmpty) return [];
              
              // Obtener la fecha solo una vez del primer punto tocado
              final spotIndex = touchedBarSpots.first.x.toInt();
              final date = startDate.add(Duration(days: spotIndex * intervalDays));
              final dateEnd = spotIndex < maxPoints - 1
                  ? startDate.add(Duration(days: (spotIndex + 1) * intervalDays - 1))
                  : endDate;
              
              String dateLabel;
              if (intervalDays == 1) {
                // Para días individuales
                dateLabel = DateFormat('d MMM yyyy', 'es').format(date);
              } else {
                // Para rangos de días
                dateLabel = '${DateFormat('d MMM', 'es').format(date)} - ${DateFormat('d MMM yyyy', 'es').format(dateEnd)}';
              }
              
              // Crear un solo tooltip con ambos valores
              return touchedBarSpots.asMap().entries.map((entry) {
                final index = entry.key;
                final barSpot = entry.value;
                final isIncome = barSpot.barIndex == 0;
                final amount = barSpot.y;
                final label = isIncome ? 'Ingresos' : 'Gastos';
                final color = isIncome ? FynceeColors.incomeGreen : FynceeColors.expenseRed;
                
                // Solo mostrar la fecha en el primer tooltip
                if (index == 0) {
                  return LineTooltipItem(
                    '$dateLabel\n$label: \$${amount.toStringAsFixed(2)}',
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                } else {
                  return LineTooltipItem(
                    '$label: \$${amount.toStringAsFixed(2)}',
                    TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
              }).toList();
            },
          ),
          handleBuiltInTouches: true,
          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((spotIndex) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: (barData.color ?? FynceeColors.primary).withValues(alpha: 0.5),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                ),
                FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 6,
                      color: barData.color ?? FynceeColors.primary,
                      strokeWidth: 2,
                      strokeColor: FynceeColors.surface,
                    );
                  },
                ),
              );
            }).toList();
          },
        ),
        lineBarsData: [
          // Línea de ingresos
          LineChartBarData(
            spots: incomeData.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: FynceeColors.incomeGreen,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: FynceeColors.incomeGreen,
                  strokeWidth: 2,
                  strokeColor: FynceeColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
          // Línea de egresos
          LineChartBarData(
            spots: expenseData.entries
                .map((e) => FlSpot(e.key.toDouble(), e.value))
                .toList(),
            isCurved: true,
            color: FynceeColors.expenseRed,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: FynceeColors.expenseRed,
                  strokeWidth: 2,
                  strokeColor: FynceeColors.surface,
                );
              },
            ),
            belowBarData: BarAreaData(show: false),
          ),
        ],
      ),
    );
  }

  double _getMaxValue(
    Map<int, double> incomeData,
    Map<int, double> expenseData,
  ) {
    final maxIncome = incomeData.values.isEmpty
        ? 0.0
        : incomeData.values.reduce((a, b) => a > b ? a : b);
    final maxExpense = expenseData.values.isEmpty
        ? 0.0
        : expenseData.values.reduce((a, b) => a > b ? a : b);
    final max = maxIncome > maxExpense ? maxIncome : maxExpense;
    return max > 0 ? max : 1500;
  }

  Widget _buildGoalsPage() {
    return GoalsPage(
      onGoalChanged: () {
        // Recargar metas cuando se crea/actualiza/elimina una
        _loadGoals();
      },
    );
  }

  Widget _buildProfilePage() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 20),
        // Avatar y nombre de usuario
        Center(
          child: Column(
            children: [
              Stack(
                children: [
                  GestureDetector(
                    onTap: _showProfileImageOptions,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: FynceeColors.primary.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        image: _getImageProvider(_profileImagePath) != null
                            ? DecorationImage(
                                image: _getImageProvider(_profileImagePath)!,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profileImagePath == null
                          ? Icon(
                              Icons.person_rounded,
                              size: 40,
                              color: FynceeColors.primary,
                            )
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showProfileImageOptions,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: FynceeColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: surfaceColor,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          Icons.camera_alt_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                _userName,
                style: TextStyle(
                  color: textPrimaryColor,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _userEmail,
                style: TextStyle(
                  color: textSecondaryColor.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Sección de Perfil
        _buildSectionTitle('Mi Perfil'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(
            icon: Icons.person_rounded,
            title: 'Información personal',
            subtitle: 'Nombre, correo y preferencias',
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileInfoScreen()),
              );
              // Si se guardaron cambios, recargar el perfil
              if (result == true) {
                _loadUserProfile();
                _loadCarryOverBalance();
                _loadTransactions();
              }
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.lock_rounded,
            title: 'Seguridad',
            subtitle: 'Contraseña, biometría y PIN',
            onTap: _showSecurityDialog,
          ),
        ]),

        const SizedBox(height: 24),

        // Sección de Aplicación
        _buildSectionTitle('Aplicación'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(
            icon: Icons.category_rounded,
            title: 'Categorías',
            subtitle: 'Gestiona tus categorías',
            onTap: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CategoriesPage()));
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.notifications_rounded,
            title: 'Notificaciones',
            subtitle: 'Alertas y recordatorios',
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.account_balance_rounded,
            title: 'Notificaciones bancarias',
            subtitle: 'Registrar transacciones automáticamente',
            onTap: _showBankNotificationsDialog,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.brightness_6_rounded,
            title: 'Tema',
            subtitle: 'Claro u oscuro',
            onTap: _showThemeDialog,
          ),
        ]),

        const SizedBox(height: 24),

        // Sección de Cuenta
        _buildSectionTitle('Cuenta'),
        const SizedBox(height: 12),
        _buildMenuCard([
          _buildMenuItem(
            icon: Icons.cloud_sync_rounded,
            title: 'Sincronización',
            subtitle: 'Respalda tus datos',
            onTap: _showSyncDialog,
          ),
          _buildDivider(),
          _buildMenuItem(
            icon: Icons.info_rounded,
            title: 'Acerca de',
            subtitle: 'Versión 1.0.0',
            onTap: () {
              _showAboutDialog();
            },
          ),
        ]),

        const SizedBox(height: 24),

        // Botón de cerrar sesión
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: _showLogoutDialog,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout_rounded, color: FynceeColors.error),
                const SizedBox(width: 12),
                Text(
                  'Cerrar sesión',
                  style: TextStyle(
                    color: FynceeColors.error,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          color: textSecondaryColor.withValues(alpha: 0.8),
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: FynceeColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: FynceeColors.primary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: textSecondaryColor.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondaryColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: FynceeColors.background,
      indent: 16,
      endIndent: 16,
    );
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función próximamente disponible'),
        backgroundColor: FynceeColors.primary,
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Fyncee',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versión 1.0.0',
              style: TextStyle(
                color: textSecondaryColor.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Tu asistente personal de finanzas. Gestiona tus ingresos, gastos y alcanza tus metas financieras.',
              style: TextStyle(
                color: textSecondaryColor.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cerrar',
              style: TextStyle(color: FynceeColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '¿Cerrar sesión?',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          '¿Estás seguro que deseas cerrar sesión? Tus datos están guardados en la nube.',
          style: TextStyle(
            color: textSecondaryColor.withValues(alpha: 0.8),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Cancelar',
              style: TextStyle(color: textSecondaryColor),
            ),
          ),
          TextButton(
            onPressed: () async {
              // Limpiar datos locales
              await DatabaseService().clearAllData();
              
              // Cerrar sesión
              await AuthService().signOut();
              
              // Cerrar diálogo y navegar en el mismo frame
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext); // Cerrar diálogo
              }
              
              // Navegar a login usando el contexto del HomePage
              if (mounted && context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            child: Text(
              'Cerrar sesión',
              style: TextStyle(color: FynceeColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog() async {
    final biometricService = BiometricAuthService();
    bool canUseBiometric = await biometricService.canUseBiometrics();
    bool isBiometricEnabled = await biometricService.isBiometricEnabled();
    bool isPinEnabled = await biometricService.isPinEnabled();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.lock_rounded, color: FynceeColors.primary),
              const SizedBox(width: 12),
              Text(
                'Seguridad',
                style: TextStyle(
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Protege tu información financiera',
                  style: TextStyle(
                    color: textSecondaryColor.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Cambiar contraseña
                InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showChangePasswordDialog();
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: FynceeColors.textSecondary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.key_rounded,
                          color: FynceeColors.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cambiar contraseña',
                                style: TextStyle(
                                  color: textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Actualiza tu contraseña de acceso',
                                style: TextStyle(
                                  color: textSecondaryColor.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: textSecondaryColor,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Biometría
                InkWell(
                  onTap: canUseBiometric
                      ? () async {
                          if (!isBiometricEnabled) {
                            bool authenticated = await biometricService.authenticateWithBiometrics();
                            if (authenticated) {
                              await biometricService.setBiometricEnabled(true);
                              setState(() => isBiometricEnabled = true);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Autenticación biométrica activada')),
                                );
                              }
                            }
                          } else {
                            await biometricService.setBiometricEnabled(false);
                            setState(() => isBiometricEnabled = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Autenticación biométrica desactivada')),
                              );
                            }
                          }
                        }
                      : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: canUseBiometric
                          ? (isBiometricEnabled
                              ? FynceeColors.primary.withValues(alpha: 0.1)
                              : Colors.transparent)
                          : FynceeColors.textSecondary.withValues(alpha: 0.05),
                      border: Border.all(
                        color: isBiometricEnabled
                            ? FynceeColors.primary
                            : FynceeColors.textSecondary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          color: canUseBiometric
                              ? (isBiometricEnabled
                                  ? FynceeColors.primary
                                  : FynceeColors.textSecondary)
                              : FynceeColors.textSecondary.withValues(alpha: 0.3),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Autenticación biométrica',
                                style: TextStyle(
                                  color: canUseBiometric
                                      ? FynceeColors.textPrimary
                                      : FynceeColors.textSecondary.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                canUseBiometric
                                    ? (isBiometricEnabled ? 'Activada' : 'Desactivada')
                                    : 'No disponible en este dispositivo',
                                style: TextStyle(
                                  color: textSecondaryColor.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (canUseBiometric)
                          Switch(
                            value: isBiometricEnabled,
                            onChanged: (value) async {
                              if (value) {
                                bool authenticated = await biometricService.authenticateWithBiometrics();
                                if (authenticated) {
                                  await biometricService.setBiometricEnabled(true);
                                  setState(() => isBiometricEnabled = true);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Autenticación biométrica activada')),
                                    );
                                  }
                                }
                              } else {
                                await biometricService.setBiometricEnabled(false);
                                setState(() => isBiometricEnabled = false);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Autenticación biométrica desactivada')),
                                  );
                                }
                              }
                            },
                            activeColor: FynceeColors.primary,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // PIN
                InkWell(
                  onTap: () async {
                    if (!isPinEnabled) {
                      Navigator.pop(context);
                      _showCreatePinDialog();
                    } else {
                      await biometricService.removePin();
                      setState(() => isPinEnabled = false);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('PIN eliminado')),
                        );
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isPinEnabled
                          ? FynceeColors.primary.withValues(alpha: 0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isPinEnabled
                            ? FynceeColors.primary
                            : FynceeColors.textSecondary.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.pin_rounded,
                          color: isPinEnabled
                              ? FynceeColors.primary
                              : FynceeColors.textSecondary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PIN de seguridad',
                                style: TextStyle(
                                  color: textPrimaryColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isPinEnabled ? 'Configurado' : 'No configurado',
                                style: TextStyle(
                                  color: textSecondaryColor.withValues(alpha: 0.7),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: isPinEnabled,
                          onChanged: (value) async {
                            if (value) {
                              Navigator.pop(context);
                              _showCreatePinDialog();
                            } else {
                              await biometricService.removePin();
                              setState(() => isPinEnabled = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('PIN eliminado')),
                                );
                              }
                            }
                          },
                          activeColor: FynceeColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(color: FynceeColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreatePinDialog() {
    String pin = '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear PIN'),
        content: TextField(
          keyboardType: TextInputType.number,
          maxLength: 4,
          obscureText: true,
          onChanged: (value) => pin = value,
          decoration: const InputDecoration(
            labelText: 'Ingresa un PIN de 4 dígitos',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              if (pin.length == 4) {
                await BiometricAuthService().savePin(pin);
                Navigator.pop(context);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('PIN creado exitosamente')),
                  );
                }
              }
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrentPassword = true;
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.key_rounded, color: FynceeColors.primary),
              const SizedBox(width: 12),
              Text(
                'Cambiar contraseña',
                style: TextStyle(
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrentPassword,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    labelStyle: TextStyle(color: textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        color: textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureCurrentPassword = !obscureCurrentPassword;
                        });
                      },
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textSecondaryColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNewPassword,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Nueva contraseña',
                    labelStyle: TextStyle(color: textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        color: textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureNewPassword = !obscureNewPassword;
                        });
                      },
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textSecondaryColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirmPassword,
                  style: TextStyle(color: textPrimaryColor),
                  decoration: InputDecoration(
                    labelText: 'Confirmar nueva contraseña',
                    labelStyle: TextStyle(color: textSecondaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: textSecondaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          obscureConfirmPassword = !obscureConfirmPassword;
                        });
                      },
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: textSecondaryColor.withValues(alpha: 0.3)),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: FynceeColors.primary),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancelar',
                style: TextStyle(color: textSecondaryColor),
              ),
            ),
            TextButton(
              onPressed: () async {
                final currentPassword = currentPasswordController.text;
                final newPassword = newPasswordController.text;
                final confirmPassword = confirmPasswordController.text;
                
                if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor completa todos los campos')),
                  );
                  return;
                }
                
                if (newPassword != confirmPassword) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Las contraseñas no coinciden')),
                  );
                  return;
                }
                
                if (newPassword.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
                  );
                  return;
                }
                
                try {
                  // Re-autenticar con la contraseña actual
                  final email = AuthService().currentUser?.email;
                  if (email == null) {
                    throw Exception('No se pudo obtener el email del usuario');
                  }
                  
                  // Intentar login con contraseña actual para verificar
                  await AuthService().signInWithEmail(email: email, password: currentPassword);
                  
                  // Si el login fue exitoso, actualizar la contraseña
                  await AuthService().updatePassword(newPassword);
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Contraseña actualizada exitosamente')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    String errorMessage = 'Error al actualizar contraseña';
                    if (e.toString().contains('Invalid login')) {
                      errorMessage = 'Contraseña actual incorrecta';
                    }
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(errorMessage)),
                    );
                  }
                }
              },
              child: Text(
                'Guardar',
                style: TextStyle(color: FynceeColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog() async {
    final isDark = await ThemeService().isDarkMode();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.brightness_6_rounded, color: FynceeColors.primary),
              const SizedBox(width: 12),
              Text(
                'Tema',
                style: TextStyle(
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Opción: Tema Claro
              InkWell(
                onTap: () async {
                  await ThemeService().setDarkMode(false);
                  FynceeApp.of(context)?.setTheme(false);
                  setState(() {});
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: !isDark
                        ? FynceeColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: !isDark
                          ? FynceeColors.primary
                          : FynceeColors.textSecondary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.light_mode_rounded,
                        color: !isDark
                            ? FynceeColors.primary
                            : FynceeColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tema Claro',
                              style: TextStyle(
                                color: textPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Interfaz con fondo blanco',
                              style: TextStyle(
                                color: textSecondaryColor.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isDark)
                        Icon(
                          Icons.check_circle_rounded,
                          color: FynceeColors.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Opción: Tema Oscuro
              InkWell(
                onTap: () async {
                  await ThemeService().setDarkMode(true);
                  FynceeApp.of(context)?.setTheme(true);
                  setState(() {});
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? FynceeColors.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    border: Border.all(
                      color: isDark
                          ? FynceeColors.primary
                          : FynceeColors.textSecondary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.dark_mode_rounded,
                        color: isDark
                            ? FynceeColors.primary
                            : FynceeColors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tema Oscuro',
                              style: TextStyle(
                                color: textPrimaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Interfaz con fondo oscuro',
                              style: TextStyle(
                                color: textSecondaryColor.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isDark)
                        Icon(
                          Icons.check_circle_rounded,
                          color: FynceeColors.primary,
                          size: 24,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cerrar',
                style: TextStyle(color: FynceeColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBankNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.account_balance_rounded, color: FynceeColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Notificaciones bancarias',
                style: TextStyle(
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Registra transacciones automáticamente desde notificaciones de tu banco.',
                style: TextStyle(
                  color: textSecondaryColor,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              
              // Instrucciones
              _buildInfoBox(
                icon: Icons.phone_android_rounded,
                title: 'Cómo funciona',
                description: 'Cuando recibas una notificación de tu banco sobre una transacción, '
                    'Fyncee puede leerla y crear automáticamente el registro en tu historial.',
              ),
              const SizedBox(height: 12),
              
              _buildInfoBox(
                icon: Icons.security_rounded,
                title: 'Privacidad',
                description: 'Fyncee solo lee notificaciones de bancos que tú autorices. '
                    'Tus datos bancarios nunca se comparten.',
                color: FynceeColors.success,
              ),
              const SizedBox(height: 12),
              
              _buildInfoBox(
                icon: Icons.settings_rounded,
                title: 'Configuración',
                description: 'Ve a Ajustes de Android > Notificaciones > Acceso a notificaciones '
                    'y activa Fyncee.',
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              
              // Nota sobre disponibilidad y fase
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.purple.withValues(alpha: 0.1),
                      Colors.blue.withValues(alpha: 0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.purple.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'ALPHA',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Función en desarrollo',
                            style: TextStyle(
                              color: Colors.purple,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.rocket_launch_rounded,
                          color: Colors.purple.withValues(alpha: 0.7),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Esta característica estará disponible próximamente en Android. '
                            'Estamos trabajando para ofrecerte la mejor experiencia.',
                            style: TextStyle(
                              color: textSecondaryColor.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendido',
              style: TextStyle(
                color: FynceeColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox({
    required IconData icon,
    required String title,
    required String description,
    Color? color,
  }) {
    final boxColor = color ?? FynceeColors.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: boxColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: boxColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: boxColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: textSecondaryColor.withValues(alpha: 0.8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProfileImageOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textSecondaryColor.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Foto de perfil',
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Icon(
                Icons.photo_library_rounded,
                color: FynceeColors.primary,
              ),
              title: Text(
                'Elegir de galería',
                style: TextStyle(color: textPrimaryColor),
              ),
              onTap: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                
                print('🖼️  Abriendo selector de galería...');
                final file = await ProfileImageService().pickImageFromGallery();
                print('🖼️  Archivo seleccionado: ${file?.path}');
                
                if (file != null && mounted) {
                  setState(() {
                    _profileImagePath = file.path;
                  });
                  print('✅ Foto de perfil actualizada: $_profileImagePath');
                  
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Foto de perfil actualizada'),
                      backgroundColor: FynceeColors.incomeGreen,
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: Icon(
                Icons.camera_alt_rounded,
                color: FynceeColors.primary,
              ),
              title: Text(
                'Tomar foto',
                style: TextStyle(color: textPrimaryColor),
              ),
              onTap: () async {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                nav.pop();
                
                final file = await ProfileImageService().pickImageFromCamera();
                
                if (file != null && mounted) {
                  setState(() {
                    _profileImagePath = file.path;
                  });
                  
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Foto de perfil actualizada'),
                      backgroundColor: FynceeColors.incomeGreen,
                    ),
                  );
                }
              },
            ),
            if (_profileImagePath != null)
              ListTile(
                leading: Icon(
                  Icons.delete_rounded,
                  color: FynceeColors.error,
                ),
                title: Text(
                  'Eliminar foto',
                  style: TextStyle(color: FynceeColors.error),
                ),
                onTap: () async {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);
                  nav.pop();
                  
                  await ProfileImageService().clearProfileImage();
                  
                  if (mounted) {
                    setState(() {
                      _profileImagePath = null;
                    });
                    
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Foto de perfil eliminada'),
                        backgroundColor: FynceeColors.textSecondary,
                      ),
                    );
                  }
                },
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cloud_sync_rounded, color: FynceeColors.primary),
            const SizedBox(width: 12),
            Text(
              'Sincronización',
              style: TextStyle(
                color: textPrimaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sincronizando tus datos...',
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );

    // Simular sincronización
    await Future.delayed(const Duration(seconds: 2));
    
    // Recargar datos
    await _loadTransactions();
    await _loadGoals();
    
    if (mounted) {
      Navigator.pop(context); // Cerrar diálogo de carga
      
      // Mostrar éxito
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: FynceeColors.incomeGreen),
              const SizedBox(width: 12),
              Text(
                'Sincronización completa',
                style: TextStyle(
                  color: textPrimaryColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSyncStat('Transacciones', _transactions.length),
              const SizedBox(height: 8),
              _buildSyncStat('Metas', _goals.length),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: FynceeColors.incomeGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_done_rounded,
                      color: FynceeColors.incomeGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Todos tus datos están respaldados en la nube',
                        style: TextStyle(
                          color: FynceeColors.incomeGreen,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Aceptar',
                style: TextStyle(color: FynceeColors.primary),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool enabled,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: FynceeColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: textSecondaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textSecondaryColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: null, // Deshabilitado por ahora
            activeColor: FynceeColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStat(String label, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textSecondaryColor.withValues(alpha: 0.8),
            fontSize: 14,
          ),
        ),
        Text(
          count.toString(),
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Future<void> _editTransaction(Transaction transaction) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddTransactionPage(
          transactionToEdit: transaction,
        ),
      ),
    );
    
    if (result == true) {
      await _loadTransactions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Transacción actualizada'),
            backgroundColor: FynceeColors.incomeGreen,
          ),
        );
      }
    }
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    try {
      // Eliminar de Supabase
      await SupabaseService().deleteTransaction(transaction.id);
      
      // Eliminar de la lista local
      setState(() {
        _transactions.removeWhere((t) => t.id == transaction.id);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Movimiento eliminado'),
          backgroundColor: FynceeColors.incomeGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al eliminar: $e'),
          backgroundColor: FynceeColors.error,
        ),
      );
    }
  }
}
