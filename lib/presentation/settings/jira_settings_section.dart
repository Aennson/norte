import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/jira_credentials.dart';
import '../../l10n/generated/app_localizations.dart';
import '../jira/jira_providers.dart';
import '../shared/theme/norte_colors.dart';
import '../shared/theme/norte_spacing.dart';
import '../shared/theme/norte_typography.dart';
import '../shared/widgets/norte_button.dart';
import '../shared/widgets/norte_card.dart';
import '../shared/widgets/norte_chip.dart';
import '../shared/widgets/norte_text_field.dart';

/// Where the user connects a Jira site.
///
/// **BR-08 shapes this form.** The token field is masked and excluded from
/// autofill; the stored token is never read back into the field — a connected
/// site shows only the account e-mail, because there is no legitimate reason
/// for the app to display a secret it already holds. Changing the connection
/// means typing a token again, which is the correct trade.
class JiraSettingsSection extends ConsumerStatefulWidget {
  const JiraSettingsSection({super.key});

  /// Keys the tests and the E2E suite drive this form by.
  static const Key siteUrlFieldKey = Key('jira.siteUrl');
  static const Key emailFieldKey = Key('jira.email');
  static const Key apiTokenFieldKey = Key('jira.apiToken');
  static const Key connectButtonKey = Key('jira.connect');
  static const Key disconnectButtonKey = Key('jira.disconnect');
  static const Key cloudChipKey = Key('jira.deployment.cloud');
  static const Key dataCenterChipKey = Key('jira.deployment.dataCenter');

  @override
  ConsumerState<JiraSettingsSection> createState() =>
      _JiraSettingsSectionState();
}

class _JiraSettingsSectionState extends ConsumerState<JiraSettingsSection> {
  final TextEditingController _siteUrl = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _apiToken = TextEditingController();

  bool _showIncomplete = false;
  JiraDeployment _deployment = JiraDeployment.cloud;

  @override
  void dispose() {
    _siteUrl.dispose();
    _email.dispose();
    _apiToken.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final JiraCredentials credentials = JiraCredentials(
      siteUrl: _siteUrl.text.trim(),
      email: _email.text.trim(),
      apiToken: _apiToken.text.trim(),
      deployment: _deployment,
    );
    if (!credentials.isComplete) {
      setState(() => _showIncomplete = true);
      return;
    }

    await ref.read(jiraCredentialStoreProvider).write(credentials);
    // The token leaves the widget tree the moment it is stored.
    _apiToken.clear();
    setState(() => _showIncomplete = false);
    ref.invalidate(jiraCredentialsProvider);
  }

  Future<void> _disconnect() async {
    await ref.read(jiraCredentialStoreProvider).clear();
    _siteUrl.clear();
    _email.clear();
    _apiToken.clear();
    setState(() => _deployment = JiraDeployment.cloud);
    ref.invalidate(jiraCredentialsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final NorteColors colors = NorteColors.of(context);
    final JiraCredentials? stored = ref
        .watch(jiraCredentialsProvider)
        .valueOrNull;

    return NorteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.jiraSectionTitle,
            style: NorteTypography.title.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: NorteSpacing.xs),
          Text(
            l10n.jiraSectionDescription,
            style: NorteTypography.body.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: NorteSpacing.md),
          Text(
            stored == null
                ? l10n.jiraNotConnected
                : l10n.jiraConnectedAs(stored.accountLabel),
            style: NorteTypography.mono.copyWith(
              color: stored == null ? colors.textMuted : colors.success,
            ),
          ),
          const SizedBox(height: NorteSpacing.lg),
          Text(
            l10n.jiraFieldDeployment,
            style: NorteTypography.caption.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: NorteSpacing.sm),
          Wrap(
            spacing: NorteSpacing.sm,
            children: <Widget>[
              NorteChip(
                key: JiraSettingsSection.cloudChipKey,
                label: l10n.jiraDeploymentCloud,
                isSelected: _deployment == JiraDeployment.cloud,
                onSelected: () =>
                    setState(() => _deployment = JiraDeployment.cloud),
              ),
              NorteChip(
                key: JiraSettingsSection.dataCenterChipKey,
                label: l10n.jiraDeploymentDataCenter,
                isSelected: _deployment == JiraDeployment.dataCenter,
                onSelected: () =>
                    setState(() => _deployment = JiraDeployment.dataCenter),
              ),
            ],
          ),
          const SizedBox(height: NorteSpacing.md),
          NorteTextField(
            key: JiraSettingsSection.siteUrlFieldKey,
            label: l10n.jiraFieldSiteUrl,
            hint: l10n.jiraFieldSiteUrlHint,
            controller: _siteUrl,
          ),
          // A Data Center personal access token authenticates on its own, so
          // asking for an e-mail there would be asking for something the
          // request will not carry (DEC-012).
          if (_deployment.needsEmail) ...<Widget>[
            const SizedBox(height: NorteSpacing.md),
            NorteTextField(
              key: JiraSettingsSection.emailFieldKey,
              label: l10n.jiraFieldEmail,
              controller: _email,
            ),
          ],
          const SizedBox(height: NorteSpacing.md),
          NorteTextField(
            key: JiraSettingsSection.apiTokenFieldKey,
            label: _deployment.needsEmail
                ? l10n.jiraFieldApiToken
                : l10n.jiraFieldApiTokenDataCenter,
            controller: _apiToken,
            isSecret: true,
            errorText: _showIncomplete ? l10n.jiraCredentialsIncomplete : null,
          ),
          const SizedBox(height: NorteSpacing.lg),
          Wrap(
            spacing: NorteSpacing.sm,
            runSpacing: NorteSpacing.sm,
            children: <Widget>[
              NorteButton(
                key: JiraSettingsSection.connectButtonKey,
                label: l10n.jiraConnectAction,
                onPressed: _connect,
              ),
              if (stored != null)
                NorteButton(
                  key: JiraSettingsSection.disconnectButtonKey,
                  label: l10n.jiraDisconnectAction,
                  onPressed: _disconnect,
                  variant: NorteButtonVariant.secondary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
