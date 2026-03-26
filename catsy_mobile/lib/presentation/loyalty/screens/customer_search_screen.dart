import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:go_router/go_router.dart'; // Unused

import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/domain/entities/customer.dart';
import 'package:catsy_pos/data/local/providers.dart';
import 'package:catsy_pos/core/utils/debounce.dart';

class CustomerSearchScreen extends ConsumerStatefulWidget {
  const CustomerSearchScreen({super.key});

  @override
  ConsumerState<CustomerSearchScreen> createState() =>
      _CustomerSearchScreenState();
}

class _CustomerSearchScreenState extends ConsumerState<CustomerSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Customer> _searchResults = [];
  bool _isLoading = false;
  final _debounce = Debounce(milliseconds: 500);

  @override
  void dispose() {
    _searchController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isLoading = true);

    // Use the repository via provider
    final result = await ref
        .read(customerRepositoryProvider)
        .searchCustomers(query);

    if (mounted) {
      setState(() {
        _isLoading = false;
        result.fold(
          (failure) =>
              _searchResults = [], // Handle error gracefully or show snackbar
          (customers) => _searchResults = customers,
        );
      });
    }
  }

  void _onCustomerSelected(Customer customer) {
    // Return the selected customer to the caller (usually integration flow)
    // Or navigate to result screen if acting standalone
    Navigator.of(context).pop(customer);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Customer')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      ),
              ),
              onChanged: (value) => _debounce.run(() => _performSearch(value)),
            ),
          ),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(
                    child: Text(
                      _searchController.text.isEmpty
                          ? 'Enter search term'
                          : 'No customers found',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.separated(
                    itemCount: _searchResults.length,
                    separatorBuilder: (_, _) => const Divider(),
                    itemBuilder: (context, index) {
                      final customer = _searchResults[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          customer.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text('${customer.email}\n${customer.phone}'),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.stars,
                              color: Colors.orange,
                              size: 16,
                            ),
                            Text(
                              '${customer.totalStamps} stamps',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => _onCustomerSelected(customer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
