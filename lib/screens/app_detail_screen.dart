import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../models/topic_model.dart';
import '../models/device_model.dart';
import '../models/condition_model.dart';
import '../services/app_storage_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_app_theme.dart';
import 'create_app_screen.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;
  final VoidCallback? onDataChanged;

  const AppDetailScreen({
    super.key,
    required this.app,
    this.onDataChanged,
  });

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _appStorage = AppStorageService();
  
  late AppModel _currentApp;
  List<TopicModel> _topics = [];
  List<DeviceModel> _devices = [];
  List<ConditionModel> _conditions = [];

  @override
  void initState() {
    super.initState();
    _currentApp = widget.app;
    _topics = widget.app.topics;
    _devices = widget.app.devices;
    _conditions = widget.app.conditions;
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {}); // Rebuild when tab changes to update FAB
    });
    _loadData();
  }

  Future<void> _loadData() async {
    final app = await _appStorage.getAppById(_currentApp.id);
    if (app != null) {
      setState(() {
        _currentApp = app;
        _topics = app.topics;
        _devices = app.devices;
        _conditions = app.conditions;
      });
    }
  }

  Future<void> _showAddTopicDialog({TopicModel? topicToEdit}) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => _AddTopicDialog(topicToEdit: topicToEdit),
    );

    if (result != null && result.isNotEmpty) {
      if (topicToEdit != null) {
        // Update existing topic
        final updatedTopic = TopicModel(
          id: topicToEdit.id,
          name: result,
          createdAt: topicToEdit.createdAt,
        );
        await _appStorage.updateTopic(_currentApp.id, updatedTopic);
        if (mounted) {
          showAppSnackBar(context, 'Topic updated successfully');
        }
      } else {
        // Add new topic
        final topic = TopicModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result,
          createdAt: DateTime.now(),
        );
        await _appStorage.addTopic(_currentApp.id, topic);
        if (mounted) {
          showAppSnackBar(context, 'Topic added successfully');
        }
      }
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<bool> _deleteTopic(TopicModel topic) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Topic'),
        content: Text('Are you sure you want to delete topic "${topic.name}"?'),
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
      await _appStorage.deleteTopic(_currentApp.id, topic.id);
      _loadData();
      if (mounted) {
        showAppSnackBar(context, 'Topic deleted');
        widget.onDataChanged?.call();
      }
      return true;
    }
    return false;
  }

  Future<void> _showAddDeviceDialog({DeviceModel? deviceToEdit}) async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => _AddDeviceDialog(deviceToEdit: deviceToEdit),
    );

    if (result != null && result.containsKey('name') && result.containsKey('token')) {
      if (deviceToEdit != null) {
        // Update existing device
        final updatedDevice = DeviceModel(
          id: deviceToEdit.id,
          name: result['name']!,
          notificationToken: result['token']!,
          createdAt: deviceToEdit.createdAt,
        );
        await _appStorage.updateDevice(_currentApp.id, updatedDevice);
        if (mounted) {
          showAppSnackBar(context, 'Device updated successfully');
        }
      } else {
        // Add new device
        final device = DeviceModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['name']!,
          notificationToken: result['token']!,
          createdAt: DateTime.now(),
        );
        await _appStorage.addDevice(_currentApp.id, device);
        if (mounted) {
          showAppSnackBar(context, 'Device added successfully');
        }
      }
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<bool> _deleteDevice(DeviceModel device) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Device'),
        content: Text('Are you sure you want to delete device "${device.name}"?'),
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
      await _appStorage.deleteDevice(_currentApp.id, device.id);
      _loadData();
      if (mounted) {
        showAppSnackBar(context, 'Device deleted');
        widget.onDataChanged?.call();
      }
      return true;
    }
    return false;
  }

  Future<void> _showAddConditionDialog({ConditionModel? conditionToEdit}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _AddConditionDialog(
        topics: _topics,
        conditions: _conditions.where((c) => c.id != conditionToEdit?.id).toList(), // Exclude self from nested conditions
        conditionToEdit: conditionToEdit,
      ),
    );

    if (result != null && result.containsKey('name') && result.containsKey('operator')) {
      if (conditionToEdit != null) {
        // Update existing condition
        final updatedCondition = ConditionModel(
          id: conditionToEdit.id,
          name: result['name']!,
          operator: result['operator']!,
          topicIds: (result['topicIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          conditionIds: (result['conditionIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          createdAt: conditionToEdit.createdAt,
        );
        await _appStorage.updateCondition(_currentApp.id, updatedCondition);
        if (mounted) {
          showAppSnackBar(context, 'Condition updated successfully');
        }
      } else {
        // Add new condition
        final condition = ConditionModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: result['name']!,
          operator: result['operator']!,
          topicIds: (result['topicIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          conditionIds: (result['conditionIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
          createdAt: DateTime.now(),
        );
        await _appStorage.addCondition(_currentApp.id, condition);
        if (mounted) {
          showAppSnackBar(context, 'Condition added successfully');
        }
      }
      _loadData();
      widget.onDataChanged?.call();
    }
  }

  Future<bool> _deleteCondition(ConditionModel condition) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Condition'),
        content: Text('Are you sure you want to delete condition "${condition.name}"?'),
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
      await _appStorage.deleteCondition(_currentApp.id, condition.id);
      _loadData();
      if (mounted) {
        showAppSnackBar(context, 'Condition deleted');
        widget.onDataChanged?.call();
      }
      return true;
    }
    return false;
  }

  String _getFABLabel() {
    final currentIndex = _tabController.index;
    if (currentIndex == 0) {
      return 'Add Device';
    } else if (currentIndex == 1) {
      return 'Add Topic';
    } else if (currentIndex == 2) {
      return 'Add Condition';
    }
    return 'Add';
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.app.name),
        actions: [
          IconButton(
            icon: const HeroIcon(HeroIcons.pencil),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CreateAppScreen(app: _currentApp),
                ),
              );
              if (result == true && context.mounted) {
                // Reload the app data if it was updated
                await _loadData();
                widget.onDataChanged?.call();
                if (context.mounted) {
                  Navigator.pop(context, true);
                }
              }
            },
            tooltip: 'Edit App',
          ),
        ],
      ),
      body: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.devicePhoneMobile, size: AppSizes.iconSm),
                    SizedBox(width: AppSpacing.xs),
                    Text('Devices'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.hashtag, size: AppSizes.iconSm),
                    SizedBox(width: AppSpacing.xs),
                    Text('Topics'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    HeroIcon(HeroIcons.funnel, size: AppSizes.iconSm),
                    SizedBox(width: AppSpacing.xs),
                    Text('Conditions'),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildDevicesTab(),
                _buildTopicsTab(),
                _buildConditionsTab(),
              ],
            ),  
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentIndex = _tabController.index;
          if (currentIndex == 0) {
            // Devices tab
            _showAddDeviceDialog();
          } else if (currentIndex == 1) {
            // Topics tab
            _showAddTopicDialog();
          } else if (currentIndex == 2) {
            // Conditions tab
            _showAddConditionDialog();
          }
        },
        icon: const HeroIcon(HeroIcons.plus),
        label: Text(_getFABLabel()),
      ),
    );
  }

  Widget _buildTopicsTab() {
    if (_topics.isEmpty) {
      return const EmptyState(
        icon: HeroIcons.inbox,
        title: 'No topics yet',
        subtitle: 'Tap + to add one',
      );
    }
    
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: _topics.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (context, index) {
        final topic = _topics[index];
        return Dismissible(
          key: Key(topic.id),
          direction: DismissDirection.endToStart,
          background: const DismissDeleteBackground(),
          confirmDismiss: (direction) async {
            final deleted = await _deleteTopic(topic);
            if (deleted) {
              widget.onDataChanged?.call();
            }
            return deleted;
          },
          child: Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: HeroIcon(HeroIcons.hashtag),
              ),
              title: Text(topic.name),
              trailing: IconButton(
                icon: const HeroIcon(HeroIcons.pencil),
                onPressed: () => _showAddTopicDialog(topicToEdit: topic),
                tooltip: 'Edit',
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDevicesTab() {
    if (_devices.isEmpty) {
      return const EmptyState(
        icon: HeroIcons.inbox,
        title: 'No devices yet',
        subtitle: 'Tap + to add one',
      );
    }
    
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: _devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (context, index) {
        final device = _devices[index];
        return Dismissible(
          key: Key(device.id),
          direction: DismissDirection.endToStart,
          background: const DismissDeleteBackground(),
          confirmDismiss: (direction) async {
            final deleted = await _deleteDevice(device);
            if (deleted) {
              widget.onDataChanged?.call();
            }
            return deleted;
          },
          child: Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: HeroIcon(HeroIcons.devicePhoneMobile),
              ),
              title: Text(device.name),
              subtitle: Text(
                device.notificationToken,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const HeroIcon(HeroIcons.pencil),
                onPressed: () => _showAddDeviceDialog(deviceToEdit: device),
                tooltip: 'Edit',
              ),
            ),
          ),
        );
      },
    );
  }

  String _buildConditionSubtitle(ConditionModel condition) {
    final parts = <String>[];
    
    // Add topic names
    for (final topicId in condition.topicIds) {
      final topic = _topics.firstWhere(
        (t) => t.id == topicId,
        orElse: () => TopicModel(id: '', name: '', createdAt: DateTime.now()),
      );
      if (topic.id.isNotEmpty) {
        parts.add(topic.name);
      }
    }
    
    // Add nested condition names
    for (final conditionId in condition.conditionIds) {
      final nestedCondition = _conditions.firstWhere(
        (c) => c.id == conditionId,
        orElse: () => ConditionModel(id: '', name: '', operator: 'AND', createdAt: DateTime.now()),
      );
      if (nestedCondition.id.isNotEmpty) {
        parts.add(nestedCondition.name);
      }
    }
    
    if (parts.isEmpty) {
      return 'No topics or conditions';
    }
    
    final operator = condition.operator == 'AND' ? ' AND ' : ' OR ';
    return parts.join(operator);
  }

  Widget _buildConditionsTab() {
    if (_conditions.isEmpty) {
      return const EmptyState(
        icon: HeroIcons.inbox,
        title: 'No conditions yet',
        subtitle: 'Tap + to add one',
      );
    }
    
    return ListView.separated(
      padding: AppSpacing.screen,
      itemCount: _conditions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.listGap),
      itemBuilder: (context, index) {
        final condition = _conditions[index];
        return Dismissible(
          key: Key(condition.id),
          direction: DismissDirection.endToStart,
          background: const DismissDeleteBackground(),
          confirmDismiss: (direction) async {
            final deleted = await _deleteCondition(condition);
            if (deleted) {
              widget.onDataChanged?.call();
            }
            return deleted;
          },
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                child: Text(
                  condition.operator,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              title: Text(condition.name),
              subtitle: Text(
                _buildConditionSubtitle(condition),
              ),
              trailing: IconButton(
                icon: const HeroIcon(HeroIcons.pencil),
                onPressed: () => _showAddConditionDialog(conditionToEdit: condition),
                tooltip: 'Edit',
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AddTopicDialog extends StatefulWidget {
  final TopicModel? topicToEdit;

  const _AddTopicDialog({this.topicToEdit});

  @override
  State<_AddTopicDialog> createState() => _AddTopicDialogState();
}

class _AddTopicDialogState extends State<_AddTopicDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.topicToEdit?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.topicToEdit == null ? 'Add Topic' : 'Edit Topic'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Topic Name',
            hintText: 'news',
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a topic name';
            }
            return null;
          },
          autofocus: true,
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, _nameController.text.trim());
            }
          },
          child: Text(widget.topicToEdit == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}

class _AddDeviceDialog extends StatefulWidget {
  final DeviceModel? deviceToEdit;

  const _AddDeviceDialog({this.deviceToEdit});

  @override
  State<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends State<_AddDeviceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _tokenController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.deviceToEdit?.name ?? '');
    _tokenController = TextEditingController(text: widget.deviceToEdit?.notificationToken ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.deviceToEdit == null ? 'Add Device' : 'Edit Device'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Device Name',
                  hintText: 'iPhone 15 Pro',
                      ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.words,
                autofocus: true,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _tokenController,
                decoration: const InputDecoration(
                  labelText: 'Notification Token',
                  hintText: 'FCM device token',
                      ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a token';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'token': _tokenController.text.trim(),
              });
            }
          },
          child: Text(widget.deviceToEdit == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}

class _AddConditionDialog extends StatefulWidget {
  final List<TopicModel> topics;
  final List<ConditionModel> conditions;
  final ConditionModel? conditionToEdit;

  const _AddConditionDialog({
    required this.topics,
    required this.conditions,
    this.conditionToEdit,
  });

  @override
  State<_AddConditionDialog> createState() => _AddConditionDialogState();
}

class _AddConditionDialogState extends State<_AddConditionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _operator;
  late final Set<String> _selectedTopicIds;
  late final Set<String> _selectedConditionIds;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.conditionToEdit?.name ?? '');
    _operator = widget.conditionToEdit?.operator ?? 'AND';
    _selectedTopicIds = Set<String>.from(widget.conditionToEdit?.topicIds ?? []);
    _selectedConditionIds = Set<String>.from(widget.conditionToEdit?.conditionIds ?? []);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      title: Text(widget.conditionToEdit == null ? 'Add Condition' : 'Edit Condition'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Condition Name',
                    hintText: 'Premium Users',
                          ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a condition name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: DropdownButtonFormField<String>(
                  initialValue: _operator,
                  decoration: const InputDecoration(
                    labelText: 'Operator',
                          ),
                  items: const [
                    DropdownMenuItem(value: 'AND', child: Text('AND')),
                    DropdownMenuItem(value: 'OR', child: Text('OR')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _operator = value;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: const Text('Select Topics:'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...widget.topics.map((topic) => CheckboxListTile(
                title: Text(topic.name),
                value: _selectedTopicIds.contains(topic.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedTopicIds.add(topic.id);
                    } else {
                      _selectedTopicIds.remove(topic.id);
                    }
                  });
                },
              )),
              const SizedBox(height: AppSpacing.lg),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: const Text('Select Conditions:'),
              ),
              const SizedBox(height: AppSpacing.sm),
              ...widget.conditions.map((condition) => CheckboxListTile(
                title: Text(condition.name),
                subtitle: Text('${condition.operator} operator'),
                value: _selectedConditionIds.contains(condition.id),
                onChanged: (checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedConditionIds.add(condition.id);
                    } else {
                      _selectedConditionIds.remove(condition.id);
                    }
                  });
                },
              )),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && 
                (_selectedTopicIds.isNotEmpty || _selectedConditionIds.isNotEmpty)) {
              Navigator.pop(context, {
                'name': _nameController.text.trim(),
                'operator': _operator,
                'topicIds': _selectedTopicIds.toList(),
                'conditionIds': _selectedConditionIds.toList(),
              });
            }
          },
          child: Text(widget.conditionToEdit == null ? 'Add' : 'Update'),
        ),
      ],
    );
  }
}
