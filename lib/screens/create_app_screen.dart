import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/app_widgets.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_app_theme.dart';

class CreateAppScreen extends StatefulWidget {
  final AppModel? app;

  /// Optional debug-only prefill used by `ScreenshotRouter`.
  final String? demoName;
  final String? demoPackage;
  final Map<String, dynamic>? demoServiceAccount;
  final bool demoAccepted;

  const CreateAppScreen({
    super.key,
    this.app,
    this.demoName,
    this.demoPackage,
    this.demoServiceAccount,
    this.demoAccepted = false,
  });

  @override
  State<CreateAppScreen> createState() => _CreateAppScreenState();
}

class _CreateAppScreenState extends State<CreateAppScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _packageController = TextEditingController();
  final _appStorage = AppStorageService();
  final _secureStorage = SecureStorageService();
  Map<String, dynamic>? _serviceAccount;
  String? _selectedLogoImageData; // Base64 encoded image data
  bool _understandEncryption = false;
  bool _acceptLiability = false;

  @override
  void initState() {
    super.initState();
    if (widget.demoName != null) _nameController.text = widget.demoName!;
    if (widget.demoPackage != null) _packageController.text = widget.demoPackage!;
    _serviceAccount = widget.demoServiceAccount;
    _understandEncryption = widget.demoAccepted;
    _acceptLiability = widget.demoAccepted;
    if (widget.app != null) {
      _nameController.text = widget.app!.name;
      _packageController.text = widget.app!.packageName;
      _selectedLogoImageData = widget.app!.imageData;
      // Load existing JSON credentials from secure storage
      _loadExistingCredentials();
    }
  }

  Future<void> _loadExistingCredentials() async {
    if (widget.app != null) {
      final credentials = await _secureStorage.getAppCredentials(widget.app!.id);
      if (credentials != null) {
        setState(() {
          _serviceAccount = credentials;
        });
      }
    }
  }

  Future<void> _pickJsonFile() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (file != null) {
        // Validate JSON and create GoogleKeyModel
        try {
          final jsonContent = utf8.decode(await file.readAsBytes());
          final serviceAccount = jsonDecode(jsonContent) as Map<String, dynamic>;
          
          // Validate the model
          if (serviceAccount.isEmpty) {
            throw Exception('Invalid service account JSON. Missing required fields.');
          }
          
          // Store GoogleKeyModel
          setState(() {
            _serviceAccount = serviceAccount;
          });
        } catch (e) {
          if (mounted) {
            showAppSnackBar(context, 'Invalid JSON file: $e', type: SnackType.error);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error loading file: $e', type: SnackType.error);
      }
    }
  }

  Widget _buildLogoPreview() {
    final emptyPlaceholder = Container(
      width: double.infinity,
      height: AppSizes.logoPreview,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.large,
        border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
      ),
      child: const HeroIcon(
        HeroIcons.photo,
        size: AppSizes.iconXl,
        color: AppColors.textMuted,
      ),
    );

    if (_selectedLogoImageData == null || _selectedLogoImageData!.isEmpty) {
      return emptyPlaceholder;
    }

    try {
      final imageBytes = base64Decode(_selectedLogoImageData!);
      return ClipRRect(
        borderRadius: AppRadius.large,
        child: Image.memory(
          imageBytes,
          width: double.infinity,
          height: AppSizes.logoPreview,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return emptyPlaceholder;
          },
        ),
      );
    } catch (e) {
      return emptyPlaceholder;
    }
  }

  Future<void> _pickLogoFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.image,
      );

      if (file != null) {
        // Read image as bytes and convert to base64
        final imageBytes = await file.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        setState(() {
          _selectedLogoImageData = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Error loading image: $e', type: SnackType.error);
      }
    }
  }

  Future<void> _saveApp() async {
    // Dismiss keyboard
    FocusScope.of(context).unfocus();
    
    if (!_formKey.currentState!.validate()) return;
    
    // Check if we have GoogleKeyModel (new file) or need to load from secure storage (existing app)
    Map<String, dynamic>? serviceAccount = _serviceAccount;
    
    // If editing existing app and no new JSON selected, try to load from secure storage
    if (serviceAccount == null && widget.app != null) {
      serviceAccount = await _secureStorage.getAppCredentials(widget.app!.id);
    }
    
    if (serviceAccount == null && mounted) {
      showAppSnackBar(context, 'Please select a JSON file', type: SnackType.error);
      return;
    }

    // Check if both checkboxes are checked (only for new apps or when JSON is selected)
    if (serviceAccount != null && (!_understandEncryption || !_acceptLiability)) {
      if (mounted) {
        showAppSnackBar(context, 'Please accept both terms before creating the app', type: SnackType.error);
      }
      return;
    }

    final appId = widget.app?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    
    if (serviceAccount == null) {
      return;
    }
    
    // Save JSON content to secure storage using the model
    await _secureStorage.saveAppCredentials(appId, serviceAccount);
    
    final app = AppModel(
      id: appId,
      name: _nameController.text.trim(),
      packageName: _packageController.text.trim(),
      imageData: _selectedLogoImageData,
      createdAt: widget.app?.createdAt ?? DateTime.now(),
      topics: widget.app?.topics ?? [],
      devices: widget.app?.devices ?? [],
      conditions: widget.app?.conditions ?? [],
    );

    await _appStorage.saveApp(app);

    if (mounted) {
      showAppSnackBar(
        context,
        widget.app == null ? 'App saved successfully' : 'App updated successfully',
        type: SnackType.success,
      );
      Navigator.pop(context, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _packageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.app == null ? 'Create App' : 'Edit App'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screen,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: AppSpacing.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo picker
                          GestureDetector(
                            onTap: _pickLogoFile,
                            child: _buildLogoPreview(),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'App Name',
                              hintText: 'My Awesome App',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter app name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _packageController,
                            decoration: const InputDecoration(
                              labelText: 'Package Name',
                              hintText: 'com.example.app',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter package name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.md),
                          if (_serviceAccount == null)
                            InkWell(
                              onTap: _pickJsonFile,
                              borderRadius: AppRadius.large,
                              child: Container(
                                padding: AppSpacing.card,
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: AppRadius.large,
                                  border: Border.all(color: AppColors.border, width: AppSizes.borderWidth),
                                ),
                                child: Row(
                                  children: [
                                    const HeroIcon(HeroIcons.documentArrowUp, color: AppColors.textSecondary),
                                    const SizedBox(width: AppSpacing.md),
                                    Text(
                                      'Select a JSON file',
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (_serviceAccount != null) ...[
                            _buildJsonFieldsExpansion(),
                          ],
                        ],
                      ),
                    ),
                    CheckboxListTile(
                      title: Text('I understand that my key is encrypted and stored only on this device.', style: Theme.of(context).textTheme.labelMedium),
                      value: _understandEncryption,
                      onChanged: (value) {
                        setState(() {
                          _understandEncryption = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: Text('I understand that I am responsible for any Google account or billing issues.', style: Theme.of(context).textTheme.labelMedium),
                      value: _acceptLiability,
                      onChanged: (value) {
                        setState(() {
                          _acceptLiability = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton(
                onPressed: _saveApp,
                child: Text(widget.app == null ? 'Save App' : 'Update App'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJsonFieldsExpansion() {
    if (_serviceAccount == null) return const SizedBox.shrink();

    return Card(
      child: ExpansionTile(
        title: Row(
          children: [
            const HeroIcon(HeroIcons.informationCircle, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _serviceAccount!['project_id'],
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_serviceAccount!.isNotEmpty) ...[
                  ..._serviceAccount!.entries
                      .where((entry) => 
                          entry.key != 'project_id' && 
                          entry.key != 'client_email' && 
                          entry.key != 'private_key')
                      .map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TextFormField(
                        initialValue: _formatJsonValue(entry.value),
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: entry.key,
                        ),
                        maxLines: entry.value is String && entry.value.length > 100 ? 3 : 1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textPrimary),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _serviceAccount = null;
                    });
                  },
                  icon: const HeroIcon(HeroIcons.trash),
                  label: const Text('Clear Data'),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatJsonValue(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is Map || value is List) {
      return jsonEncode(value);
    }
    return value.toString();
  }
}