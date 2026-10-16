import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inventory/controller/shopkpprovider.dart';
import 'package:inventory/model/ordertrack.dart';
import 'package:inventory/model/product.dart';
import 'package:inventory/model/product_category.dart';
import 'package:inventory/model/saler.dart';
import 'package:inventory/model/shopmodel.dart';
import 'package:inventory/model/stock.dart';
import 'package:inventory/provider/shopkp.dart';

class ShopkeeperScreen extends ConsumerStatefulWidget {
  final int warehouseId;

  const ShopkeeperScreen({super.key, required this.warehouseId});

  @override
  ConsumerState<ShopkeeperScreen> createState() => _ShopkeeperScreenState();
}

class _ShopkeeperScreenState extends ConsumerState<ShopkeeperScreen> {
  int selectedIndex = 0;

  final TextEditingController searchController = TextEditingController();

  static const Color primaryColor = Color(0xFF2878D0);
  static const Color backgroundColor = Color(0xFFF7F9FC);

  ShopkeeperController get controller => ref.read(shopprovider.notifier);

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      if (controller.warehouseExists(widget.warehouseId)) {
        controller.syncData(widget.warehouseId);
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  /// Dispose dialog controllers only AFTER the dialog's close animation
  /// has finished (prevents the '_dependents.isEmpty' assertion).
  void _disposeLater(List<TextEditingController> controllers) {
    Future.delayed(const Duration(milliseconds: 500), () {
      for (final c in controllers) {
        c.dispose();
      }
    });
  }

  void refreshData() {
    if (mounted) {
      controller.syncData(widget.warehouseId);
    }
  }

  void openPage(int index) {
    setState(() {
      selectedIndex = index;
      searchController.clear();
    });

    if (index == 1) {
      controller.clearProductSearch(widget.warehouseId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Shopmodel state = ref.watch(shopprovider);

    if (!controller.warehouseExists(widget.warehouseId)) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(title: const Text('Shopkeeper')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This warehouse could not be found. '
              'Please contact the administrator.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final pages = <Widget>[
      _buildDashboard(state),
      _buildProducts(state),
      _buildCategories(state),
      _buildSellers(state),
      _buildStock(state),
      _buildOrders(state),
    ];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(_pageTitle(selectedIndex)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1D2939),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: refreshData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(index: selectedIndex, children: pages),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex <= 2 ? selectedIndex : 3,
        onDestinationSelected: (index) {
          if (index < 3) {
            openPage(index);
          } else {
            _showMorePages();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          NavigationDestination(
            icon: Icon(Icons.category_outlined),
            selectedIcon: Icon(Icons.category),
            label: 'Categories',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu),
            selectedIcon: Icon(Icons.menu_open),
            label: 'More',
          ),
        ],
      ),
    );
  }

  String _pageTitle(int index) {
    switch (index) {
      case 0:
        return 'Shopkeeper Dashboard';
      case 1:
        return 'Products';
      case 2:
        return 'Categories';
      case 3:
        return 'Sellers';
      case 4:
        return 'Stock';
      case 5:
        return 'Orders';
      default:
        return 'Inventory';
    }
  }

  void _showMorePages() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.people_outline),
                title: const Text('Sellers'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openPage(3);
                },
              ),
              ListTile(
                leading: const Icon(Icons.price_check_outlined),
                title: const Text('Stock and selling prices'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openPage(4);
                },
              ),
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: const Text('Orders'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openPage(5);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // ------------------------------------------------------------
  // DASHBOARD
  // ------------------------------------------------------------

  Widget _buildDashboard(Shopmodel state) {
    final products = state.actualProduct ?? <Product>[];
    final categories = state.cattegory ?? <ProductCategory>[];
    final sellers = state.saler ?? <Saler>[];
    final orders = state.orders ?? <Ordertrack>[];
    final stocks = state.stock ?? <Stock>[];
    final alerts = state.alert ?? <String>[];

    final lowStockCount = products
        .where(
          (product) =>
              product.warehouseid == widget.warehouseId &&
              product.quantity < ShopkeeperController.lowStockLimit,
        )
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 3
            : 2;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Manage products, sellers, stock and orders.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 18),
            GridView.count(
              crossAxisCount: columns,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: constraints.maxWidth < 360 ? 1.05 : 1.3,
              children: [
                _summaryCard(
                  title: 'Products',
                  count: products.length,
                  icon: Icons.inventory_2_outlined,
                  color: primaryColor,
                  onTap: () => openPage(1),
                ),
                _summaryCard(
                  title: 'Categories',
                  count: categories.length,
                  icon: Icons.category_outlined,
                  color: const Color(0xFF7B61C9),
                  onTap: () => openPage(2),
                ),
                _summaryCard(
                  title: 'Sellers',
                  count: sellers.length,
                  icon: Icons.people_outline,
                  color: const Color(0xFF16856B),
                  onTap: () => openPage(3),
                ),
                _summaryCard(
                  title: 'Orders',
                  count: orders.length,
                  icon: Icons.receipt_long_outlined,
                  color: const Color(0xFFCB7A22),
                  onTap: () => openPage(5),
                ),
                _summaryCard(
                  title: 'Stock items',
                  count: stocks.length,
                  icon: Icons.warehouse_outlined,
                  color: const Color(0xFF526579),
                  onTap: () => openPage(4),
                ),
                _summaryCard(
                  title: 'Low stock',
                  count: lowStockCount,
                  icon: Icons.warning_amber_outlined,
                  color: Colors.redAccent,
                  onTap: () => openPage(1),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Low-stock alerts',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      controller.checkLowStockAlerts(widget.warehouseId),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Check'),
                ),
              ],
            ),
            if (alerts.isEmpty)
              _emptyCard(
                icon: Icons.check_circle_outline,
                message: 'No low-stock alerts.',
              )
            else
              ...alerts.map(
                (alert) => Card(
                  elevation: 0,
                  color: const Color(0xFFFFF4E5),
                  child: ListTile(
                    leading: const Icon(
                      Icons.warning_amber,
                      color: Colors.deepOrange,
                    ),
                    title: Text(alert),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Quick actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _quickAction(
                  icon: Icons.add_box_outlined,
                  label: 'Add product',
                  onTap: () => _showProductDialog(),
                ),
                _quickAction(
                  icon: Icons.create_new_folder_outlined,
                  label: 'Add category',
                  onTap: () => _showCategoryDialog(),
                ),
                _quickAction(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Add seller',
                  onTap: () => _showSellerDialog(),
                ),
                _quickAction(
                  icon: Icons.price_change_outlined,
                  label: 'Add stock',
                  onTap: () => _showStockDialog(),
                ),
                _quickAction(
                  icon: Icons.add_shopping_cart,
                  label: 'Create order',
                  onTap: () => _showOrderDialog(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE8EDF3)),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const Spacer(),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  // ------------------------------------------------------------
  // CATEGORIES
  // ------------------------------------------------------------

  Widget _buildCategories(Shopmodel state) {
    final categories = state.cattegory ?? <ProductCategory>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          title: 'Categories',
          subtitle: '${categories.length} categories',
          buttonText: 'Add category',
          onPressed: () => _showCategoryDialog(),
        ),
        const SizedBox(height: 12),
        if (categories.isEmpty)
          _emptyCard(
            icon: Icons.category_outlined,
            message: 'No categories found. Add your first category.',
          )
        else
          ...categories.map(
            (category) => Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.category, color: primaryColor),
                ),
                title: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('Category ID: ${category.id}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showCategoryDialog(category: category);
                    } else if (value == 'delete') {
                      _confirmDelete(
                        title: 'Delete category?',
                        message: 'Delete "${category.name}"?',
                        onConfirm: () => controller.deleteCategory(
                          category.id,
                          widget.warehouseId,
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showCategoryDialog({ProductCategory? category}) async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: category?.name ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(category == null ? 'Add category' : 'Edit category'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 420,
              maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.55,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: TextFormField(
                  controller: nameController,
                  autofocus: true,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Category name is required'
                      : null,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!(formKey.currentState?.validate() ?? false)) return;

                final name = nameController.text.trim();
                bool success;

                try {
                  if (category == null) {
                    success = controller.createCategory(
                      ProductCategory(
                        name: name,
                        warehouseId: widget.warehouseId,
                      ),
                      widget.warehouseId,
                    );
                  } else {
                    success = controller.updateCategory(
                      id: category.id,
                      warehouseId: widget.warehouseId,
                      name: name,
                    );
                  }
                } catch (error) {
                  _showMessage('Could not save category: $error');
                  return;
                }

                if (!success) {
                  _showMessage(
                    'Category could not be saved. '
                    'Check whether it already exists.',
                  );
                  return;
                }

                Navigator.pop(dialogContext, true);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    _disposeLater([nameController]);

    if (result == true && mounted) {
      refreshData();
      _showMessage(
        category == null
            ? 'Category added successfully.'
            : 'Category updated successfully.',
      );
    }
  }

  // ------------------------------------------------------------
  // PRODUCTS
  // ------------------------------------------------------------

  Widget _buildProducts(Shopmodel state) {
    final products = state.filteredProduct ?? <Product>[];
    final categories = state.cattegory ?? <ProductCategory>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          title: 'Products',
          subtitle: '${products.length} products',
          buttonText: 'Add product',
          onPressed: () => _showProductDialog(),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          onChanged: (value) =>
              controller.searchProduct(value, widget.warehouseId),
          decoration: InputDecoration(
            hintText: 'Search products...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Clear search',
              onPressed: () {
                searchController.clear();
                controller.clearProductSearch(widget.warehouseId);
              },
              icon: const Icon(Icons.clear),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        if (products.isEmpty)
          _emptyCard(
            icon: Icons.inventory_2_outlined,
            message: 'No products found.',
          )
        else
          ...products.map((product) {
            final category = _categoryById(categories, product.categoryId);

            return Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                isThreeLine: true,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEAF2FF),
                  child: Icon(Icons.inventory_2_outlined, color: primaryColor),
                ),
                title: Text(
                  product.productname,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Category: ${category?.name ?? 'Unknown'}\n'
                  'Quantity: ${product.quantity}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showProductDialog(product: product);
                    } else if (value == 'order') {
                      _showOrderDialog(initialProduct: product);
                    } else if (value == 'delete') {
                      _confirmDelete(
                        title: 'Delete product?',
                        message: 'Delete "${product.productname}"?',
                        onConfirm: () => controller.deleteProduct(
                          product.id,
                          widget.warehouseId,
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'order', child: Text('Create order')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showProductDialog({Product? product}) async {
    final formKey = GlobalKey<FormState>();
    final state = ref.read(shopprovider);
    final categories = state.cattegory ?? <ProductCategory>[];

    final nameController = TextEditingController(
      text: product?.productname ?? '',
    );
    final quantityController = TextEditingController(
      text: product?.quantity.toString() ?? '0',
    );

    int? selectedCategoryId =
        categories.any((category) => category.id == product?.categoryId)
        ? product!.categoryId
        : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(product == null ? 'Add product' : 'Edit product'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Product name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Product name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedCategoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: categories
                              .map(
                                (category) => DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(
                                    category.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategoryId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select a category' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final quantity = int.tryParse(value ?? '');
                            if (quantity == null || quantity < 0) {
                              return 'Enter a valid non-negative quantity';
                            }
                            return null;
                          },
                        ),
                        if (categories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Create a category before adding a product.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: categories.isEmpty
                      ? null
                      : () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          final name = nameController.text.trim();
                          final quantity = int.tryParse(
                            quantityController.text.trim(),
                          );

                          if (quantity == null || selectedCategoryId == null) {
                            return;
                          }

                          final bool success;

                          try {
                            if (product == null) {
                              success = controller.createProduct(
                                Product(
                                  productname: name,
                                  categoryId: selectedCategoryId!,
                                  warehouseid: widget.warehouseId,
                                  quantity: quantity,
                                ),
                                widget.warehouseId,
                              );
                            } else {
                              success = controller.updateProduct(
                                id: product.id,
                                warehouseId: widget.warehouseId,
                                productname: name,
                                categoryId: selectedCategoryId!,
                                quantity: quantity,
                              );
                            }
                          } catch (error) {
                            _showMessage('Could not save product: $error');
                            return;
                          }

                          if (!success) {
                            _showMessage('Product could not be saved.');
                            return;
                          }

                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeLater([nameController, quantityController]);

    if (result == true && mounted) {
      refreshData();
      _showMessage(
        product == null
            ? 'Product added successfully.'
            : 'Product updated successfully.',
      );
    }
  }

  // ------------------------------------------------------------
  // SELLERS
  // ------------------------------------------------------------

  Widget _buildSellers(Shopmodel state) {
    final sellers = state.saler ?? <Saler>[];
    final categories = state.cattegory ?? <ProductCategory>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          title: 'Sellers',
          subtitle: '${sellers.length} sellers',
          buttonText: 'Add seller',
          onPressed: () => _showSellerDialog(),
        ),
        const SizedBox(height: 12),
        if (sellers.isEmpty)
          _emptyCard(icon: Icons.people_outline, message: 'No sellers found.')
        else
          ...sellers.map((seller) {
            final category = _categoryById(categories, seller.categoryId);

            return Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                isThreeLine: true,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFE8F7F0),
                  child: Icon(Icons.person_outline, color: Colors.green),
                ),
                title: Text(
                  seller.salerName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Contact: ${seller.salerContact}\n'
                  'Category: ${category?.name ?? 'Unknown'}',
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showSellerDialog(seller: seller);
                    } else if (value == 'delete') {
                      _confirmDelete(
                        title: 'Delete seller?',
                        message: 'Delete "${seller.salerName}"?',
                        onConfirm: () => controller.deleteSaler(
                          seller.id,
                          widget.warehouseId,
                        ),
                      );
                    }
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showSellerDialog({Saler? seller}) async {
    final formKey = GlobalKey<FormState>();
    final categories = ref.read(shopprovider).cattegory ?? <ProductCategory>[];

    final nameController = TextEditingController(text: seller?.salerName ?? '');
    final contactController = TextEditingController(
      text: seller?.salerContact ?? '',
    );
    final remarksController = TextEditingController(
      text: seller?.remarks ?? '',
    );

    int? selectedCategoryId =
        categories.any((category) => category.id == seller?.categoryId)
        ? seller!.categoryId
        : null;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(seller == null ? 'Add seller' : 'Edit seller'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Seller name',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Seller name is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: contactController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Contact',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Contact is required'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<int>(
                          initialValue: selectedCategoryId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(),
                          ),
                          items: categories
                              .map(
                                (category) => DropdownMenuItem<int>(
                                  value: category.id,
                                  child: Text(
                                    category.name,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedCategoryId = value;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select a category' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: remarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (categories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Create a category before adding a seller.',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: categories.isEmpty
                      ? null
                      : () {
                          if (!(formKey.currentState?.validate() ?? false)) {
                            return;
                          }

                          if (selectedCategoryId == null) return;

                          final bool success;

                          try {
                            if (seller == null) {
                              success = controller.createSaler(
                                Saler(
                                  salerName: nameController.text.trim(),
                                  salerContact: contactController.text.trim(),
                                  remarks: remarksController.text.trim(),
                                  categoryId: selectedCategoryId!,
                                  warehouseId: widget.warehouseId,
                                ),
                                widget.warehouseId,
                              );
                            } else {
                              success = controller.updateSaler(
                                id: seller.id,
                                warehouseId: widget.warehouseId,
                                salerName: nameController.text.trim(),
                                salerContact: contactController.text.trim(),
                                remarks: remarksController.text.trim(),
                                categoryId: selectedCategoryId!,
                              );
                            }
                          } catch (error) {
                            _showMessage('Could not save seller: $error');
                            return;
                          }

                          if (!success) {
                            _showMessage('Seller could not be saved.');
                            return;
                          }

                          Navigator.pop(dialogContext, true);
                        },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeLater([nameController, contactController, remarksController]);

    if (result == true && mounted) {
      refreshData();
      _showMessage(
        seller == null
            ? 'Seller added successfully.'
            : 'Seller updated successfully.',
      );
    }
  }

  // ------------------------------------------------------------
  // STOCK
  // ------------------------------------------------------------

  Widget _buildStock(Shopmodel state) {
    final stocks = state.stock ?? <Stock>[];
    final products = state.actualProduct ?? <Product>[];
    final categories = state.cattegory ?? <ProductCategory>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          title: 'Stock',
          subtitle: '${stocks.length} stock records',
          buttonText: 'Add stock',
          onPressed: () => _showStockDialog(),
        ),
        const SizedBox(height: 12),
        if (stocks.isEmpty)
          _emptyCard(
            icon: Icons.warehouse_outlined,
            message:
                'No stock records found. Tap "Add stock" to set a '
                'selling price for a product.',
          )
        else
          ...stocks.map((stock) {
            final product = _productById(products, stock.productId);
            final category = _categoryById(categories, stock.categoryId);

            return Card(
              elevation: 0,
              color: Colors.white,
              child: ListTile(
                isThreeLine: true,
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFFFF3E5),
                  child: Icon(
                    Icons.price_check_outlined,
                    color: Colors.deepOrange,
                  ),
                ),
                title: Text(
                  product?.productname ?? 'Unknown product',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Category: ${category?.name ?? 'Unknown'}\n'
                  'Quantity: ${product?.quantity.toString() ?? 'N/A'}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 70),
                      child: Text(
                        'Price\n${stock.sellingPrice}',
                        textAlign: TextAlign.end,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _showStockDialog(stock: stock);
                        } else if (value == 'delete') {
                          _confirmDelete(
                            title: 'Delete stock record?',
                            message:
                                'Delete the selling price record for '
                                '"${product?.productname ?? 'this product'}"?',
                            onConfirm: () => controller.deleteStock(
                              stock.id,
                              widget.warehouseId,
                            ),
                          );
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  /// Add or edit a stock (selling price) record.
  ///
  /// Add  : choose a product that has no stock record yet + enter a price.
  ///        The category is taken automatically from the product.
  /// Edit : product is locked, only the selling price can be changed.
  Future<void> _showStockDialog({Stock? stock}) async {
    final state = ref.read(shopprovider);
    final products = state.actualProduct ?? <Product>[];
    final stocks = state.stock ?? <Stock>[];
    final categories = state.cattegory ?? <ProductCategory>[];

    final bool isEdit = stock != null;

    if (products.isEmpty) {
      _showMessage('Add a product before adding stock.');
      return;
    }

    // When adding, only offer products that do not have a record yet.
    final List<Product> availableProducts = isEdit
        ? products.where((p) => p.id == stock.productId).toList()
        : products
              .where((p) => !stocks.any((s) => s.productId == p.id))
              .toList();

    if (availableProducts.isEmpty) {
      _showMessage(
        isEdit
            ? 'The product for this stock record could not be found.'
            : 'Every product already has a selling price. '
                  'Edit an existing stock record instead.',
      );
      return;
    }

    final formKey = GlobalKey<FormState>();
    final priceController = TextEditingController(
      text: isEdit ? stock.sellingPrice.toInt().toString() : '',
    );

    int? selectedProductId = isEdit
        ? stock.productId
        : (availableProducts.length == 1 ? availableProducts.first.id : null);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Product? selectedProduct;

            for (final p in availableProducts) {
              if (p.id == selectedProductId) {
                selectedProduct = p;
                break;
              }
            }

            final ProductCategory? selectedCategory = selectedProduct == null
                ? null
                : _categoryById(categories, selectedProduct.categoryId);

            return AlertDialog(
              title: Text(isEdit ? 'Edit stock price' : 'Add stock'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: selectedProductId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Product',
                            border: OutlineInputBorder(),
                          ),
                          items: availableProducts
                              .map(
                                (p) => DropdownMenuItem<int>(
                                  value: p.id,
                                  child: Text(
                                    '${p.productname} (${p.quantity})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: isEdit
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedProductId = value;
                                  });
                                },
                          validator: (value) =>
                              value == null ? 'Select a product' : null,
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedProduct == null
                                ? 'Category: select a product first'
                                : 'Category: '
                                      '${selectedCategory?.name ?? 'Unknown'}',
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: priceController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Selling price',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final price = int.tryParse((value ?? '').trim());

                            if (price == null || price <= 0) {
                              return 'Enter a selling price greater than zero';
                            }

                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    if (selectedProduct == null) return;

                    final int? price = int.tryParse(
                      priceController.text.trim(),
                    );

                    if (price == null || price <= 0) return;

                    final bool success;

                    try {
                      if (isEdit) {
                        success = controller.updateStock(
                          id: stock.id,
                          warehouseId: widget.warehouseId,
                          categoryId: selectedProduct.categoryId,
                          productId: selectedProduct.id,
                          sellingPrice: price,
                        );
                      } else {
                        final String? branchCode = controller
                            .getBranchCodeForWarehouse(widget.warehouseId);

                        if (branchCode == null || branchCode.trim().isEmpty) {
                          _showMessage(
                            'This warehouse has no branch code. '
                            'Please contact the administrator.',
                          );
                          return;
                        }

                        success = controller.createStock(
                          Stock(
                            categoryId: selectedProduct.categoryId,
                            productId: selectedProduct.id,
                            sellingPrice: price,
                            warehouseId: widget.warehouseId,
                            branchCode: branchCode,
                          ),
                          widget.warehouseId,
                        );
                      }
                    } catch (error) {
                      _showMessage('Could not save stock: $error');
                      return;
                    }

                    if (!success) {
                      _showMessage(
                        'Stock could not be saved. Check the product, '
                        'category and warehouse branch code.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: Text(isEdit ? 'Save' : 'Add'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeLater([priceController]);

    if (result == true && mounted) {
      refreshData();
      _showMessage(
        isEdit ? 'Stock updated successfully.' : 'Stock added successfully.',
      );
    }
  }

  // ------------------------------------------------------------
  // ORDERS
  // ------------------------------------------------------------

  Widget _buildOrders(Shopmodel state) {
    final orders = state.orders ?? <Ordertrack>[];
    final products = state.actualProduct ?? <Product>[];
    final sellers = state.saler ?? <Saler>[];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionHeader(
          title: 'Orders',
          subtitle: '${orders.length} orders',
          buttonText: 'Create order',
          onPressed: () => _showOrderDialog(),
        ),
        const SizedBox(height: 12),
        if (orders.isEmpty)
          _emptyCard(
            icon: Icons.receipt_long_outlined,
            message: 'No orders found.',
          )
        else
          ...orders.map((order) {
            final product = _productById(products, order.productid);
            final seller = _sellerById(sellers, order.selerid);

            final status = order.fullfilled
                ? 'Completed'
                : order.partially_completed
                ? 'Partially completed'
                : 'Pending';

            final statusColor = order.fullfilled
                ? const Color(0xFFE5F7ED)
                : order.partially_completed
                ? const Color(0xFFFFF3D6)
                : const Color(0xFFEAF2FF);

            return Card(
              elevation: 0,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product?.productname ?? 'Unknown product',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          enabled: !order.fullfilled,
                          onSelected: (value) {
                            if (value == 'edit') {
                              _showOrderEditDialog(order: order);
                            } else if (value == 'delete') {
                              _confirmDelete(
                                title: 'Delete order?',
                                message: 'Delete order ${order.id}?',
                                onConfirm: () => controller.deleteOrder(
                                  order.id,
                                  widget.warehouseId,
                                ),
                              );
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('Seller: ${seller?.salerName ?? 'Unknown'}'),
                    Text('Quantity: ${order.quantity}'),
                    Text('Total: ${order.totalprice}'),
                    if (order.descriptive_remark.trim().isNotEmpty)
                      Text('Remarks: ${order.descriptive_remark}'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(status, style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _showOrderDialog({Product? initialProduct}) async {
    final state = ref.read(shopprovider);
    final products = state.actualProduct ?? <Product>[];
    final sellers = state.saler ?? <Saler>[];
    final List<Stock> stocks = state.stock ?? <Stock>[];

    if (products.isEmpty || sellers.isEmpty) {
      _showMessage('Add a product and a seller before creating an order.');
      return;
    }

    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController(text: '1');
    final remarksController = TextEditingController();

    int? selectedProductId =
        products.any((product) => product.id == initialProduct?.id)
        ? initialProduct!.id
        : null;

    int? selectedSellerId;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Product? selectedProduct;

            for (final product in products) {
              if (product.id == selectedProductId) {
                selectedProduct = product;
                break;
              }
            }

            final eligibleSellers = selectedProduct == null
                ? <Saler>[]
                : sellers
                      .where(
                        (seller) =>
                            seller.categoryId == selectedProduct!.categoryId,
                      )
                      .toList();

            if (!eligibleSellers.any(
              (seller) => seller.id == selectedSellerId,
            )) {
              selectedSellerId = null;
            }

            Stock? selectedStock;

            if (selectedProduct != null) {
              for (final stock in stocks) {
                if (stock.productId == selectedProduct!.id) {
                  selectedStock = stock;
                  break;
                }
              }
            }

            final int quantity =
                int.tryParse(quantityController.text.trim()) ?? 0;

            // Ordertrack.totalprice is int, so convert the price to int.
            final int price = (selectedStock?.sellingPrice ?? 0).toInt();
            final int total = quantity * price;

            return AlertDialog(
              title: const Text('Create order'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: selectedProductId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Product',
                            border: OutlineInputBorder(),
                          ),
                          items: products
                              .map(
                                (product) => DropdownMenuItem<int>(
                                  value: product.id,
                                  child: Text(
                                    '${product.productname} '
                                    '(${product.quantity})',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setDialogState(() {
                              selectedProductId = value;
                              selectedSellerId = null;
                            });
                          },
                          validator: (value) =>
                              value == null ? 'Select a product' : null,
                        ),
                        const SizedBox(height: 12),
                        // The key forces this dropdown to rebuild with a fresh
                        // internal value whenever the product changes.
                        DropdownButtonFormField<int>(
                          key: ValueKey('seller_for_$selectedProductId'),
                          initialValue: selectedSellerId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Seller',
                            border: OutlineInputBorder(),
                          ),
                          items: eligibleSellers
                              .map(
                                (seller) => DropdownMenuItem<int>(
                                  value: seller.id,
                                  child: Text(
                                    seller.salerName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: eligibleSellers.isEmpty
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedSellerId = value;
                                  });
                                },
                          validator: (value) =>
                              value == null ? 'Select a seller' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                          validator: (value) {
                            final q = int.tryParse(value ?? '');

                            if (q == null || q <= 0) {
                              return 'Quantity must be greater than zero';
                            }

                            if (selectedProduct != null &&
                                q > selectedProduct!.quantity) {
                              return 'Quantity exceeds available stock';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: remarksController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            selectedStock == null
                                ? 'No selling-price record found'
                                : 'Selling price: $price\nTotal: $total',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    if (selectedProduct == null || selectedSellerId == null) {
                      return;
                    }

                    if (selectedStock == null) {
                      _showMessage(
                        'Add a stock record and selling price first.',
                      );
                      return;
                    }

                    final int orderQuantity = int.parse(
                      quantityController.text.trim(),
                    );

                    final int orderTotal = orderQuantity * price;

                    final success = controller.createOrder(
                      Ordertrack(
                        selerid: selectedSellerId!,
                        warehouseid: widget.warehouseId,
                        productid: selectedProduct!.id,
                        quantity: orderQuantity,
                        totalprice: orderTotal,
                        descriptive_remark: remarksController.text.trim(),
                        fullfilled: false,
                        partially_completed: false,
                      ),
                      widget.warehouseId,
                    );

                    if (!success) {
                      _showMessage(
                        'Order could not be created. Check the product, '
                        'seller and category.',
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Create'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeLater([quantityController, remarksController]);

    if (result == true && mounted) {
      refreshData();
      _showMessage('Order created successfully.');
    }
  }

  Future<void> _showOrderEditDialog({required Ordertrack order}) async {
    final formKey = GlobalKey<FormState>();

    final quantityController = TextEditingController(
      text: order.quantity.toString(),
    );
    final totalController = TextEditingController(
      text: order.totalprice.toString(),
    );
    final remarksController = TextEditingController(
      text: order.descriptive_remark,
    );

    bool partiallyCompleted = order.partially_completed;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit order'),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 420,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.58,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: quantityController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Quantity',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final quantity = int.tryParse(value ?? '');

                            return quantity == null || quantity <= 0
                                ? 'Enter a valid quantity'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: totalController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Total price',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            final total = int.tryParse(value ?? '');

                            return total == null || total < 0
                                ? 'Enter a valid total price'
                                : null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: remarksController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Remarks',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: partiallyCompleted,
                          title: const Text('Partially completed'),
                          onChanged: (value) {
                            setDialogState(() {
                              partiallyCompleted = value ?? false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }

                    final success = controller.updateOrder(
                      id: order.id,
                      warehouseId: widget.warehouseId,
                      quantity: int.parse(quantityController.text.trim()),
                      totalprice: int.parse(totalController.text.trim()),
                      descriptive_remark: remarksController.text.trim(),
                      partially_completed: partiallyCompleted,
                    );

                    if (!success) {
                      _showMessage('Order could not be updated.');
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    _disposeLater([quantityController, totalController, remarksController]);

    if (result == true && mounted) {
      refreshData();
      _showMessage('Order updated successfully.');
    }
  }

  // ------------------------------------------------------------
  // SHARED WIDGETS AND HELPERS
  // ------------------------------------------------------------

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black54)),
          ],
        ),
        FilledButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, size: 18),
          label: Text(buttonText),
        ),
      ],
    );
  }

  Widget _emptyCard({required IconData icon, required String message}) {
    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(icon, size: 42, color: Colors.black38),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  ProductCategory? _categoryById(List<ProductCategory> categories, int id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Product? _productById(List<Product> products, int id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  Saler? _sellerById(List<Saler> sellers, int id) {
    for (final seller in sellers) {
      if (seller.id == id) return seller;
    }
    return null;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirmDelete({
    required String title,
    required String message,
    required bool Function() onConfirm,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(child: Text(message)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      final success = onConfirm();

      if (!mounted) return;

      if (success) {
        refreshData();
        _showMessage('Deleted successfully.');
      } else {
        _showMessage(
          'Could not delete this record. '
          'It may be used by another record.',
        );
      }
    } catch (error) {
      _showMessage('Delete failed: $error');
    }
  }
}
