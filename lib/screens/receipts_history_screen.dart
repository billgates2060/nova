import 'package:flutter/material.dart';
import 'dart:io';
import '../services/print_service.dart';
import '../widgets/responsive_widgets.dart';
import 'package:intl/intl.dart';
import 'package:nova/l10n/app_localizations.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cross_file/cross_file.dart';

class ReceiptsHistoryScreen extends StatefulWidget {
  const ReceiptsHistoryScreen({super.key});

  @override
  State<ReceiptsHistoryScreen> createState() => _ReceiptsHistoryScreenState();
}

class _ReceiptsHistoryScreenState extends State<ReceiptsHistoryScreen> {
  List<File> _receipts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadReceipts();
  }

  Future<void> _loadReceipts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final receipts = await PrintService.getSavedReceipts();
      setState(() {
        _receipts = receipts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingReceipts}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<File> get _filteredReceipts {
    if (_searchQuery.isEmpty) {
      return _receipts;
    }

    return _receipts.where((file) {
      final fileName = file.path.split('/').last.toLowerCase();
      return fileName.contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getReceiptDisplayName(File file) {
    final fileName = file.path.split('/').last;
    final nameWithoutExtension = fileName.replaceAll('.pdf', '');

    // Extrair informações do nome do arquivo
    final parts = nameWithoutExtension.split('_');
    if (parts.length >= 2) {
      final receiptNumber = parts[1];
      final timestamp = parts.length > 2 ? parts[2] : '';

      if (timestamp.isNotEmpty) {
        try {
          final date = DateTime.fromMillisecondsSinceEpoch(
            int.parse(timestamp),
          );
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);
          return '${AppLocalizations.of(context)!.receiptPrefix} #$receiptNumber - $formattedDate';
        } catch (e) {
          return '${AppLocalizations.of(context)!.receiptPrefix} #$receiptNumber';
        }
      }
      return '${AppLocalizations.of(context)!.receiptPrefix} #$receiptNumber';
    }

    return fileName;
  }

  String _getReceiptDate(File file) {
    final fileName = file.path.split('/').last;
    final nameWithoutExtension = fileName.replaceAll('.pdf', '');
    final parts = nameWithoutExtension.split('_');

    if (parts.length > 2) {
      final timestamp = parts[2];
      try {
        final date = DateTime.fromMillisecondsSinceEpoch(int.parse(timestamp));
        return DateFormat('dd/MM/yyyy HH:mm').format(date);
      } catch (e) {
        return DateFormat('dd/MM/yyyy').format(file.lastModifiedSync());
      }
    }

    return DateFormat('dd/MM/yyyy').format(file.lastModifiedSync());
  }

  Future<void> _deleteReceipt(File file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmDeletion),
        content: Text(AppLocalizations.of(context)!.confirmDeleteProductPrompt),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)!.delete,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await PrintService.deleteReceipt(file.path);
        await _loadReceipts();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.deletedSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.loadErrorPrefix} $e',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _shareReceipt(File file) async {
    try {
      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorProcessingReceipt} $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ResponsiveAppBar(
        title: AppLocalizations.of(context)!.receiptsHistory,
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReceipts,
            tooltip: AppLocalizations.of(context)!.updateTooltip,
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de pesquisa
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.searchTooltip,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Lista de recibos
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReceipts.isEmpty
                ? _buildEmptyState()
                : ResponsiveList(
                    children: _filteredReceipts.map((file) {
                      return _buildReceiptCard(file);
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty
                ? AppLocalizations.of(context)!.noSales
                : AppLocalizations.of(context)!.noSales,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? AppLocalizations.of(context)!.receipts
                : AppLocalizations.of(context)!.filters,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptCard(File file) {
    return ResponsiveCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.purple[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.receipt_long,
                  color: Colors.purple[700],
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getReceiptDisplayName(file),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getReceiptDate(file),
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tamanho: ${_formatFileSize(file.lengthSync())}',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'share':
                      _shareReceipt(file);
                      break;
                    case 'delete':
                      _deleteReceipt(file);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, color: Colors.blue),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.share),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.delete),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareReceipt(file),
                  icon: const Icon(Icons.share),
                  label: Text(AppLocalizations.of(context)!.share),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.blue),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteReceipt(file),
                  icon: const Icon(Icons.delete),
                  label: Text(AppLocalizations.of(context)!.delete),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
