import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:inventory/controller/SuperadminController.dart';
import 'package:inventory/model/usermodel.dart';
import 'package:inventory/model/warehouse.dart';
import 'package:inventory/provider/superAdminProvider.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final searchController = TextEditingController();

  String searchQuery = '';
  String selectedRoleFilter = 'all';

  final List<String> roles = ['admin', 'shopkeeper'];

  String normalizeRole(String role) =>
      role.trim().toLowerCase().replaceAll('_', '').replaceAll(' ', '');

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

  List<UserModel> filterUsers(List<UserModel> users) {
    final query = searchQuery.trim().toLowerCase();

    return users.where((user) {
      final matchesSearch =
          user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);

      final matchesRole =
          selectedRoleFilter == 'all' ||
          normalizeRole(user.role) == normalizeRole(selectedRoleFilter);

      return matchesSearch && matchesRole;
    }).toList();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> showUserForm({UserModel? user}) async {
    final editing = user != null;
    final controller = ref.read(superprovider.notifier);

    // Get the current warehouse list from ObjectBox.
    final warehouses = controller.getAllWarehouses();

    final result = await showDialog<_UserFormResult>(
      context: context,
      builder: (_) => _UserFormDialog(
        user: user,
        warehouses: warehouses,
        roles: roles,
        normalizeRole: normalizeRole,
      ),
    );

    if (result == null || !mounted) return;

    final email = result.email.trim().toLowerCase();
    final name = result.name.trim();
    final passcode = result.passcode.trim();
    final isAdmin = result.role == 'admin';

    final String? branchCode = isAdmin
        ? result.branchCode.trim().toUpperCase()
        : null;

    final int? warehouseId = isAdmin ? null : result.warehouseId;

    if (!editing) {
      if (controller.emailExists(email)) {
        showMessage('This email is already registered.');
        return;
      }

      try {
        controller.addUser(
          UserModel(
            name: name,
            email: email,
            warehouseId: warehouseId,
            role: result.role,
            passcode: passcode,
            branchCode: branchCode,
          ),
        );

        // addUser refreshes controller state after saving.
        showMessage('User created successfully.');
      } catch (e) {
        showMessage('Could not create user: $e');
      }

      return;
    }

    try {
      final success = controller.updateUser(
        email: user.email,
        name: name,
        warehouseId: warehouseId,
        role: result.role,
        passcode: passcode,
        branchCode: branchCode,
      );

      showMessage(
        success
            ? 'User updated successfully.'
            : 'Failed to update user. Check the email and database.',
      );
    } catch (e) {
      showMessage('Could not update user: $e');
    }
  }

  Future<void> confirmDelete(UserModel user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete ${user.name}?'),
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

    if (confirmed != true || !mounted) return;

    try {
      final success = ref.read(superprovider.notifier).deleteUser(user.email);

      showMessage(
        success ? 'User deleted successfully.' : 'Failed to delete user.',
      );
    } catch (e) {
      showMessage('Could not delete user: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // This subscription causes the screen to rebuild when state changes.
    final state = ref.watch(superprovider);

    // Use the complete user list, not the controller's filtered list.
    final users = filterUsers(state.adminsac);
    final warehouses = state.actual;

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showUserForm(),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add User'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() => searchQuery = value);
                },
                decoration: InputDecoration(
                  hintText: 'Search users by name or email',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            searchController.clear();
                            setState(() => searchQuery = '');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.filter_list),
                  const SizedBox(width: 10),
                  const Text('Role'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedRoleFilter,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: 'all',
                          child: Text('All roles'),
                        ),
                        ...roles.map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role[0].toUpperCase() + role.substring(1),
                            ),
                          ),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => selectedRoleFilter = value);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text('Users', style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  Text('${users.length} found'),
                ],
              ),
            ),

            Expanded(
              child: users.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline, size: 56),
                          SizedBox(height: 12),
                          Text('No users found'),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                      itemCount: users.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];

                        Warehouse? warehouse;
                        for (final item in warehouses) {
                          if (item.id == user.warehouseId) {
                            warehouse = item;
                            break;
                          }
                        }

                        final isAdmin = normalizeRole(user.role) == 'admin';

                        return Card(
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              child: Text(
                                user.name.isEmpty
                                    ? '?'
                                    : user.name[0].toUpperCase(),
                              ),
                            ),
                            title: Text(
                              user.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(user.email),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      Chip(
                                        label: Text(user.role),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      if (isAdmin)
                                        Chip(
                                          avatar: const Icon(
                                            Icons.qr_code,
                                            size: 16,
                                          ),
                                          label: Text(
                                            'Branch: ${user.branchCode ?? "Not assigned"}',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        )
                                      else
                                        Chip(
                                          avatar: const Icon(
                                            Icons.warehouse_outlined,
                                            size: 16,
                                          ),
                                          label: Text(
                                            warehouse == null
                                                ? 'Warehouse not assigned'
                                                : '${warehouse.name} (ID: ${warehouse.id})',
                                          ),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            trailing: PopupMenuButton<String>(
                              tooltip: 'User actions',
                              onSelected: (action) {
                                if (action == 'edit') {
                                  showUserForm(user: user);
                                } else if (action == 'delete') {
                                  confirmDelete(user);
                                }
                              },
                              itemBuilder: (context) => const [
                                PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: ListTile(
                                    leading: Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                    ),
                                    title: Text('Delete'),
                                    contentPadding: EdgeInsets.zero,
                                  ),
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
      ),
    );
  }
}

class _UserFormResult {
  final String name;
  final String email;
  final String passcode;
  final String role;
  final String branchCode;
  final int? warehouseId;

  const _UserFormResult({
    required this.name,
    required this.email,
    required this.passcode,
    required this.role,
    required this.branchCode,
    required this.warehouseId,
  });
}

class _UserFormDialog extends StatefulWidget {
  final UserModel? user;
  final List<Warehouse> warehouses;
  final List<String> roles;
  final String Function(String) normalizeRole;

  const _UserFormDialog({
    required this.user,
    required this.warehouses,
    required this.roles,
    required this.normalizeRole,
  });

  @override
  State<_UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends State<_UserFormDialog> {
  final formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;
  late final TextEditingController emailController;
  late final TextEditingController passcodeController;
  late final TextEditingController branchCodeController;
  late final TextEditingController warehouseSearchController;

  late String selectedRole;
  int? selectedWarehouseId;
  bool obscurePasscode = true;

  bool get isEditing => widget.user != null;
  bool get isAdmin => selectedRole == 'admin';

  @override
  void initState() {
    super.initState();

    final user = widget.user;

    nameController = TextEditingController(text: user?.name ?? '');
    emailController = TextEditingController(text: user?.email ?? '');
    passcodeController = TextEditingController(text: user?.passcode ?? '');
    branchCodeController = TextEditingController(text: user?.branchCode ?? '');
    warehouseSearchController = TextEditingController();

    selectedRole = widget.normalizeRole(user?.role ?? 'admin');

    if (!widget.roles.contains(selectedRole)) {
      selectedRole = 'admin';
    }

    selectedWarehouseId = user?.warehouseId;

    for (final warehouse in widget.warehouses) {
      if (warehouse.id == selectedWarehouseId) {
        warehouseSearchController.text = warehouse.name;
        break;
      }
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passcodeController.dispose();
    branchCodeController.dispose();
    warehouseSearchController.dispose();
    super.dispose();
  }

  void submit() {
    if (!formKey.currentState!.validate()) return;

    Navigator.of(context).pop(
      _UserFormResult(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        passcode: passcodeController.text.trim(),
        role: selectedRole,
        branchCode: branchCodeController.text.trim(),
        warehouseId: isAdmin ? null : selectedWarehouseId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = warehouseSearchController.text.trim().toLowerCase();

    final matchingWarehouses = query.isEmpty
        ? <Warehouse>[]
        : widget.warehouses.where((warehouse) {
            return warehouse.name.toLowerCase().contains(query);
          }).toList();

    Warehouse? selectedWarehouse;
    for (final warehouse in widget.warehouses) {
      if (warehouse.id == selectedWarehouseId) {
        selectedWarehouse = warehouse;
        break;
      }
    }

    return AlertDialog(
      title: Text(isEditing ? 'Edit User' : 'Create User'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    prefixIcon: Icon(Icons.person_outline),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter the user name'
                      : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: emailController,
                  readOnly: isEditing,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)
                        ? null
                        : 'Enter a valid email';
                  },
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: passcodeController,
                  obscureText: obscurePasscode,
                  decoration: InputDecoration(
                    labelText: 'Passcode',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          obscurePasscode = !obscurePasscode;
                        });
                      },
                      icon: Icon(
                        obscurePasscode
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a passcode'
                      : null,
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'User role',
                    prefixIcon: Icon(Icons.admin_panel_settings_outlined),
                    border: OutlineInputBorder(),
                  ),
                  items: widget.roles.map((role) {
                    return DropdownMenuItem(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;

                    setState(() {
                      selectedRole = value;
                      selectedWarehouseId = null;
                      warehouseSearchController.clear();
                      branchCodeController.clear();
                    });
                  },
                ),
                const SizedBox(height: 22),

                if (isAdmin)
                  TextFormField(
                    controller: branchCodeController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Branch code',
                      hintText: 'Enter branch code',
                      prefixIcon: Icon(Icons.qr_code),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a branch code'
                        : null,
                  ),

                if (!isAdmin) ...[
                  Text(
                    'Assign Warehouse',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),

                  TextFormField(
                    controller: warehouseSearchController,
                    decoration: InputDecoration(
                      labelText: 'Search warehouse by name',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Clear warehouse',
                        onPressed: () {
                          setState(() {
                            warehouseSearchController.clear();
                            selectedWarehouseId = null;
                          });
                        },
                        icon: const Icon(Icons.clear),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        selectedWarehouseId = null;
                      });
                    },
                    validator: (_) {
                      if (selectedWarehouseId == null) {
                        return 'Search and select a warehouse';
                      }

                      final exists = widget.warehouses.any(
                        (w) => w.id == selectedWarehouseId,
                      );

                      return exists ? null : 'Select an existing warehouse';
                    },
                  ),
                  const SizedBox(height: 10),

                  if (widget.warehouses.isEmpty)
                    const Text(
                      'Create a warehouse before assigning a shopkeeper.',
                    ),

                  if (query.isNotEmpty && matchingWarehouses.isEmpty)
                    const Text(
                      'No matching warehouse found.',
                      style: TextStyle(color: Colors.red),
                    ),

                  if (matchingWarehouses.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 220),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: matchingWarehouses.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final warehouse = matchingWarehouses[index];
                          final selected = warehouse.id == selectedWarehouseId;

                          return ListTile(
                            dense: true,
                            selected: selected,
                            leading: Icon(
                              selected
                                  ? Icons.check_circle
                                  : Icons.warehouse_outlined,
                            ),
                            title: Text(warehouse.name),
                            subtitle: Text(
                              'ID: ${warehouse.id}\n'
                              'Branch code: ${warehouse.branchCode}',
                            ),
                            isThreeLine: true,
                            trailing: Icon(
                              selected ? Icons.check : Icons.chevron_right,
                            ),
                            onTap: () {
                              setState(() {
                                selectedWarehouseId = warehouse.id;
                                warehouseSearchController.text = warehouse.name;
                              });
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),

                  if (selectedWarehouse != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected warehouse',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text('Name: ${selectedWarehouse.name}'),
                          Text('ID: ${selectedWarehouse.id}'),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
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
          icon: Icon(isEditing ? Icons.save_outlined : Icons.person_add),
          label: Text(isEditing ? 'Save Changes' : 'Create User'),
        ),
      ],
    );
  }
}
