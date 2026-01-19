import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:reminder/core/router/app_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/location_monitor_service.dart';
import '../../domain/entities/reminder.dart';
import '../bloc/reminder_bloc.dart';
import '../bloc/reminder_event.dart';
import '../bloc/reminder_state.dart';

class ReminderListPage extends StatefulWidget {
  const ReminderListPage({super.key});

  @override
  State<ReminderListPage> createState() => _ReminderListPageState();
}

class _ReminderListPageState extends State<ReminderListPage> {
  late final LocationMonitorService _locationMonitor;

  @override
  void initState() {
    super.initState();
    _locationMonitor = getIt<LocationMonitorService>();
    _locationMonitor.start();
    context.read<ReminderBloc>().add(const ReminderLoadRequested());
  }

  @override
  void dispose() {
    _locationMonitor.stop();
    super.dispose();
  }

  Future<void> _refresh() async {
    context.read<ReminderBloc>().add(const ReminderLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReminderBloc, ReminderState>(
      listener: (context, state) {
        _locationMonitor.updateReminders(state.reminders);
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Reminders'),
            centerTitle: false,
            actions: [
              IconButton(
                onPressed: () {
                  context.read<ReminderBloc>().add(const ReminderLoadRequested());
                },
                icon: const Icon(Icons.refresh_rounded),
              ),
            ],
          ),
          body: SafeArea(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (state.status) {
                  ReminderStatus.loading => const Center(
                      key: ValueKey('loading'),
                      child: CircularProgressIndicator(),
                    ),
                  ReminderStatus.failure => _FailureState(
                      key: const ValueKey('failure'),
                      message: state.errorMessage,
                      onRetry: () {
                        context
                            .read<ReminderBloc>()
                            .add(const ReminderLoadRequested());
                      },
                    ),
                  _ => _ReminderList(
                      key: const ValueKey('list'),
                      reminders: state.reminders,
                      onCreate: () async {
                        final bloc = context.read<ReminderBloc>();
                        final created = await context.push<bool>(AppPages.remindersNew);
                        if (!mounted) return;
                        if (created == true) {
                          bloc.add(const ReminderLoadRequested());
                        }
                      },
                    ),
                },
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              final bloc = context.read<ReminderBloc>();
              final result = await context.push<bool>(AppPages.remindersNew);
              if (!mounted) return;
              if (result == true) {
                bloc.add(const ReminderLoadRequested());
              }
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('New reminder'),
          ),
        );
      },
    );
  }
}

class _ReminderList extends StatelessWidget {
  const _ReminderList({super.key, required this.reminders, required this.onCreate});

  final List<Reminder> reminders;
  final Future<void> Function() onCreate;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 72,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No reminders yet',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first reminder to stay on top of tasks.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
      itemCount: reminders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reminder = reminders[index];

        return Dismissible(
          key: ValueKey(reminder.id),
          direction: DismissDirection.endToStart,
          background: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.error,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(
                  Icons.delete_rounded,
                  color: Theme.of(context).colorScheme.onError,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delete',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onError,
                      ),
                ),
              ],
            ),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Delete reminder?'),
                      content: const Text('This cannot be undone.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Delete'),
                        ),
                      ],
                    );
                  },
                ) ??
                false;
          },
          onDismissed: (_) {
            context
                .read<ReminderBloc>()
                .add(ReminderDeleteRequested(reminder.id));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Reminder deleted'),
                behavior: SnackBarBehavior.floating,
                width: 360,
              ),
            );
          },
          child: _ReminderTile(reminder: reminder),
        );
      },
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueAt = reminder.dueAt;
    final isLocation = reminder.type == ReminderType.location;

    final dateLabel = dueAt == null
        ? null
        : DateFormat('EEE, d MMM · HH:mm').format(dueAt.toLocal());

    final locationLabel = reminder.locationLabel?.trim();
    final locationChipLabel = (locationLabel != null && locationLabel.isNotEmpty)
        ? locationLabel
        : ((reminder.latitude != null && reminder.longitude != null)
            ? '${reminder.latitude!.toStringAsFixed(5)}, ${reminder.longitude!.toStringAsFixed(5)}'
            : null);

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      decoration: reminder.isDone ? TextDecoration.lineThrough : null,
      color: reminder.isDone
          ? theme.colorScheme.onSurfaceVariant
          : theme.colorScheme.onSurface,
    );

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final updated = await context.push<bool>(
            AppPages.remindersEdit,
            extra: reminder,
          );
          if (!context.mounted) return;
          if (updated == true) {
            context.read<ReminderBloc>().add(const ReminderLoadRequested());
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Checkbox.adaptive(
                  value: reminder.isDone,
                  onChanged: (_) {
                    context
                        .read<ReminderBloc>()
                        .add(ReminderToggleDoneRequested(reminder.id));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reminder.title.trim().isEmpty
                          ? '(Untitled reminder)'
                          : reminder.title,
                      style: titleStyle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (reminder.note.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reminder.note,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          decoration:
                              reminder.isDone ? TextDecoration.lineThrough : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (dateLabel != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _InfoChip(
                          label: dateLabel,
                          isDone: reminder.isDone,
                          icon: Icons.schedule_rounded,
                          kind: _ChipKind.primary,
                        ),
                      ),
                    ],
                    if (isLocation && locationChipLabel != null) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _InfoChip(
                          label: locationChipLabel,
                          isDone: reminder.isDone,
                          icon: Icons.place_rounded,
                          kind: _ChipKind.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ChipKind { primary, secondary }

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.isDone,
    required this.icon,
    required this.kind,
  });

  final String label;
  final bool isDone;
  final IconData icon;
  final _ChipKind kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bgColor = isDone
        ? theme.colorScheme.surfaceContainerHigh
        : (kind == _ChipKind.primary
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.secondaryContainer);

    final fgColor = isDone
        ? theme.colorScheme.onSurfaceVariant
        : (kind == _ChipKind.primary
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSecondaryContainer);

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: fgColor,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelMedium?.copyWith(
                color: fgColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FailureState extends StatelessWidget {
  const _FailureState({super.key, required this.message, required this.onRetry});

  final String? message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 12),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message ?? 'Please try again.',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
