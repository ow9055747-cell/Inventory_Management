import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inventory/controller/SuperadminController.dart';

import 'package:inventory/model/warehouse.dart';
import 'package:inventory/provider/superAdminProvider.dart';

class WarehouseManagementScreen extends ConsumerStatefulWidget {
  const WarehouseManagementScreen({super.key});

  @override
  ConsumerState<WarehouseManagementScreen> createState() =>
      _WarehouseManagementScreenState();
}

class _WarehouseManagementScreenState
    extends ConsumerState<WarehouseManagementScreen> {
  final TextEditingController searchController = TextEditingController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        ref.read(superprovider.notifier).syncData();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Warehouse> filterWarehouses(List<Warehouse> warehouses) {
    final query = searchQuery.trim().toLowerCase();

    if (query.isEmpty) {
      return warehouses;
    }

    return warehouses.where((warehouse) {
      return warehouse.name.toLowerCase().contains(query);
    }).toList();
  }

  Future<void> showWarehouseForm({Warehouse? warehouse}) async {
    final result = await showDialog<_WarehouseFormResult>(
      context: context,
      builder: (_) => _WarehouseFormDialog(warehouse: warehouse),
    );

    if (!mounted || result == null) return;

    final controller = ref.read(superprovider.notifier);

    if (warehouse == null) {
      final success = controller.addWarehouse(
        Warehouse(
          mainBranch: result.mainBranch,
          name: result.name,
          branchCode: result.branchCode,
          address: result.address,
        ),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Warehouse added successfully'
                : 'Warehouse name is empty or already exists',
          ),
        ),
      );
    } else {
      final success = controller.updateWarehouse(
        id: warehouse.id,
        mainBranch: result.mainBranch,
        name: result.name,
        branchCode: result.branchCode,
        address: result.address,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Warehouse updated successfully'
                : 'Update failed. Check the name or warehouse details.',
          ),
        ),
      );
    }
  }

  Future<void> confirmDelete(Warehouse warehouse) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Warehouse?'),
        content: Text('Are you sure you want to delete "${warehouse.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    final success = ref
        .read(superprovider.notifier)
        .deleteWarehouse(warehouse.id);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Warehouse deleted successfully'
              : 'Unable to delete warehouse',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warehouseState = ref.watch(superprovider);
    final warehouses = filterWarehouses(warehouseState.actual);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Warehouse Management'),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showWarehouseForm(),
        icon: const Icon(Icons.add),
        label: const Text('Add Warehouse'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search warehouse by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.warehouse_outlined),
                const SizedBox(width: 8),
                Text(
                  'Warehouses (${warehouses.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: warehouses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warehouse_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          searchQuery.isEmpty
                              ? 'No warehouses found'
                              : 'No matching warehouses',
                        ),
                        const SizedBox(height: 8),
                        if (searchQuery.isEmpty)
                          OutlinedButton.icon(
                            onPressed: () => showWarehouseForm(),
                            icon: const Icon(Icons.add),
                            label: const Text('Create Warehouse'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: warehouses.length,
                    itemBuilder: (context, index) {
                      final warehouse = warehouses[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: warehouse.mainBranch
                                        ? Colors.orange.shade100
                                        : Colors.blue.shade100,
                                    child: Icon(
                                      warehouse.mainBranch
                                          ? Icons.business
                                          : Icons.warehouse,
                                      color: warehouse.mainBranch
                                          ? Colors.deepOrange
                                          : Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          warehouse.name,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 9,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: warehouse.mainBranch
                                                ? Colors.orange.shade100
                                                : Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            warehouse.mainBranch
                                                ? 'Main Branch'
                                                : 'Regular Branch',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: warehouse.mainBranch
                                                  ? Colors.deepOrange
                                                  : Colors.blue.shade800,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        showWarehouseForm(warehouse: warehouse);
                                      } else if (value == 'delete') {
                                        confirmDelete(warehouse);
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit_outlined),
                                            SizedBox(width: 10),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                            ),
                                            SizedBox(width: 10),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),

                              const Divider(height: 24),

                              _WarehouseDetailRow(
                                icon: Icons.tag,
                                label: 'Warehouse ID',
                                value: warehouse.id.toString(),
                              ),
                              _WarehouseDetailRow(
                                icon: Icons.qr_code,
                                label: 'Branch Code',
                                value: warehouse.branchCode,
                              ),
                              _WarehouseDetailRow(
                                icon: Icons.location_on_outlined,
                                label: 'Address',
                                value: warehouse.address,
                              ),

                              const SizedBox(height: 8),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton.icon(
                                    onPressed: () =>
                                        showWarehouseForm(warehouse: warehouse),
                                    icon: const Icon(Icons.edit_outlined),
                                    label: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  TextButton.icon(
                                    onPressed: () => confirmDelete(warehouse),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    icon: const Icon(Icons.delete_outline),
                                    label: const Text('Delete'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// Displays an individual warehouse detail.
class _WarehouseDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _WarehouseDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: Colors.grey.shade700),
          const SizedBox(width: 10),
          SizedBox(
            width: 105,
            child: Text(label, style: TextStyle(color: Colors.grey.shade700)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

// The dialog owns its controllers, so they are disposed at the right time.
class _WarehouseFormDialog extends StatefulWidget {
  final Warehouse? warehouse;

  const _WarehouseFormDialog({this.warehouse});

  @override
  State<_WarehouseFormDialog> createState() => _WarehouseFormDialogState();
}

class _WarehouseFormDialogState extends State<_WarehouseFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController branchCodeController;
  late final TextEditingController addressController;

  late bool mainBranch;

  @override
  void initState() {
    super.initState();

    final warehouse = widget.warehouse;

    nameController = TextEditingController(text: warehouse?.name ?? '');
    branchCodeController = TextEditingController(
      text: warehouse?.branchCode ?? '',
    );
    addressController = TextEditingController(text: warehouse?.address ?? '');

    mainBranch = warehouse?.mainBranch ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    branchCodeController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _WarehouseFormResult(
        name: nameController.text.trim(),
        branchCode: branchCodeController.text.trim(),
        address: addressController.text.trim(),
        mainBranch: mainBranch,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.warehouse != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Warehouse' : 'Add Warehouse'),
      content: SingleChildScrollView(
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Warehouse Name',
                  prefixIcon: Icon(Icons.warehouse_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter warehouse name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: branchCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Branch Code',
                  prefixIcon: Icon(Icons.qr_code),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter branch code';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: addressController,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter warehouse address';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Main Branch'),
                subtitle: const Text('Mark this warehouse as the main branch'),
                value: mainBranch,
                onChanged: (value) {
                  setState(() {
                    mainBranch = value;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: submit,
          icon: Icon(isEditing ? Icons.save : Icons.add),
          label: Text(isEditing ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}

class _WarehouseFormResult {
  final String name;
  final String branchCode;
  final String address;
  final bool mainBranch;

  const _WarehouseFormResult({
    required this.name,
    required this.branchCode,
    required this.address,
    required this.mainBranch,
  });
}
