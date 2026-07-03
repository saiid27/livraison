import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/calls/support_call_session.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';

class SupportCallPage extends ConsumerStatefulWidget {
  const SupportCallPage({super.key});

  @override
  ConsumerState<SupportCallPage> createState() => _SupportCallPageState();
}

class _SupportCallPageState extends ConsumerState<SupportCallPage> {
  SupportCallSession? _session;
  String _status = '...';
  bool _calling = false;

  @override
  void initState() {
    super.initState();
    _session = SupportCallSession(
      role: SupportCallRole.client,
      onStatus: _setStatus,
      onCallEnded: (_) {
        if (mounted) setState(() => _calling = false);
      },
    );
    Future.microtask(_start);
  }

  Future<void> _start() async {
    setState(() => _calling = true);
    await _session?.startClientCall();
  }

  void _setStatus(String value) {
    if (mounted) setState(() => _status = value);
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
        title: Text(isAr ? 'اتصال بالمركز' : 'Appel au centre'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/client'),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 54,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Icon(
                  _calling ? Icons.call : Icons.call_end,
                  size: 54,
                  color: _calling ? AppColors.primary : AppColors.error,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _calling
                    ? (isAr ? 'مكالمة صوتية مع المركز' : 'Appel audio')
                    : (isAr ? 'المكالمة غير نشطة' : 'Appel inactif'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 34),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _calling
                      ? () async {
                          await _session?.endCall();
                          if (mounted) setState(() => _calling = false);
                        }
                      : _start,
                  icon: Icon(_calling ? Icons.call_end : Icons.call),
                  label: Text(
                    _calling
                        ? (isAr ? 'إنهاء المكالمة' : 'Terminer')
                        : (isAr ? 'الاتصال مرة أخرى' : 'Rappeler'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _calling
                        ? AppColors.error
                        : AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
