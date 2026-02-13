import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:admin_frontend/models/grant.dart';
import 'package:admin_frontend/theme/app_theme.dart';
import 'package:admin_frontend/services/grant_service.dart';

class GrantEditorScreen extends StatefulWidget {
  final Grant? grant;

  const GrantEditorScreen({
    super.key, 
    this.grant,
  });

  @override
  State<GrantEditorScreen> createState() => _GrantEditorScreenState();
}

class _GrantEditorScreenState extends State<GrantEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _providerCtrl;
  late TextEditingController _amountCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _applyUrlCtrl;
  
  List<String> _eligibilityCriteria = [];
  List<String> _requiredDocuments = [];
  String _selectedCategory = 'General';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  bool _isLoading = false;

  final _grantService = GrantService();

  static const List<String> _categories = [
    'General',
    'Housing',
    'Education',
    'Healthcare',
    'Employment',
    'Legal',
    'Emergency',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.grant?.title ?? '');
    _providerCtrl = TextEditingController(text: widget.grant?.organizer ?? '');
    _amountCtrl = TextEditingController(text: widget.grant?.amount ?? '');
    _descCtrl = TextEditingController(text: widget.grant?.description ?? '');
    _locationCtrl = TextEditingController(text: widget.grant?.country ?? '');
    _applyUrlCtrl = TextEditingController(text: widget.grant?.applyUrl ?? '');
    _selectedCategory = widget.grant?.category ?? 'General';
    
    if (widget.grant != null) {
      _selectedDate = widget.grant!.deadline;
      _eligibilityCriteria = List.from(widget.grant!.eligibilityCriteria);
      _requiredDocuments = List.from(widget.grant!.requiredDocuments);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _providerCtrl.dispose();
    _amountCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    _applyUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveGrant() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final newGrant = Grant(
        id: widget.grant?.id ?? '', // ID ignored on create
        title: _titleCtrl.text,
        organizer: _providerCtrl.text,
        country: _locationCtrl.text,
        category: _selectedCategory,
        deadline: _selectedDate,
        amount: _amountCtrl.text,
        description: _descCtrl.text,
        eligibilityCriteria: _eligibilityCriteria,
        requiredDocuments: _requiredDocuments,
        applyUrl: _applyUrlCtrl.text.isEmpty ? 'https://example.com/apply' : _applyUrlCtrl.text,
        isVerified: widget.grant?.isVerified ?? false, // Preserve existing or default to false
      );

      if (widget.grant == null) {
          await _grantService.createGrant(newGrant);
      } else {
          await _grantService.updateGrant(newGrant);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Grant saved successfully!'), backgroundColor: AppTheme.success),
        );
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Error saving grant: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addListItem(List<String> list, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController();
        return AlertDialog(
          title: Text('Add $itemName'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(hintText: 'Enter $itemName'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() => list.add(ctrl.text));
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _editListItem(List<String> list, int index, String itemName) {
    showDialog(
      context: context,
      builder: (context) {
        final ctrl = TextEditingController(text: list[index]);
        return AlertDialog(
          title: Text('Edit $itemName'),
          content: TextField(
            controller: ctrl,
            decoration: InputDecoration(hintText: 'Enter $itemName'),
            autofocus: true,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                setState(() => list.removeAt(index));
                Navigator.pop(context);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
            ElevatedButton(
              onPressed: () {
                if (ctrl.text.isNotEmpty) {
                  setState(() => list[index] = ctrl.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onAdd) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          IconButton(
            onPressed: onAdd,
            icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<String> list, String itemName) {
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('No $itemName added yet.', style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          color: Colors.grey[100],
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(list[index]),
            trailing: const Icon(Icons.edit, size: 16),
            onTap: () => _editListItem(list, index, itemName),
            dense: true,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.grant == null ? 'Create Grant' : 'Edit Grant'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveGrant,
            icon: _isLoading 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Icon(Icons.save),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 100.0), // Added bottom padding for navigation bar
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Info Section
              const Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(labelText: 'Grant Title *', prefixIcon: Icon(Icons.title)),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _providerCtrl,
                      decoration: const InputDecoration(labelText: 'Provider *', prefixIcon: Icon(Icons.business)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _locationCtrl,
                      decoration: const InputDecoration(labelText: 'Location *', prefixIcon: Icon(Icons.location_on)),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category *',
                  prefixIcon: Icon(Icons.category_rounded),
                ),
                items: _categories.map((String category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedCategory = newValue);
                  }
                },
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _amountCtrl,
                decoration: const InputDecoration(
                  labelText: 'Amount *', 
                  prefixIcon: Icon(Icons.payments_outlined),
                  hintText: 'e.g., \$500 or €1,000',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description)),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Deadline *',
                    prefixIcon: Icon(Icons.calendar_today),
                    helperText: 'Deadline is required for all grants',
                  ),
                  child: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              
              // Apply Configuration
              const Text('Application Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
               TextFormField(
                controller: _applyUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Apply Button URL', 
                  prefixIcon: Icon(Icons.link),
                  hintText: 'https://example.com/apply-here',
                  helperText: 'Users will be redirected to this link when they click Apply',
                ),
              ),
              
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Dynamic Lists
              _buildSectionHeader('Eligibility Criteria', () => _addListItem(_eligibilityCriteria, 'Criteria')),
              _buildList(_eligibilityCriteria, 'Criteria'),

              const SizedBox(height: 16),

              _buildSectionHeader('Required Documents', () => _addListItem(_requiredDocuments, 'Document')),
              _buildList(_requiredDocuments, 'Document'),
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGrant,
                  child: const Text('Save Grant'),
                ),
              ),
              const SizedBox(height: 24), // Extra spacing after button
            ],
          ),
        ),
      ),
    );
  }
}
