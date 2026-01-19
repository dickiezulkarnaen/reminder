import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:reminder/features/reminders/presentation/bloc/reminder_state.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import 'location_picker_page.dart';

class ReminderFormPage extends StatefulWidget {
  const ReminderFormPage({super.key, this.existing});

  final Reminder? existing;

  @override
  State<ReminderFormPage> createState() => _ReminderFormPageState();
}

class _ReminderFormPageState extends State<ReminderFormPage> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late final TextEditingController _locationLabelController;
  final _formKey = GlobalKey<FormState>();

  ReminderType _type = ReminderType.time;
  DateTime? _dueAt;
  LocationSelection? _location;

  void _syncFromExisting(Reminder? existing) {
    final hasLocation =
        existing?.latitude != null && existing?.longitude != null;
    final hasDueAt = existing?.dueAt != null;

    final existingType = existing?.type;
    var nextType =
        existingType ?? (hasLocation ? ReminderType.location : ReminderType.time);

    if (nextType == ReminderType.location && !hasLocation) {
      nextType = ReminderType.time;
    }

    if (nextType == ReminderType.time && !hasDueAt && hasLocation && existingType == null) {
      nextType = ReminderType.location;
    }

    _type = nextType;
    _dueAt = _type == ReminderType.time ? existing?.dueAt : null;
    _location = (_type == ReminderType.location && hasLocation)
        ? LocationSelection(
            latitude: existing!.latitude!,
            longitude: existing.longitude!,
            label: existing.locationLabel,
          )
        : null;

    final nextLabel = existing?.locationLabel ?? '';
    if (_locationLabelController.text != nextLabel) {
      _locationLabelController.text = nextLabel;
    }
  }

  Future<TimeOfDay?> _showScrollTimePicker(TimeOfDay initialTime) async {
    final initialDateTime = DateTime(
      2000,
      1,
      1,
      initialTime.hour,
      initialTime.minute,
    );

    DateTime selected = initialDateTime;

    final result = await showModalBottomSheet<DateTime>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 320,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(selected),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.time,
                    initialDateTime: initialDateTime,
                    use24hFormat: MediaQuery.of(context).alwaysUse24HourFormat,
                    onDateTimeChanged: (value) {
                      selected = value;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result == null) return null;
    return TimeOfDay(hour: result.hour, minute: result.minute);
  }

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _titleController = TextEditingController(text: existing?.title ?? '');
    _noteController = TextEditingController(text: existing?.note ?? '');

    _locationLabelController = TextEditingController(
      text: existing?.locationLabel ?? '',
    );
    _syncFromExisting(existing);
  }

  @override
  void didUpdateWidget(covariant ReminderFormPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final prevId = oldWidget.existing?.id;
    final nextId = widget.existing?.id;
    if (prevId == nextId) return;
    _syncFromExisting(widget.existing);
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    _locationLabelController.dispose();
    super.dispose();
  }

  Future<void> _pickLocation() async {
    final selected = await context.push<LocationSelection>(
      AppPages.locationPicker,
      extra: _location ?? LocationSelection.def,
    );
    if (!mounted) return;
    if (selected == null) return;
    setState(() {
      _location = selected;
      if ((_locationLabelController.text).trim().isEmpty && selected.label != null) {
        _locationLabelController.text = selected.label!;
      } else {
        context.read<ReminderBloc>().add(
          ReminderLocationNameRequested(
            selected.latitude,
            selected.longitude,
            const String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
          ),
        );
      }
    });
  }

  Future<void> _pickDueAt() async {
    final now = DateTime.now();

    final initial = _dueAt ?? now.add(const Duration(hours: 1));

    final date = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 10),
      initialDate: initial,
    );
    if (date == null) return;

    if (!mounted) return;

    final time = await _showScrollTimePicker(TimeOfDay.fromDateTime(initial));
    if (time == null) return;

    setState(() {
      _dueAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  void _clearDueAt() {
    setState(() {
      _dueAt = null;
    });
  }

  void _clearPickedLocation() {
    setState(() {
      _location = null;
      _locationLabelController.clear();
    });
  }

  void _save() {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    if (_type == ReminderType.location && _location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please pick a location.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final existing = widget.existing;

    final title = _titleController.text.trim();
    final note = _noteController.text.trim();
    final locationLabel = _locationLabelController.text.trim();

    final location = _location;
    final latitude = _type == ReminderType.location ? location?.latitude : null;
    final longitude = _type == ReminderType.location ? location?.longitude : null;

    final reminder = Reminder(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      note: note,
      type: _type,
      dueAt: _type == ReminderType.time ? _dueAt : null,
      latitude: latitude,
      longitude: longitude,
      locationLabel: _type == ReminderType.location
          ? (locationLabel.isEmpty ? location?.label : locationLabel)
          : null,
      isDone: existing?.isDone ?? false,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );

    context.read<ReminderBloc>().add(ReminderUpsertRequested(reminder));
    context.pop(true);
  }

  String? _validateTitle(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Title is required';
    return null;
  }

  Widget _buildHeader(ThemeData theme, {required bool isEdit}) {
    return Text(
      isEdit ? 'Update your reminder' : 'Create a reminder',
      style: theme.textTheme.titleLarge,
    );
  }

  Widget _buildTypePicker() {
    return DropdownButtonFormField<ReminderType>(
      value: _type,
      decoration: const InputDecoration(
        labelText: 'Reminder type',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.tune_rounded),
      ),
      items: const [
        DropdownMenuItem(
          value: ReminderType.time,
          child: Text('Time'),
        ),
        DropdownMenuItem(
          value: ReminderType.location,
          child: Text('Location'),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          _type = value;
        });
      },
    );
  }

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      textInputAction: TextInputAction.next,
      validator: _validateTitle,
      decoration: const InputDecoration(
        labelText: 'Title',
        hintText: 'e.g. Pay electricity bill',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.edit_rounded),
      ),
    );
  }

  Widget _buildNoteField() {
    return TextFormField(
      controller: _noteController,
      minLines: 3,
      maxLines: 6,
      decoration: const InputDecoration(
        labelText: 'Note',
        hintText: 'Optional details…',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes_rounded),
      ),
    );
  }

  Widget _buildTimeSection(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schedule_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Schedule',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _pickDueAt,
                  child: Text(_dueAt == null ? 'Pick' : 'Change'),
                ),
                if (_dueAt != null)
                  IconButton(
                    onPressed: _clearDueAt,
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChip(
                  selected: _dueAt != null,
                  onSelected: (_) {
                    _pickDueAt();
                  },
                  label: Text(
                    _dueAt == null
                        ? 'No due date'
                        : MaterialLocalizations.of(context)
                            .formatFullDate(_dueAt!.toLocal()),
                  ),
                ),
                if (_dueAt != null)
                  FilterChip(
                    selected: true,
                    onSelected: (_) {
                      _pickDueAt();
                    },
                    label: Text(
                      MaterialLocalizations.of(context).formatTimeOfDay(
                        TimeOfDay.fromDateTime(_dueAt!),
                      ),
                    ),
                  ),
                if (_dueAt != null)
                  ActionChip(
                    onPressed: _clearDueAt,
                    label: const Text('Clear'),
                  ),
                if (_dueAt == null)
                  Text(
                    'Add a due date to get a notification.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    final location = _location;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.place_rounded),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Location',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                TextButton(
                  onPressed: _pickLocation,
                  child: Text(location == null ? 'Pick' : 'Change'),
                ),
                if (location != null)
                  IconButton(
                    onPressed: () {
                      _clearPickedLocation();
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (location != null)
              Text(
                '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Text(
                'Pick a location to get a notification when you arrive nearby.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            const SizedBox(height: 12),
            BlocListener<ReminderBloc, ReminderState>(
              listenWhen: (prev, curr) =>
                  prev.location?.label != curr.location?.label,
              listener: (ctx, state) {
                log('ReminderForm location label changed: ${state.location?.label}');
                final nextText = state.location?.label ?? '';
                if (_locationLabelController.text != nextText) {
                  _locationLabelController.value =
                      _locationLabelController.value.copyWith(
                    text: nextText,
                    selection: TextSelection.collapsed(
                      offset: nextText.length,
                    ),
                    composing: TextRange.empty,
                  );
                }
              },
              child: TextFormField(
                controller: _locationLabelController,
                decoration: const InputDecoration(
                  labelText: 'Location label',
                  hintText: 'Optional',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label_rounded),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatedFooter(ThemeData theme) {
    return Text(
      'Created ${MaterialLocalizations.of(context).formatFullDate(widget.existing!.createdAt.toLocal())}',
      style: theme.textTheme.bodySmall
          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit reminder' : 'New reminder'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            children: [
              _buildHeader(theme, isEdit: isEdit),
              const SizedBox(height: 12),
              _buildTypePicker(),
              const SizedBox(height: 12),
              _buildTitleField(),
              const SizedBox(height: 12),
              _buildNoteField(),
              const SizedBox(height: 16),
              if (_type == ReminderType.time)
                _buildTimeSection(theme)
              else
                _buildLocationSection(theme),
              const SizedBox(height: 16),
              if (isEdit)
                _buildCreatedFooter(theme),
              const SizedBox(height: 90),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _save,
              icon: Icon(isEdit ? Icons.check_rounded : Icons.add_rounded),
              label: Text(isEdit ? 'Save changes' : 'Create reminder'),
            ),
          ),
        ),
      ),
    );
  }
}
