import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_errors.dart';
import '../features/auth/presentation/providers/auth_providers.dart';
import '../providers/push_provider.dart';
import '../routes.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _subscribed = true;
  bool _updatingSubscription = false;

  Future<void> _toggleSubscription() async {
    setState(() => _updatingSubscription = true);
    try {
      final pushService = ref.read(pushServiceProvider);
      if (_subscribed) {
        await pushService.unsubscribeFromAnnouncements();
      } else {
        await pushService.subscribeToAnnouncements();
      }
      if (mounted) setState(() => _subscribed = !_subscribed);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(apiFailureFrom(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _updatingSubscription = false);
    }
  }

  Future<void> _logout() => ref.read(authStateProvider.notifier).logout();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Notification'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.waving_hand_outlined, color: colors.primary),
                const SizedBox(height: 16),
                Text(
                  'Halo, Mahasiswa!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Temukan informasi dan pengumuman terbaru kampus di sini.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: colors.onPrimaryContainer),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Menu',
            style: Theme.of(context).textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              leading: CircleAvatar(
                backgroundColor: colors.secondaryContainer,
                child: Icon(
                  Icons.campaign_outlined,
                  color: colors.onSecondaryContainer,
                ),
              ),
              title: const Text('Pengumuman kampus'),
              subtitle: const Text('Lihat informasi terbaru'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(AppRoutes.announcement('demo')),
            ),
          ),
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 8,
              ),
              secondary: CircleAvatar(
                backgroundColor: colors.tertiaryContainer,
                child: Icon(
                  Icons.notifications_active_outlined,
                  color: colors.onTertiaryContainer,
                ),
              ),
              title: const Text('Notifikasi pengumuman'),
              subtitle: Text(
                _subscribed ? 'Notifikasi sedang aktif' : 'Notifikasi nonaktif',
              ),
              value: _subscribed,
              onChanged: _updatingSubscription
                  ? null
                  : (_) => _toggleSubscription(),
            ),
          ),
          if (_updatingSubscription)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
