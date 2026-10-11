import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/custom_app_theme.dart';
import 'app_detail_screen.dart';
import 'create_app_screen.dart';

class AppsScreen extends StatefulWidget {
  final void Function(VoidCallback)? onRefreshCallback;
  final VoidCallback? onDataChanged;

  const AppsScreen({
    super.key,
    this.onRefreshCallback,
    this.onDataChanged,
  });

  @override
  State<AppsScreen> createState() => _AppsScreenState();
}

class _AppsScreenState extends State<AppsScreen> with AutomaticKeepAliveClientMixin {
  final _appStorage = AppStorageService();
  List<AppModel> _apps = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    widget.onRefreshCallback?.call(_loadApps);
    _loadApps();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload apps when returning to this screen
    _loadApps();
  }

  Future<void> _loadApps() async {
    final apps = await _appStorage.getApps();
    setState(() {
      _apps = apps;
    });
  }

  Future<bool> _deleteApp(AppModel app) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete App'),
        content: Text('Are you sure you want to delete ${app.name}? This action cannot be undone.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.onStatus,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _appStorage.deleteApp(app.id);
      _loadApps();
      if (mounted) {
        showAppSnackBar(context, 'App deleted');
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: _apps.isEmpty
          ? const EmptyState(
              icon: HeroIcons.inbox,
              title: 'No apps yet',
              subtitle: 'Tap Create App to connect your first Firebase project',
            )
          : ListView.separated(
              padding: AppSpacing.screen,
              itemCount: _apps.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.listGap),
              itemBuilder: (context, index) {
                final app = _apps[index];
                return Dismissible(
                  key: Key(app.id),
                  direction: DismissDirection.endToStart,
                  background: const DismissDeleteBackground(),
                  confirmDismiss: (direction) async {
                    final deleted = await _deleteApp(app);
                    if (deleted) {
                      widget.onDataChanged?.call();
                    }
                    return deleted;
                  },
                  child: Card(
                    child: ListTile(
                      leading: AppAvatar(imageData: app.imageData, name: app.name),
                      title: Text(app.name),
                      subtitle: Text(app.packageName),
                      trailing: const HeroIcon(
                        HeroIcons.chevronRight,
                        color: AppColors.textMuted,
                        size: AppSizes.iconMd,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AppDetailScreen(
                              app: app,
                              onDataChanged: () {
                                _loadApps();
                                widget.onDataChanged?.call();
                              },
                            ),
                          ),
                        ).then((result) {
                          _loadApps();
                          if (result == true) {
                            widget.onDataChanged?.call();
                          }
                        });
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateAppScreen(),
            ),
          );
          if (result == true) {
            _loadApps();
            widget.onDataChanged?.call();
          }
        },
        icon: const HeroIcon(HeroIcons.plus),
        label: const Text('Create App'),
      ),
    );
  }
}

