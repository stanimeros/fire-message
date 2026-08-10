import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:heroicons/heroicons.dart';
import '../models/app_model.dart';
import '../services/app_storage_service.dart';
import '../services/secure_storage_service.dart';
import '../widgets/custom_app_bar.dart';

class CreateAppScreen extends StatefulWidget {
  final AppModel? app;
  
  const CreateAppScreen({super.key, this.app});

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
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        // Validate JSON and create GoogleKeyModel
        try {
          final jsonContent = await file.readAsString();
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Invalid JSON file: $e'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Widget _buildLogoPreview() {
    final theme = Theme.of(context);
    final emptyPlaceholder = Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.image,
        size: 50,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );

    if (_selectedLogoImageData == null || _selectedLogoImageData!.isEmpty) {
      return emptyPlaceholder;
    }

    try {
      final imageBytes = base64Decode(_selectedLogoImageData!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          imageBytes,
          width: double.infinity,
          height: 200,
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
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final filePath = result.files.single.path!;
        final file = File(filePath);
        
        // Read image as bytes and convert to base64
        final imageBytes = await file.readAsBytes();
        final base64Image = base64Encode(imageBytes);
        
        setState(() {
          _selectedLogoImageData = base64Image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading image: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a JSON file'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    // Check if both checkboxes are checked (only for new apps or when JSON is selected)
    if (serviceAccount != null && (!_understandEncryption || !_acceptLiability)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please accept both terms before creating the app'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.app == null ? 'App saved successfully' : 'App updated successfully')),
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
        padding: const EdgeInsets.all(12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo picker
                          GestureDetector(
                            onTap: _pickLogoFile,
                            child: _buildLogoPreview(),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'App Name',
                              hintText: 'My Awesome App',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter app name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _packageController,
                            decoration: const InputDecoration(
                              labelText: 'Package Name',
                              hintText: 'com.example.app',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter package name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          if (_serviceAccount == null)
                            InkWell(
                              onTap: _pickJsonFile,
                              borderRadius: BorderRadius.circular(8),
                              child: InputDecorator(
                                isEmpty: true,
                                decoration: InputDecoration(
                                  labelText: 'Select a json file',
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
                      title: const Text('I understand that my key is encrypted and stored only on this device.', style: TextStyle(fontSize: 13)),
                      value: _understandEncryption,
                      onChanged: (value) {
                        setState(() {
                          _understandEncryption = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    CheckboxListTile(
                      title: const Text('I understand that I am responsible for any google account or billing issues.', style: TextStyle(fontSize: 13)),
                      value: _acceptLiability,
                      onChanged: (value) {
                        setState(() {
                          _acceptLiability = value ?? false;
                        });
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
            Icon(
              Icons.info_outline,
              size: 20,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              _serviceAccount!['project_id'],
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
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
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: TextFormField(
                        initialValue: _formatJsonValue(entry.value),
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: entry.key,
                          border: const OutlineInputBorder(),
                          filled: true,
                          fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                        ),
                        maxLines: entry.value is String && entry.value.length > 100 ? 3 : 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    );
                  }),
                ],
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _serviceAccount = null;
                    });
                  },
                  icon: const HeroIcon(HeroIcons.trash),
                  label: const Text('Clear Data'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
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