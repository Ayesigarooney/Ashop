import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/config/app_theme.dart';
import '../../core/config/constants.dart';
import '../../core/utils/backup_restore_helper.dart';
import '../../core/utils/security_helper.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_cubit.dart';
import '../../features/sale/data/models/sale_model.dart';
import '../../features/settings/data/settings_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SettingsRepository _settings;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _settings = context.read<SettingsRepository>();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const SizedBox(height: 12),
          Center(
            child: Stack(
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withOpacity(0.25),
                      width: 2,
                    ),
                  ),
                  child:
                      _settings.shopLogo != null &&
                          File(_settings.shopLogo!).existsSync()
                      ? ClipOval(
                          child: Image.file(
                            File(_settings.shopLogo!),
                            fit: BoxFit.cover,
                            width: 90,
                            height: 90,
                          ),
                        )
                      : Center(
                          child: Text(
                            _settings.shopName.isNotEmpty
                                ? _settings.shopName[0].toUpperCase()
                                : 'A',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickShopLogo(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              _settings.shopName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Center(
            child: Text(
              _settings.shopAddress.isEmpty
                  ? 'No address set'
                  : _settings.shopAddress,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Shop Profile
          _SettingsSection(
            title: 'Shop Profile',
            icon: Icons.store_rounded,
            children: [
              _SettingsTile(
                title: 'Shop Name',
                subtitle: _settings.shopName,
                onTap: () =>
                    _editText(context, 'Shop Name', _settings.shopName, (v) {
                      _settings.shopName = v;
                      setState(() {});
                    }),
              ),
              _SettingsTile(
                title: 'Address',
                subtitle: _settings.shopAddress.isEmpty
                    ? 'Not set'
                    : _settings.shopAddress,
                onTap: () =>
                    _editText(context, 'Address', _settings.shopAddress, (v) {
                      _settings.shopAddress = v;
                      setState(() {});
                    }),
              ),
              _SettingsTile(
                title: 'Phone Number',
                subtitle: _settings.shopPhone.isEmpty
                    ? 'Not set'
                    : _settings.shopPhone,
                onTap: () => _editText(
                  context,
                  'Phone Number',
                  _settings.shopPhone,
                  (v) {
                    _settings.shopPhone = v;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          // Receipt Settings
          _SettingsSection(
            title: 'Receipt',
            icon: Icons.receipt_long_rounded,
            children: [
              _SettingsTile(
                title: 'Header Message',
                subtitle: _settings.receiptHeader.isEmpty
                    ? 'Not set'
                    : _settings.receiptHeader,
                onTap: () => _editText(
                  context,
                  'Receipt Header',
                  _settings.receiptHeader,
                  (v) {
                    _settings.receiptHeader = v;
                    setState(() {});
                  },
                ),
              ),
              _SettingsTile(
                title: 'Footer Message',
                subtitle: _settings.receiptFooter,
                onTap: () => _editText(
                  context,
                  'Receipt Footer',
                  _settings.receiptFooter,
                  (v) {
                    _settings.receiptFooter = v;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),

          // Printer & Receipt Settings
          _SettingsSection(
            title: 'Printer & Receipt',
            icon: Icons.print_rounded,
            children: [
              _SettingsTile(
                title: 'Receipt Template',
                subtitle: _settings.receiptTemplateStyle == 'modern'
                    ? 'Modern'
                    : _settings.receiptTemplateStyle == 'classic'
                    ? 'Classic'
                    : 'Compact',
                onTap: () => _pickReceiptTemplate(context),
              ),
              _SettingsSwitchTile(
                title: 'Show Logo on Receipt',
                subtitle: 'Print store logo on receipts',
                value: _settings.printerShowLogo,
                onChanged: (v) {
                  _settings.printerShowLogo = v;
                  setState(() {});
                },
              ),
              _SettingsSwitchTile(
                title: 'Show Footer on Receipt',
                subtitle: 'Print footer on receipts',
                value: _settings.printerShowFooter,
                onChanged: (v) {
                  _settings.printerShowFooter = v;
                  setState(() {});
                },
              ),
              _SettingsTile(
                title: 'Paper Size',
                subtitle: _settings.printerPaperSize,
                onTap: () => _pickPaperSize(context),
              ),
              _SettingsSwitchTile(
                title: 'Enable Email Receipts',
                subtitle: 'Send receipts via email',
                value: _settings.enableEmailReceipts,
                onChanged: (v) {
                  _settings.enableEmailReceipts = v;
                  setState(() {});
                },
              ),
            ],
          ),

          // Currency & Tax
          _SettingsSection(
            title: 'Currency & Tax',
            icon: Icons.attach_money_rounded,
            children: [
              _SettingsTile(
                title: 'Currency',
                subtitle: _settings.currency,
                onTap: () => _pickCurrency(context),
              ),
              _SettingsSwitchTile(
                title: 'Enable Tax',
                subtitle: 'Apply tax to sales',
                value: _settings.taxEnabled,
                onChanged: (v) {
                  _settings.taxEnabled = v;
                  setState(() {});
                },
              ),
              if (_settings.taxEnabled)
                _SettingsTile(
                  title: 'Tax Rate',
                  subtitle: '${(_settings.taxRate * 100).toStringAsFixed(0)}%',
                  onTap: () => _editText(
                    context,
                    'Tax Rate (%)',
                    '${(_settings.taxRate * 100).toStringAsFixed(0)}',
                    (v) {
                      final rate = double.tryParse(v);
                      if (rate != null) _settings.taxRate = rate / 100;
                      setState(() {});
                    },
                    keyboardType: TextInputType.number,
                  ),
                ),
            ],
          ),

          // Appearance
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette_rounded,
            children: [
              _SettingsSwitchTile(
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _settings.isDarkMode,
                onChanged: (v) {
                  _settings.isDarkMode = v;
                  setState(() {});
                },
              ),
            ],
          ),

          // Security
          _SettingsSection(
            title: 'Security',
            icon: Icons.security_rounded,
            children: [
              _SettingsSwitchTile(
                title: 'PIN Lock',
                subtitle: 'Require PIN to open app',
                value: _settings.isPinEnabled,
                onChanged: (v) async {
                  if (v) {
                    _setupPin(context);
                  } else {
                    await _settings.clearSecuredPin();
                    setState(() {});
                  }
                },
              ),
              if (_settings.isPinEnabled)
                _SettingsTile(
                  title: 'Change PIN',
                  onTap: () => _setupPin(context),
                ),
            ],
          ),

          // Inventory
          _SettingsSection(
            title: 'Inventory',
            icon: Icons.inventory_2_rounded,
            children: [
              _SettingsTile(
                title: 'Low Stock Alert Threshold',
                subtitle: '${_settings.lowStockThreshold} units',
                onTap: () => _editText(
                  context,
                  'Low Stock Threshold',
                  '${_settings.lowStockThreshold}',
                  (v) {
                    final t = int.tryParse(v);
                    if (t != null) _settings.lowStockThreshold = t;
                    setState(() {});
                  },
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),

          // Data & Backup
          _SettingsSection(
            title: 'Data & Backup',
            icon: Icons.backup_rounded,
            children: [
              _SettingsTile(
                title: 'Export Products (CSV)',
                subtitle: 'Export product list as CSV (openable in Excel)',
                onTap: () async {
                  final csv = await BackupRestoreHelper.generateProductsCsv();
                  final ts = DateTime.now().millisecondsSinceEpoch;
                  await BackupRestoreHelper.exportCsvToFile(
                    csv,
                    'ashop_products_$ts.csv',
                  );
                },
              ),
              _SettingsTile(
                title: 'Export Sales (CSV)',
                subtitle: 'Export sales and items as CSV',
                onTap: () async {
                  final csv = await BackupRestoreHelper.generateSalesCsv();
                  final ts = DateTime.now().millisecondsSinceEpoch;
                  await BackupRestoreHelper.exportCsvToFile(
                    csv,
                    'ashop_sales_$ts.csv',
                  );
                },
              ),
              _SettingsTile(
                title: 'Backup to File',
                subtitle: 'Export all data as JSON backup',
                onTap: () => _backupToFile(context),
              ),
              _SettingsTile(
                title: 'Restore from Backup',
                onTap: () => _restoreFromBackup(context),
              ),
              const Divider(height: 1, indent: 16, endIndent: 16),
              _SettingsTile(
                title: 'Factory Reset',
                subtitle: 'Delete all data and start fresh',
                onTap: () => _factoryReset(context),
              ),
            ],
          ),

          // About
          _SettingsSection(
            title: 'About',
            icon: Icons.info_rounded,
            children: [
              _SettingsTile(
                title: 'App Version',
                subtitle: 'v${AppConstants.appVersion}',
              ),
              _SettingsTile(
                title: 'Developer',
                subtitle: AppConstants.developerName,
              ),
              _SettingsTile(
                title: 'Contact',
                subtitle: AppConstants.developerPhone,
              ),
            ],
          ),

          // Footer
          const SizedBox(height: 28),
          Center(
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppConstants.appTagline,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.45),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Developed by ${AppConstants.developerName}',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
                Text(
                  AppConstants.developerPhone,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickShopLogo(BuildContext context) async {
    final picker = ImagePicker();
    final hasLogo =
        _settings.shopLogo != null && File(_settings.shopLogo!).existsSync();

    final source = await showDialog<dynamic>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Shop Logo'),
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt_rounded),
            title: const Text('Take Photo'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_rounded),
            title: const Text('Choose from Gallery'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
          if (hasLogo)
            ListTile(
              leading: const Icon(
                Icons.delete_rounded,
                color: AppTheme.dangerColor,
              ),
              title: const Text(
                'Remove Photo',
                style: TextStyle(color: AppTheme.dangerColor),
              ),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ],
      ),
    );

    if (source != null) {
      if (source == 'remove') {
        _settings.shopLogo = null;
        setState(() {});
      } else if (source is ImageSource) {
        final file = await picker.pickImage(source: source, maxWidth: 600);
        if (file != null) {
          _settings.shopLogo = file.path;
          setState(() {});
        }
      }
    }
  }

  void _backupToFile(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Generating backup...'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    try {
      await BackupRestoreHelper.backupToFile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup shared successfully!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _restoreFromBackup(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => const _RestoreFromBackupDialog(),
    );
  }

  void _editText(
    BuildContext context,
    String title,
    String currentValue,
    void Function(String) onSave, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => _EditTextDialog(
        title: title,
        currentValue: currentValue,
        onSave: onSave,
        keyboardType: keyboardType,
      ),
    );
  }

  void _pickCurrency(BuildContext context) {
    final currencies = AppConstants.currencies;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Currency'),
        children: [
          SizedBox(
            width: 320,
            height: currencies.length > 8 ? 400 : null,
            child: ListView(
              shrinkWrap: true,
              children: currencies
                  .map(
                    (c) => ListTile(
                      title: Text(
                        '${c['name']} (${c['symbol']})',
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(c['code']!),
                      trailing: _settings.currency == c['code']
                          ? const Icon(
                              Icons.check_rounded,
                              color: AppTheme.primaryColor,
                            )
                          : null,
                      onTap: () {
                        _settings.currency = c['code']!;
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _pickReceiptTemplate(BuildContext context) {
    const options = ['standard', 'modern', 'classic', 'compact'];
    const labels = ['Standard', 'Modern', 'Classic', 'Compact'];
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Receipt Template'),
        children: [
          ...List.generate(
            options.length,
            (i) => ListTile(
              title: Text(labels[i]),
              trailing: _settings.receiptTemplateStyle == options[i]
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppTheme.primaryColor,
                    )
                  : null,
              onTap: () {
                _settings.receiptTemplateStyle = options[i];
                setState(() {});
                Navigator.pop(ctx);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _pickPaperSize(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Select Paper Size'),
        children: [
          ListTile(
            title: const Text('58mm (Thermal)'),
            trailing: _settings.printerPaperSize == '58mm'
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              _settings.printerPaperSize = '58mm';
              setState(() {});
              Navigator.pop(ctx);
            },
          ),
          ListTile(
            title: const Text('80mm (Thermal)'),
            trailing: _settings.printerPaperSize == '80mm'
                ? const Icon(Icons.check_rounded, color: AppTheme.primaryColor)
                : null,
            onTap: () {
              _settings.printerPaperSize = '80mm';
              setState(() {});
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  void _factoryReset(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          'Factory Reset',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will permanently delete ALL data including products, sales, and settings.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'This action cannot be undone. Your app will be reset to factory state.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              if (!mounted) return;
              try {
                // Close all boxes so their files can be deleted from disk
                await Hive.close();

                await Future.wait([
                  Hive.deleteBoxFromDisk(AppConstants.productsBox),
                  Hive.deleteBoxFromDisk(AppConstants.salesBox),
                  Hive.deleteBoxFromDisk(AppConstants.settingsBox),
                  Hive.deleteBoxFromDisk(AppConstants.notesBox),
                ]);

                // Wipe PIN credentials and Hive encryption key
                await SecurityHelper.clearStoredPin();
                await SecurityHelper.clearHiveEncryptionKey();
                final newKey = await SecurityHelper.getHiveEncryptionKey();

                // Re-open fresh boxes with a new encryption key
                await Hive.openBox(AppConstants.settingsBox);
                await Hive.openBox<ProductModel>(
                  AppConstants.productsBox,
                  encryptionKey: newKey,
                );
                await Hive.openBox<SaleModel>(
                  AppConstants.salesBox,
                  encryptionKey: newKey,
                );
                // Notes box must also use the new encryption key
                await Hive.openBox<dynamic>(
                  AppConstants.notesBox,
                  encryptionKey: newKey,
                );
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to reset app. Please try again.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
                return;
              }
              if (!mounted) return;
              // Reload state
              context.read<ProductCubit>().loadProducts();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('App has been reset to factory state'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Reset Everything'),
          ),
        ],
      ),
    );
  }

  void _setupPin(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _SetupPinDialog(settings: _settings, onPinSet: () => setState(() {})),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Material(
          color: isDark ? AppTheme.darkCard : AppTheme.lightCard,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: Column(children: children),
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: onTap != null
          ? Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.25),
              size: 20,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitchTile({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      dense: true,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
      activeColor: AppTheme.primaryColor,
    );
  }
}

class _EditTextDialog extends StatefulWidget {
  final String title;
  final String currentValue;
  final void Function(String) onSave;
  final TextInputType keyboardType;

  const _EditTextDialog({
    required this.title,
    required this.currentValue,
    required this.onSave,
    required this.keyboardType,
  });

  @override
  State<_EditTextDialog> createState() => _EditTextDialogState();
}

class _EditTextDialogState extends State<_EditTextDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.currentValue);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.title,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _ctrl,
        keyboardType: widget.keyboardType,
        autofocus: true,
        decoration: InputDecoration(hintText: 'Enter ${widget.title}'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onSave(_ctrl.text.trim());
            Navigator.pop(context);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _RestoreFromBackupDialog extends StatefulWidget {
  const _RestoreFromBackupDialog();

  @override
  State<_RestoreFromBackupDialog> createState() =>
      _RestoreFromBackupDialogState();
}

class _RestoreFromBackupDialogState extends State<_RestoreFromBackupDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Restore from Backup',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'WARNING: Restoring will overwrite all current products, sales, and settings. This action cannot be undone.',
            style: TextStyle(
              color: AppTheme.dangerColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Paste backup JSON string here...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final data = _ctrl.text.trim();
            if (data.isEmpty) return;
            try {
              await BackupRestoreHelper.restoreFromBackupJson(data);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Backup restored successfully!'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                Navigator.pop(context);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Restore failed: ${e.toString()}'),
                    backgroundColor: AppTheme.dangerColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            }
          },
          child: const Text('Restore'),
        ),
      ],
    );
  }
}

class _SetupPinDialog extends StatefulWidget {
  final SettingsRepository settings;
  final VoidCallback onPinSet;

  const _SetupPinDialog({required this.settings, required this.onPinSet});

  @override
  State<_SetupPinDialog> createState() => _SetupPinDialogState();
}

class _SetupPinDialogState extends State<_SetupPinDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Set PIN',
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
      ),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        maxLength: 6,
        obscureText: true,
        autofocus: true,
        decoration: const InputDecoration(hintText: '4-6 digit PIN'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (_ctrl.text.length >= 4) {
              await widget.settings.setSecuredPin(_ctrl.text);
              if (context.mounted) {
                widget.onPinSet();
                Navigator.pop(context);
              }
            }
          },
          child: const Text('Set PIN'),
        ),
      ],
    );
  }
}
