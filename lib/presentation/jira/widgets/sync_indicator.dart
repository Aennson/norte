import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../domain/entities/outbox_operation.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../shared/theme/norte_colors.dart';
import '../../shared/theme/norte_spacing.dart';
import '../../shared/theme/norte_typography.dart';
import '../jira_providers.dart';

/// What the outbox is holding, made visible.
///
/// Offline-first only works if the user can tell the difference between "done"
/// and "will be done". This strip is that difference: while operations are
/// queued it says so in `info`; once some have run out of attempts it turns
/// `warning` and offers the manual retry the sprint requires.
///
/// It renders nothing when the queue is empty — the ordinary case deserves no
/// furniture. It is driven by `watchUnsettled`, so it updates from the
/// database rather than from a poll.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<OutboxOperation> operations =
        ref.watch(unsettledOperationsProvider).valueOrNull ??
        const <OutboxOperation>[];
    if (operations.isEmpty) return const SizedBox.shrink();

    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);

    final List<OutboxOperation> failed = operations
        .where((OutboxOperation o) => o.state == OutboxOperationState.failed)
        .toList();
    final bool hasFailures = failed.isNotEmpty;

    final Color tone = hasFailures ? colors.warning : colors.info;
    final String message = hasFailures
        ? l10n.jiraSyncFailed(failed.length)
        : l10n.jiraSyncPending(operations.length);

    return Padding(
      padding: const EdgeInsets.only(bottom: NorteSpacing.md),
      child: Row(
        children: <Widget>[
          Icon(
            hasFailures ? LucideIcons.triangleAlert : LucideIcons.refreshCw,
            size: 16,
            color: tone,
          ),
          const SizedBox(width: NorteSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: NorteTypography.mono.copyWith(color: tone),
            ),
          ),
          if (hasFailures)
            TextButton(
              onPressed: () async {
                final OutboxRetry retry = ref.read(outboxRetryProvider);
                for (final OutboxOperation operation in failed) {
                  await retry(operation.operationId);
                }
                await ref.read(outboxDispatchProvider)();
              },
              child: Text(
                l10n.jiraSyncRetryAction,
                style: NorteTypography.monoSmall.copyWith(color: colors.accent),
              ),
            ),
        ],
      ),
    );
  }
}
