import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/extensions.dart';
import '../../../providers/auth_provider.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded, color: Colors.white),
            onPressed: () => context.push('/admin/users/new'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name, shop or phone…',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        })
                    : null,
              ),
            ),
          ),
          Expanded(
            child: usersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => const Center(child: Text('Unable to load users. Please try again.')),
              data: (users) {
                final filtered = _query.isEmpty
                    ? users
                    : users.where((u) =>
                        u.name.toLowerCase().contains(_query) ||
                        u.shopName.toLowerCase().contains(_query) ||
                        u.phone.contains(_query)).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.people_outline, size: 64,
                          color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      const Text('No users found'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => context.push('/admin/users/new'),
                        icon: const Icon(Icons.person_add_rounded),
                        label: const Text('Create User'),
                        style: ElevatedButton.styleFrom(
                            minimumSize: const Size(160, 44)),
                      ),
                    ]),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final u = filtered[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Row(children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.12),
                          child: Text(
                            u.name.isNotEmpty
                                ? u.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: 18),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(u.name,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              Text(u.shopName,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodyMedium),
                              Text(u.phone,
                                  maxLines: 1, overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: (u.isActive
                                        ? AppColors.success
                                        : AppColors.error)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                u.isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: u.isActive
                                      ? AppColors.success
                                      : AppColors.error,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(u.createdAt.display,
                                style: context.textTheme.bodySmall),
                          ],
                        ),
                        const SizedBox(width: 8),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'toggle') {
                              await ref
                                  .read(authRepoProvider)
                                  .updateUser(u.id, {'isActive': !u.isActive});
                              if (context.mounted) {
                                context.showSnack(u.isActive
                                    ? 'User deactivated'
                                    : 'User activated');
                              }
                            }
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'toggle',
                              child: Text(u.isActive
                                  ? 'Deactivate User'
                                  : 'Activate User'),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert, size: 20),
                        ),
                      ]),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/users/new'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_rounded, color: Colors.white),
        label: const Text('Create User',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
