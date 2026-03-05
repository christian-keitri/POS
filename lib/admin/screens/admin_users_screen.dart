import 'package:flutter/material.dart';
import 'package:pos/theme/app_theme.dart';
import 'package:pos/services/api_service.dart';
import 'package:pos/models/user.dart';

/// User management: list, add, edit, delete, assign roles.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<User> _users = [];
  bool _loading = true;
  String? _error;
  String _roleFilter = 'all';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await ApiService.getUsers(
        role: _roleFilter == 'all' ? null : _roleFilter,
      );
      if (!mounted) return;
      setState(() {
        _users = list;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    final q = _searchQuery.toLowerCase();
    return _users.where((u) {
      return u.email.toLowerCase().contains(q) ||
          (u.displayName?.toLowerCase().contains(q) ?? false) ||
          (u.businessName?.toLowerCase().contains(q) ?? false) ||
          u.role.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 280,
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Search',
                        hintText: 'Email, name, role...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                      onChanged: (v) => setState(() => _searchQuery = v),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _roleFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All roles')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'manager', child: Text('Manager')),
                      DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _roleFilter = v);
                      _load();
                    },
                  ),
                  FilledButton.icon(
                    onPressed: () => _showUserForm(context),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Add user'),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? _ErrorView(message: _error!, onRetry: _load)
                  : _UsersTable(
                      users: _filteredUsers,
                      onEdit: _editUser,
                      onDelete: _deleteUser,
                      onRefresh: _load,
                    ),
        ),
      ],
    );
  }

  void _showUserForm(BuildContext context, [User? user]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => _UserFormSheet(
        user: user,
        onSaved: () {
          Navigator.pop(ctx);
          _load();
        },
        onCancel: () => Navigator.pop(ctx),
      ),
    );
  }

  void _editUser(User user) => _showUserForm(context, user);

  Future<void> _deleteUser(User user) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: Text(
          'Remove "${user.name}" (${user.email})? This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await ApiService.deleteUser(user.id);
      if (mounted) {
        AppSnackBar.success(context, 'User deleted');
        _load();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e.toString());
    }
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<User> users;
  final void Function(User) onEdit;
  final void Function(User) onDelete;
  final VoidCallback onRefresh;

  const _UsersTable({
    required this.users,
    required this.onEdit,
    required this.onDelete,
    required this.onRefresh,
  });

  static String _roleDisplay(String role) {
    switch (role) {
      case 'admin': return 'Admin';
      case 'manager': return 'Manager';
      case 'cashier': return 'Cashier';
      default: return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.sizeOf(context).width < 700;
    if (isNarrow) {
      return RefreshIndicator(
        onRefresh: () async => onRefresh(),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          itemCount: users.length,
          itemBuilder: (context, i) {
            final u = users[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(u.name),
                subtitle: Text('${u.email} · ${_roleDisplay(u.role)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => onEdit(u),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: AppTheme.error),
                      onPressed: () => onDelete(u),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Email')),
            DataColumn(label: Text('Name')),
            DataColumn(label: Text('Role')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Actions'), numeric: true),
          ],
          rows: users.map((u) {
            return DataRow(
              cells: [
                DataCell(Text(u.email)),
                DataCell(Text(u.displayName ?? u.businessName ?? '—')),
                DataCell(Text(_roleDisplay(u.role))),
                DataCell(
                  Chip(
                    label: Text(u.isActive ? 'Active' : 'Inactive'),
                    backgroundColor: u.isActive ? AppTheme.success.withValues(alpha: 0.2) : AppTheme.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                DataCell(Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => onEdit(u),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: AppTheme.error),
                      onPressed: () => onDelete(u),
                    ),
                  ],
                )),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _UserFormSheet extends StatefulWidget {
  final User? user;
  final VoidCallback onSaved;
  final VoidCallback onCancel;

  const _UserFormSheet({this.user, required this.onSaved, required this.onCancel});

  @override
  State<_UserFormSheet> createState() => _UserFormSheetState();
}

class _UserFormSheetState extends State<_UserFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _displayNameController;
  late TextEditingController _passwordController;
  late String _role;
  late bool _isActive;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _emailController = TextEditingController(text: u?.email ?? '');
    _displayNameController = TextEditingController(text: u?.displayName ?? u?.businessName ?? '');
    _passwordController = TextEditingController();
    _role = u?.role ?? 'cashier';
    _isActive = u?.isActive ?? true;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      if (widget.user != null) {
        await ApiService.updateUser(
          widget.user!.id,
          email: _emailController.text.trim(),
          displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
          role: _role,
          isActive: _isActive,
          password: _passwordController.text.isEmpty ? null : _passwordController.text,
        );
      } else {
        if (_passwordController.text.isEmpty) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password is required for new users')),
          );
          return;
        }
        await ApiService.createUser(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim().isEmpty ? null : _displayNameController.text.trim(),
          role: _role,
        );
      }
      if (mounted) {
        AppSnackBar.success(context, widget.user != null ? 'User updated' : 'User created');
        widget.onSaved();
      }
    } catch (e) {
      if (mounted) AppSnackBar.error(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.user != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isEdit ? 'Edit user' : 'Add user',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !isEdit,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: isEdit ? 'New password (leave blank to keep)' : 'Password',
                  ),
                  obscureText: true,
                  validator: (v) {
                    if (!isEdit && (v == null || v.isEmpty)) return 'Required';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey(_role),
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'manager', child: Text('Manager')),
                    DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
                if (isEdit) ...[
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: _saving ? null : widget.onCancel, child: const Text('Cancel')),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _saving ? null : _submit,
                      child: _saving ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
