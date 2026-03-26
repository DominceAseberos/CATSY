import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:catsy_pos/config/theme/app_colors.dart';
import 'package:catsy_pos/domain/enums/reservation_status.dart';
import 'package:catsy_pos/domain/entities/reservation.dart';
import 'package:catsy_pos/presentation/reservation/providers/reservation_provider.dart';
import 'package:catsy_pos/presentation/reservation/widgets/reservation_card.dart';
import 'package:intl/intl.dart';
import 'package:catsy_pos/presentation/common_widgets/empty_state_widget.dart';
import 'package:catsy_pos/presentation/common_widgets/shimmer_loading.dart';

class ReservationScreen extends ConsumerWidget {
  const ReservationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservationsAsync = ref.watch(filteredReservationsProvider);
    final selectedFilter = ref.watch(reservationFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            // TODO: Implement create reservation dialog in future or next step if needed
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => const CreateReservationDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: selectedFilter == null,
                  onSelected: () => ref
                      .read(reservationFilterProvider.notifier)
                      .setFilter(null),
                ),
                const SizedBox(width: 8),
                ...ReservationStatus.values.map((status) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: status.label,
                      isSelected: selectedFilter == status,
                      onSelected: () => ref
                          .read(reservationFilterProvider.notifier)
                          .setFilter(status),
                    ),
                  );
                }),
              ],
            ),
          ),

          const Divider(),

          // List
          Expanded(
            child: reservationsAsync.when(
              data: (reservations) {
                if (reservations.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_busy,
                    title: selectedFilter == null
                        ? 'No reservations found'
                        : 'No ${selectedFilter.label.toLowerCase()} reservations',
                    subtitle: 'New reservations will appear here',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    // In local-first, this might trigger a remote sync check in Phase 12.
                    // For now it just re-reads the stream which is auto-updating anyway.
                    return Future.delayed(const Duration(milliseconds: 500));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: reservations.length,
                    itemBuilder: (context, index) {
                      final reservation = reservations[index];
                      return ReservationCard(reservation: reservation);
                    },
                  ),
                );
              },
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                itemBuilder: (context, index) => const ShimmerListTile(),
              ),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppColors.primary : AppColors.border,
        ),
      ),
    );
  }
}

class CreateReservationDialog extends ConsumerStatefulWidget {
  const CreateReservationDialog({super.key});

  @override
  ConsumerState<CreateReservationDialog> createState() =>
      _CreateReservationDialogState();
}

class _CreateReservationDialogState
    extends ConsumerState<CreateReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  int _partySize = 2;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final date = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final reservation = Reservation(
        id: '', // Repo generates
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        partySize: _partySize,
        reservationDate: date,
        reservationTime: date,
        status: ReservationStatus.pending,
        notes: _notesController.text,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref
          .read(reservationControllerProvider.notifier)
          .createReservation(reservation);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation created successfully!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Reservation'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Customer Name'),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _partySize,
                      decoration: const InputDecoration(
                        labelText: 'Party Size',
                      ),
                      items: List.generate(20, (i) => i + 1)
                          .map(
                            (i) => DropdownMenuItem(
                              value: i,
                              child: Text('$i People'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _partySize = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text(DateFormat('yyyy-MM-dd').format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
              ),
              ListTile(
                title: Text(_selectedTime.format(context)),
                trailing: const Icon(Icons.access_time),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                },
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('CANCEL'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('SAVE')),
      ],
    );
  }
}
