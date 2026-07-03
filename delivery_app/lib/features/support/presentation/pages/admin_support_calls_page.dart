import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/calls/support_call_session.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';

class AdminSupportCallsPage extends ConsumerStatefulWidget {
  const AdminSupportCallsPage({super.key});

  @override
  ConsumerState<AdminSupportCallsPage> createState() =>
      _AdminSupportCallsPageState();
}

class _AdminSupportCallsPageState extends ConsumerState<AdminSupportCallsPage> {
  SupportCallSession? _session;
  final List<IncomingSupportCall> _incoming = [];
  String _status = '...';
  String? _activeCallId;

  @override
  void initState() {
    super.initState();
    _session = SupportCallSession(
      role: SupportCallRole.admin,
      onStatus: _setStatus,
      onIncomingCall: _addIncoming,
      onCallEnded: (_) {
        if (mounted) setState(() => _activeCallId = null);
      },
    );
    Future.microtask(() => _session?.connect());
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
  }

  void _addIncoming(IncomingSupportCall call) {
    if (!mounted) return;
    setState(() {
      _incoming.removeWhere((item) => item.callId == call.callId);
      _incoming.insert(0, call);
    });
  }

  Future<void> _accept(IncomingSupportCall call) async {
    setState(() {
      _activeCallId = call.callId;
      _incoming.removeWhere((item) => item.callId == call.callId);
    });
    await _session?.acceptCall(call.callId);
  }

  @override
  void dispose() {
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(isAr ? 'مكالمات المركز' : 'Appels du centre'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _activeCallId == null ? Icons.headset_mic : Icons.call,
                  color: AppColors.primary,
                  size: 34,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _status,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_activeCallId != null) ...[
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () async {
                await _session?.endCall();
                if (mounted) setState(() => _activeCallId = null);
              },
              icon: const Icon(Icons.call_end),
              label: Text(isAr ? 'إنهاء المكالمة' : 'Terminer l’appel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
          const SizedBox(height: 22),
          Text(
            isAr ? 'المكالمات الواردة' : 'Appels entrants',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_incoming.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 70),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_none,
                    size: 76,
                    color: AppColors.textSecondary.withValues(alpha: 0.35),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isAr
                        ? 'لا توجد مكالمات حاليا'
                        : 'Aucun appel pour le moment',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          else
            for (final call in _incoming)
              Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.person, color: Colors.white),
                  ),
                  title: Text(call.clientName),
                  subtitle: Text(
                    isAr ? 'يريد الاتصال بالمركز' : 'Appel entrant',
                  ),
                  trailing: ElevatedButton(
                    onPressed: _activeCallId == null
                        ? () => _accept(call)
                        : null,
                    child: Text(isAr ? 'قبول' : 'Accepter'),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
