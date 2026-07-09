import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';

class PublicInfoPage extends ConsumerWidget {
  const PublicInfoPage({super.key, required this.type});

  final PublicInfoType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final content = _content(isAr);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(content.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(content.icon, size: 52, color: AppColors.primary),
              const SizedBox(height: 18),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                content.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _PublicInfoContent _content(bool isAr) {
    switch (type) {
      case PublicInfoType.about:
        return _PublicInfoContent(
          icon: Icons.info_outline,
          title: isAr ? 'من نحن' : 'À propos',
          body: isAr
              ? 'مايحصر منصة موريتانية للخدمات السريعة، صممت لتسهيل الحركة اليومية بين العملاء، الكباتن، المندوبين، والتجار.\n\n'
                    'من خلال التطبيق يمكنك طلب توصيل طرد من نقطة إلى أخرى، أو طلب كابتن لمشوارك داخل المدينة، مع إمكانية متابعة حالة الطلب خطوة بخطوة حتى الوصول.\n\n'
                    'نوفر كذلك مساحة للتجار لإدارة منتجاتهم وطلباتهم، وخدمة تواصل مع المركز للمساعدة عند الحاجة. هدفنا أن تكون خدمات التوصيل والمشاوير أوضح، أسرع، وأسهل للجميع.'
              : 'Mayahsar est une plateforme mauritanienne de services rapides, conçue pour faciliter le quotidien des clients, capitaines, livreurs et commerçants.\n\n'
                    'Depuis l’application, vous pouvez demander la livraison d’un colis d’un point à un autre, ou commander une course avec un capitaine, avec un suivi simple de la demande jusqu’à son arrivée.\n\n'
                    'Nous proposons aussi un espace commerçant pour gérer les produits et les commandes, ainsi qu’un centre de contact pour vous assister en cas de besoin. Notre objectif est de rendre la livraison et les courses plus claires, rapides et accessibles.',
        );
      case PublicInfoType.privacy:
        return _PublicInfoContent(
          icon: Icons.privacy_tip_outlined,
          title: isAr ? 'سياسة الخصوصية' : 'Confidentialité',
          body: isAr
              ? 'خصوصيتك مهمة لنا. تطبيق مايحصر لا يستخدم رقم هاتفك إلا لهدف تسجيل الدخول، حماية حسابك، والتأكد من أن الخدمة تصل إلى صاحب الحساب الصحيح.\n\n'
                    'نحن لا نتتبع هاتفك، ولا نتجسس عليك، ولا نستخدم بياناتك لأي غرض خارج تشغيل الخدمة وحماية الحساب.\n\n'
                    'تطبيق مايحصر آمن 100%، وهدفنا أن تستخدمه براحة وثقة.'
              : 'Votre confidentialité est importante pour nous. Mayahsar utilise votre numéro de téléphone uniquement pour la connexion, la protection de votre compte et la vérification du bon utilisateur.\n\n'
                    'Nous ne suivons pas votre téléphone, nous ne vous espionnons pas et nous n’utilisons pas vos données en dehors du fonctionnement du service et de la sécurité du compte.\n\n'
                    'Mayahsar est une application sûre, conçue pour être utilisée avec confiance.',
        );
      case PublicInfoType.contact:
        return _PublicInfoContent(
          icon: Icons.support_agent_outlined,
          title: isAr ? 'تواصل معنا' : 'Contact',
          body: isAr
              ? 'نرحب بكم دائمًا في مايحصر، ويسعدنا خدمتكم والإجابة على استفساراتكم في أي وقت.\n\n'
                    'واتساب: 22233398\n'
                    'واتساب: 34339292\n'
                    'واتساب: 41196566'
              : 'Nous vous souhaitons toujours la bienvenue chez Mayahsar. Nous sommes à votre service pour répondre à vos questions à tout moment.\n\n'
                    'WhatsApp : 22233398\n'
                    'WhatsApp : 34339292\n'
                    'WhatsApp : 41196566',
        );
      case PublicInfoType.deleteAccount:
        return _PublicInfoContent(
          icon: Icons.person_remove_outlined,
          title: isAr ? 'طلب حذف حسابي' : 'Supprimer mon compte',
          body: isAr
              ? 'لطلب حذف حسابك وبياناتك، تواصل مع الدعم على ${AppConstants.supportPhone} مع إرسال رقم الهاتف المرتبط بالحساب.'
              : 'Pour demander la suppression de votre compte et de vos données, contactez le support au ${AppConstants.supportPhone} avec le numéro lié au compte.',
        );
    }
  }
}

enum PublicInfoType { about, privacy, contact, deleteAccount }

class _PublicInfoContent {
  const _PublicInfoContent({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
