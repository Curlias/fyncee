import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/supabase_service.dart';
import '../services/auth_service.dart';

class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;

  // Método helper para obtener colores según el tema
  Color get backgroundColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.background 
      : FynceeColors.lightBackground;
  
  Color get surfaceColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.surface 
      : FynceeColors.lightSurface;
  
  Color get textPrimaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textPrimary 
      : FynceeColors.lightTextPrimary;
  
  Color get textSecondaryColor => Theme.of(context).brightness == Brightness.dark 
      ? FynceeColors.textSecondary 
      : FynceeColors.lightTextSecondary;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    final categories = await SupabaseService().getAllCategories();
    if (mounted) {
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _filteredCategories {
    if (_searchQuery.isEmpty) {
      return _categories;
    }
    return _categories
        .where(
          (cat) => (cat['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  IconData _getIconData(String iconName) {
    // Map de nombres de iconos a IconData
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Categorías',
          style: TextStyle(
            color: textPrimaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.visibility_outlined, color: textPrimaryColor),
            onPressed: _showHiddenCategories,
            tooltip: 'Ver categorías ocultas',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
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
                  hintText: 'Buscar categoría',
                  hintStyle: TextStyle(
                    color: textSecondaryColor.withValues(alpha: 0.6),
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: textSecondaryColor,
                  ),
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
          ),

          // Grid de categorías
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      itemCount: _filteredCategories.length + 1,
                      itemBuilder: (context, index) {
                        // Último item: botón "Agregar"
                        if (index == _filteredCategories.length) {
                          return _buildAddCategoryButton();
                        }

                        final category = _filteredCategories[index];
                        return _buildCategoryItem(category);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(Map<String, dynamic> category) {
    final name = category['name'] as String;
    final icon = category['icon'] as String;
    final colorValue = category['color_value'] as int;
    final isDefault = category['is_default'] as bool? ?? false;
    
    return GestureDetector(
      onTap: () {
        _showCategoryOptions(category);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                _getIconData(icon),
                size: 32,
                color: Color(colorValue),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddCategoryButton() {
    return GestureDetector(
      onTap: () {
        _showAddCategoryDialog();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: textSecondaryColor.withValues(alpha: 0.3),
                width: 2,
                strokeAlign: BorderSide.strokeAlignInside,
              ),
            ),
            child: Center(
              child: Icon(
                Icons.add,
                size: 32,
                color: textSecondaryColor.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agregar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondaryColor.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryOptions(Map<String, dynamic> category) {
    final isDefault = category['is_default'] as bool? ?? false;
    final userId = category['user_id'];
    final isGlobal = isDefault && userId == null;
    
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
            Icon(
              _getIconData(category['icon'] as String),
              size: 48,
              color: Color(category['color_value'] as int),
            ),
            const SizedBox(height: 12),
            Text(
              category['name'] as String,
              style: TextStyle(
                color: textPrimaryColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isGlobal ? 'Categoría global' : 'Categoría personalizada',
              style: TextStyle(
                color: textSecondaryColor.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 24),
            if (!isGlobal) ...[
              ListTile(
                leading: Icon(
                  Icons.edit_rounded,
                  color: FynceeColors.primary,
                ),
                title: Text(
                  'Editar categoría',
                  style: TextStyle(color: textPrimaryColor),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditCategoryDialog(category);
                },
              ),
            ],
            ListTile(
              leading: Icon(
                isGlobal ? Icons.visibility_off_rounded : Icons.delete_rounded,
                color: FynceeColors.error,
              ),
              title: Text(
                isGlobal ? 'Ocultar categoría' : 'Eliminar categoría',
                style: TextStyle(color: FynceeColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(category);
              },
            ),
            if (isGlobal)
              ListTile(
                leading: Icon(
                  Icons.info_outline_rounded,
                  color: textSecondaryColor,
                ),
                title: Text(
                  'Las categorías ocultas se pueden volver a mostrar desde el menú superior',
                  style: TextStyle(
                    color: textSecondaryColor.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog() {
    final nameController = TextEditingController();
    String selectedType = 'egreso';
    String selectedIcon = 'category';
    Color selectedColor = Colors.blueAccent;

    final availableIcons = [
      'restaurant', 'directions_car', 'movie', 'shopping_bag', 'local_hospital',
      'school', 'build', 'home', 'more_horiz', 'account_balance_wallet',
      'trending_up', 'sell', 'computer', 'card_giftcard', 'attach_money',
      'flight', 'sports_soccer', 'local_cafe', 'pets', 'fitness_center',
      'phone_android', 'laptop', 'games', 'music_note', 'brush',
      'beach_access', 'spa', 'hotel', 'local_gas_station', 'shopping_cart',
      'fastfood', 'local_pizza', 'cake', 'wine_bar',
    ];

    final availableColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Nueva Categoría',
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: textSecondaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: textSecondaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FynceeColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tipo
                  Text(
                    'Tipo',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Ingreso'),
                          selected: selectedType == 'ingreso',
                          onSelected: (selected) {
                            setDialogState(() => selectedType = 'ingreso');
                          },
                          selectedColor: FynceeColors.primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'ingreso' ? Colors.white : textPrimaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('Egreso'),
                          selected: selectedType == 'egreso',
                          onSelected: (selected) {
                            setDialogState(() => selectedType = 'egreso');
                          },
                          selectedColor: FynceeColors.primary,
                          labelStyle: TextStyle(
                            color: selectedType == 'egreso' ? Colors.white : textPrimaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Icono
                  Text(
                    'Icono',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedIcon = icon);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? FynceeColors.primary.withValues(alpha: 0.2) : backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? FynceeColors.primary : textSecondaryColor.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              color: isSelected ? FynceeColors.primary : textPrimaryColor,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Color
                  Text(
                    'Color',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableColors.length,
                      itemBuilder: (context, index) {
                        final color = availableColors[index];
                        final isSelected = color == selectedColor;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = color);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un nombre')),
                  );
                  return;
                }
                
                try {
                  await SupabaseService().createCategory(
                    name: nameController.text.trim(),
                    type: selectedType,
                    icon: selectedIcon,
                    colorValue: selectedColor.value,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoría creada exitosamente'),
                        backgroundColor: FynceeColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: FynceeColors.primary,
              ),
              child: const Text('Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCategoryDialog(Map<String, dynamic> category) {
    final nameController = TextEditingController(text: category['name'] as String);
    String selectedIcon = category['icon'] as String;
    Color selectedColor = Color(category['color_value'] as int);

    final availableIcons = [
      'restaurant', 'directions_car', 'movie', 'shopping_bag', 'local_hospital',
      'school', 'build', 'home', 'more_horiz', 'account_balance_wallet',
      'trending_up', 'sell', 'computer', 'card_giftcard', 'attach_money',
      'flight', 'sports_soccer', 'local_cafe', 'pets', 'fitness_center',
      'phone_android', 'laptop', 'games', 'music_note', 'brush',
      'beach_access', 'spa', 'hotel', 'local_gas_station', 'shopping_cart',
      'fastfood', 'local_pizza', 'cake', 'wine_bar',
    ];

    final availableColors = [
      Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,
      Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,
      Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,
      Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: surfaceColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Editar Categoría',
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: textPrimaryColor),
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      labelStyle: TextStyle(color: textSecondaryColor),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: textSecondaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: FynceeColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Icono
                  Text(
                    'Icono',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 150,
                    child: GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 6,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: availableIcons.length,
                      itemBuilder: (context, index) {
                        final icon = availableIcons[index];
                        final isSelected = icon == selectedIcon;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedIcon = icon);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? FynceeColors.primary.withValues(alpha: 0.2) : backgroundColor,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? FynceeColors.primary : textSecondaryColor.withValues(alpha: 0.2),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              _getIconData(icon),
                              color: isSelected ? FynceeColors.primary : textPrimaryColor,
                              size: 24,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Color
                  Text(
                    'Color',
                    style: TextStyle(
                      color: textPrimaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 60,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: availableColors.length,
                      itemBuilder: (context, index) {
                        final color = availableColors[index];
                        final isSelected = color.value == selectedColor.value;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() => selectedColor = color);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 3,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ] : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa un nombre')),
                  );
                  return;
                }
                
                try {
                  await SupabaseService().updateCategory(
                    category['id'] as int,
                    name: nameController.text.trim(),
                    icon: selectedIcon,
                    colorValue: selectedColor.value,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    _loadCategories();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Categoría actualizada'),
                        backgroundColor: FynceeColors.primary,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: FynceeColors.primary,
              ),
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Map<String, dynamic> category) {
    final isDefault = category['is_default'] as bool? ?? false;
    final userId = category['user_id'];
    final isGlobal = isDefault && userId == null;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isGlobal ? '¿Ocultar categoría?' : '¿Eliminar categoría?',
          style: TextStyle(
            color: textPrimaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          isGlobal
              ? 'Esta categoría se ocultará solo para ti. Podrás volver a mostrarla desde la configuración.'
              : 'Esta acción no se puede deshacer.',
          style: TextStyle(
            color: textSecondaryColor.withValues(alpha: 0.8),
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
          FilledButton(
            onPressed: () async {
              try {
                await SupabaseService().deleteCategory(category['id'] as int);
                
                if (context.mounted) {
                  Navigator.pop(context);
                  _loadCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isGlobal ? 'Categoría ocultada' : 'Categoría eliminada'),
                      backgroundColor: FynceeColors.primary,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: FynceeColors.error,
            ),
            child: Text(isGlobal ? 'Ocultar' : 'Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showHiddenCategories() async {
    try {
      // Obtener todas las categorías globales ocultas
      final supabase = SupabaseService();
      final userId = AuthService().currentUserId;
      
      if (userId == null) return;
      
      final hiddenResponse = await supabase.client
          .from('user_hidden_categories')
          .select('category_id')
          .eq('user_id', userId);
      
      final hiddenIds = (hiddenResponse as List)
          .map((item) => item['category_id'] as int)
          .toSet();
      
      if (hiddenIds.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tienes categorías ocultas'),
              backgroundColor: FynceeColors.primary,
            ),
          );
        }
        return;
      }
      
      final allGlobalCategories = await supabase.client
          .from('categories')
          .select()
          .or('user_id.is.null')
          .inFilter('id', hiddenIds.toList());
      
      if (context.mounted) {
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
                  'Categorías Ocultas',
                  style: TextStyle(
                    color: textPrimaryColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: (allGlobalCategories as List).length,
                    itemBuilder: (context, index) {
                      final category = allGlobalCategories[index];
                      return ListTile(
                        leading: Icon(
                          _getIconData(category['icon'] as String),
                          color: Color(category['color_value'] as int),
                        ),
                        title: Text(
                          category['name'] as String,
                          style: TextStyle(color: textPrimaryColor),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.visibility_rounded,
                            color: FynceeColors.primary,
                          ),
                          onPressed: () async {
                            try {
                              await supabase.showCategory(category['id'] as int);
                              if (context.mounted) {
                                Navigator.pop(context);
                                _loadCategories();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Categoría visible nuevamente'),
                                    backgroundColor: FynceeColors.primary,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
