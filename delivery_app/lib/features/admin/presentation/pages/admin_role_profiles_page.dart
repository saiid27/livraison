import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/language_provider.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/language_button.dart';
import '../../../../core/widgets/logout_button.dart';
import '../../../auth/data/models/user_model.dart';
import '../../../client/data/models/order_model.dart';

enum AdminProfileKind { captain, merchant }

class AdminRoleProfilesPage extends ConsumerStatefulWidget {
  final AdminProfileKind kind;

  const AdminRoleProfilesPage({super.key, required this.kind});

  @override
  ConsumerState<AdminRoleProfilesPage> createState() =>
      _AdminRoleProfilesPageState();
}

class _AdminRoleProfilesPageState extends ConsumerState<AdminRoleProfilesPage> {
  late Future<List<UserModel>> _future;

  bool get _isCaptain => widget.kind == AdminProfileKind.captain;

  String get _listEndpoint =>
      _isCaptain ? '/admin/captains' : '/admin/merchants';

  @override
  void initState() {
    super.initState();
    _future = _loadUsers();
  }

  Future<List<UserModel>> _loadUsers() async {
    final response = await ApiClient.instance.get(_listEndpoint);
    return (response.data['users'] as List)
        .map((user) => UserModel.fromJson(user))
        .toList();
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadUsers());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    final title = _isCaptain
        ? (isAr ? 'قائمة الكباتنة' : 'Liste des capitaines')
        : (isAr ? 'قائمة التجار' : 'Liste des commerçants');

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/admin'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _EmptyState(
              icon: Icons.error_outline,
              label: isAr ? 'تعذر تحميل القائمة' : 'Chargement impossible',
            );
          }
          final users = snapshot.data ?? const [];
          if (users.isEmpty) {
            return _EmptyState(
              icon: _isCaptain
                  ? Icons.delivery_dining_outlined
                  : Icons.storefront_outlined,
              label: _isCaptain
                  ? (isAr ? 'لا يوجد كباتنة' : 'Aucun capitaine')
                  : (isAr ? 'لا يوجد تجار' : 'Aucun commerçant'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                return _ProfileListTile(
                  user: user,
                  isCaptain: _isCaptain,
                  onTap: () => context.go(
                    _isCaptain
                        ? '/admin/captains/${user.id}'
                        : '/admin/merchants/${user.id}',
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class AdminProfileDetailPage extends ConsumerStatefulWidget {
  final AdminProfileKind kind;
  final String userId;

  const AdminProfileDetailPage({
    super.key,
    required this.kind,
    required this.userId,
  });

  @override
  ConsumerState<AdminProfileDetailPage> createState() =>
      _AdminProfileDetailPageState();
}

class _AdminProfileDetailPageState
    extends ConsumerState<AdminProfileDetailPage> {
  late Future<Map<String, dynamic>> _future;

  bool get _isCaptain => widget.kind == AdminProfileKind.captain;

  String get _endpoint => _isCaptain
      ? '/admin/captains/${widget.userId}'
      : '/admin/merchants/${widget.userId}';

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  }

  Future<Map<String, dynamic>> _loadProfile() async {
    final response = await ApiClient.instance.get(_endpoint);
    return Map<String, dynamic>.from(response.data);
  }

  Future<void> _refresh() async {
    setState(() => _future = _loadProfile());
    await _future;
  }

  Future<void> _uploadCaptainDocument(String field, String imagePath) async {
    final formData = FormData.fromMap({
      field: await MultipartFile.fromFile(imagePath),
    });
    await ApiClient.instance.put(
      '/admin/captains/${widget.userId}/documents',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final isAr = ref.watch(localeProvider).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(
        title: Text(isAr ? 'البروفايل' : 'Profil'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go(_isCaptain ? '/admin/captains' : '/admin/merchants'),
        ),
        actions: const [LanguageButton(), LogoutButton()],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return _EmptyState(
              icon: Icons.error_outline,
              label: isAr ? 'تعذر تحميل البروفايل' : 'Profil indisponible',
            );
          }

          final data = snapshot.data!;
          final user = UserModel.fromJson(data['user']);
          final stats = Map<String, dynamic>.from(data['stats'] ?? {});
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _ProfileHeader(
                  user: user,
                  isCaptain: _isCaptain,
                  stats: stats,
                  isAr: isAr,
                ),
                const SizedBox(height: 14),
                if (_isCaptain) ...[
                  _CaptainDocumentsSection(
                    user: user,
                    isAr: isAr,
                    onUpload: _uploadCaptainDocument,
                  ),
                  const SizedBox(height: 14),
                  _CaptainOrdersSection(
                    orders: ((data['orders'] ?? []) as List)
                        .map((order) => OrderModel.fromJson(order))
                        .toList(),
                    isAr: isAr,
                  ),
                ] else ...[
                  _MerchantProductsSection(
                    products: ((data['products'] ?? []) as List)
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList(),
                    isAr: isAr,
                  ),
                  const SizedBox(height: 14),
                  _MerchantOrdersSection(
                    orders: ((data['orders'] ?? []) as List)
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList(),
                    isAr: isAr,
                  ),
                  const SizedBox(height: 14),
                  _MerchantPaymentMethodsSection(
                    methods: ((data['payment_methods'] ?? []) as List)
                        .map((item) => Map<String, dynamic>.from(item))
                        .toList(),
                    isAr: isAr,
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final UserModel user;
  final bool isCaptain;
  final VoidCallback onTap;

  const _ProfileListTile({
    required this.user,
    required this.isCaptain,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCaptain ? Colors.teal : AppColors.secondary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: _Avatar(path: user.avatar, color: color, name: user.name),
        title: Text(
          user.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${user.phone}\n${user.email}'),
        isThreeLine: true,
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCaptain;
  final Map<String, dynamic> stats;
  final bool isAr;

  const _ProfileHeader({
    required this.user,
    required this.isCaptain,
    required this.stats,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCaptain ? Colors.teal : AppColors.secondary;
    final balance = (stats['balance'] as num?)?.toDouble();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(
                path: user.avatar,
                color: color,
                name: user.name,
                size: 58,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      user.phone,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      user.email,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (!isCaptain && user.merchantContactPhone != null)
                      Text(
                        'Contact: ${user.merchantContactPhone}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    if (!isCaptain && user.merchantPaymentPhone != null)
                      Text(
                        'Paiement: ${user.merchantPaymentPhone}',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoPill(
                label: isAr ? 'الطلبات' : 'Commandes',
                value: '${stats['orders_count'] ?? 0}',
                color: AppColors.primary,
              ),
              if (isCaptain)
                _InfoPill(
                  label: isAr ? 'تم التوصيل' : 'Livrées',
                  value: '${stats['delivered_count'] ?? 0}',
                  color: AppColors.success,
                ),
              if (balance != null)
                _InfoPill(
                  label: isAr ? 'الرصيد' : 'Solde',
                  value: '${balance.toStringAsFixed(0)} MRU',
                  color: Colors.teal,
                ),
              if (!isCaptain)
                _InfoPill(
                  label: isAr ? 'المنتجات' : 'Produits',
                  value: '${stats['products_count'] ?? 0}',
                  color: AppColors.secondary,
                ),
              if (!isCaptain)
                _InfoPill(
                  label: isAr ? 'المبيعات' : 'Ventes',
                  value:
                      '${((stats['sales_total'] as num?)?.toDouble() ?? 0).toStringAsFixed(0)} MRU',
                  color: AppColors.success,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CaptainOrdersSection extends StatelessWidget {
  final List<OrderModel> orders;
  final bool isAr;

  const _CaptainOrdersSection({required this.orders, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: isAr ? 'الطلبات والكورسات التي أخذها' : 'Courses prises',
      empty: isAr ? 'لم يأخذ أي طلب بعد' : 'Aucune course',
      children: orders.map((order) {
        return _DataCard(
          title: '#${order.id} - ${_statusLabel(order.status, isAr)}',
          lines: [
            order.description,
            '${isAr ? 'من' : 'De'}: ${order.pickupAddress}',
            '${isAr ? 'إلى' : 'À'}: ${order.deliveryAddress}',
            if (order.price != null) '${order.price!.toStringAsFixed(0)} MRU',
          ],
          icon: order.serviceType == 'course'
              ? Icons.directions_car_outlined
              : Icons.delivery_dining_outlined,
        );
      }).toList(),
    );
  }
}

class _CaptainDocumentsSection extends StatelessWidget {
  final UserModel user;
  final bool isAr;
  final Future<void> Function(String field, String imagePath) onUpload;

  const _CaptainDocumentsSection({
    required this.user,
    required this.isAr,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final documents = [
      (
        title: isAr ? 'الصورة الشخصية' : 'Photo personnelle',
        field: 'profile_image',
        path: user.avatar,
        icon: Icons.person_outline,
      ),
      (
        title: isAr ? 'بطاقة التعريف' : 'Carte d’identité',
        field: 'id_card_image',
        path: user.idCardImage,
        icon: Icons.badge_outlined,
      ),
      (
        title: isAr ? 'صورة الموتو' : 'Photo moto',
        field: 'vehicle_image',
        path: user.vehicleImage,
        icon: Icons.two_wheeler_outlined,
      ),
      (
        title: isAr ? 'ترخيص المركبة' : 'Immatriculation',
        field: 'vehicle_registration_image',
        path: user.vehicleRegistrationImage,
        icon: Icons.description_outlined,
      ),
      (
        title: isAr ? 'صورة التصريح' : 'Permis',
        field: 'permit_image',
        path: user.permitImage,
        icon: Icons.assignment_ind_outlined,
      ),
    ];

    return _Section(
      title: isAr ? 'صور الكابتن المرفوعة' : 'Documents du capitaine',
      empty: isAr ? 'لا توجد صور مرفوعة' : 'Aucune image',
      children: documents
          .map(
            (document) => _DocumentReviewCard(
              title: document.title,
              field: document.field,
              path: document.path,
              icon: document.icon,
              isAr: isAr,
              onUpload: onUpload,
            ),
          )
          .toList(),
    );
  }
}

class _DocumentReviewCard extends StatelessWidget {
  final String title;
  final String field;
  final String? path;
  final IconData icon;
  final bool isAr;
  final Future<void> Function(String field, String imagePath) onUpload;

  const _DocumentReviewCard({
    required this.title,
    required this.field,
    required this.path,
    required this.icon,
    required this.isAr,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl(path);
    final hasImage = url != null;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: hasImage ? () => _openPreview(context, url) : null,
        leading: _DocumentThumb(url: url, icon: icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(
          hasImage
              ? (isAr ? 'اضغط لمراجعة الصورة' : 'Toucher pour vérifier')
              : (isAr ? 'لا توجد صورة محفوظة' : 'Aucune image enregistrée'),
        ),
        trailing: Wrap(
          spacing: 4,
          children: [
            if (hasImage)
              IconButton(
                tooltip: isAr ? 'عرض' : 'Voir',
                onPressed: () => _openPreview(context, url),
                icon: const Icon(Icons.visibility_outlined),
              ),
            IconButton(
              tooltip: isAr ? 'تعديل الصورة' : 'Modifier',
              onPressed: () => _pickAndUpload(context),
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUpload(BuildContext context) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await onUpload(field, picked.path);
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تم تحديث الصورة' : 'Image mise à jour'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(isAr ? 'تعذر تحديث الصورة' : 'Mise à jour impossible'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  void _openPreview(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isAr
                          ? 'الصورة غير متوفرة على السيرفر'
                          : 'Image indisponible sur le serveur',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentThumb extends StatelessWidget {
  final String? url;
  final IconData icon;

  const _DocumentThumb({required this.url, required this.icon});

  @override
  Widget build(BuildContext context) {
    if (url == null) return _IconBox(icon: icon);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url!,
        width: 58,
        height: 58,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _IconBox(icon: icon),
      ),
    );
  }
}

class _MerchantProductsSection extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isAr;

  const _MerchantProductsSection({required this.products, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: isAr ? 'منتجات التاجر' : 'Produits',
      empty: isAr ? 'لا توجد منتجات' : 'Aucun produit',
      children: products.map((product) {
        final price = (product['price'] as num?)?.toDouble() ?? 0;
        return _DataCard(
          title: product['name']?.toString() ?? '',
          lines: [
            '${price.toStringAsFixed(0)} MRU',
            '${isAr ? 'المتوفر' : 'Stock'}: ${product['quantity'] ?? 0}',
          ],
          icon: Icons.shopping_bag_outlined,
          imagePath: product['image']?.toString(),
        );
      }).toList(),
    );
  }
}

class _MerchantOrdersSection extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool isAr;

  const _MerchantOrdersSection({required this.orders, required this.isAr});

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: isAr ? 'طلبات التاجر' : 'Commandes du commerçant',
      empty: isAr ? 'لا توجد طلبات' : 'Aucune commande',
      children: orders.map((order) {
        final total = (order['total_price'] as num?)?.toDouble() ?? 0;
        return _DataCard(
          title: '#${order['id']} - ${order['product_name'] ?? ''}',
          lines: [
            '${isAr ? 'الزبون' : 'Client'}: ${order['client_name'] ?? '-'}',
            '${isAr ? 'الكمية' : 'Qté'}: ${order['quantity'] ?? 0}',
            '${total.toStringAsFixed(0)} MRU',
            '${isAr ? 'الحالة' : 'Statut'}: ${order['status'] ?? '-'}',
          ],
          icon: Icons.receipt_long_outlined,
          imagePath: order['product_image']?.toString(),
        );
      }).toList(),
    );
  }
}

class _MerchantPaymentMethodsSection extends StatelessWidget {
  final List<Map<String, dynamic>> methods;
  final bool isAr;

  const _MerchantPaymentMethodsSection({
    required this.methods,
    required this.isAr,
  });

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: isAr ? 'طرق دفع التاجر' : 'Moyens de paiement',
      empty: isAr ? 'لا توجد طرق دفع' : 'Aucun moyen de paiement',
      children: methods.map((method) {
        final active = method['is_active'] == true;
        return _DataCard(
          title: method['name']?.toString() ?? '',
          lines: [
            method['phone_number']?.toString() ?? '',
            isAr
                ? (active ? 'نشط' : 'غير نشط')
                : (active ? 'Actif' : 'Inactif'),
          ],
          icon: Icons.account_balance_wallet_outlined,
        );
      }).toList(),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String empty;
  final List<Widget> children;

  const _Section({
    required this.title,
    required this.empty,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        if (children.isEmpty)
          _EmptyState(icon: Icons.inbox_outlined, label: empty, compact: true)
        else
          ...children,
      ],
    );
  }
}

class _DataCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData icon;
  final String? imagePath;

  const _DataCard({
    required this.title,
    required this.lines,
    required this.icon,
    this.imagePath,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _SquareImage(path: imagePath, icon: icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 6),
                  ...lines
                      .where((line) => line.trim().isNotEmpty)
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            line,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? path;
  final Color color;
  final String name;
  final double size;

  const _Avatar({
    required this.path,
    required this.color,
    required this.name,
    this.size = 46,
  });

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl(path);
    if (url != null) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _InitialAvatar(color: color, name: name, size: size),
        ),
      );
    }
    return _InitialAvatar(color: color, name: name, size: size);
  }
}

class _InitialAvatar extends StatelessWidget {
  final Color color;
  final String name;
  final double size;

  const _InitialAvatar({
    required this.color,
    required this.name,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Text(
        initial,
        style: TextStyle(color: color, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _SquareImage extends StatelessWidget {
  final String? path;
  final IconData icon;

  const _SquareImage({required this.path, required this.icon});

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl(path);
    if (url != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          url,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _IconBox(icon: icon),
        ),
      );
    }
    return _IconBox(icon: icon);
  }
}

class _IconBox extends StatelessWidget {
  final IconData icon;

  const _IconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(color: color, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool compact;

  const _EmptyState({
    required this.icon,
    required this.label,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 18 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: compact ? 36 : 62,
              color: AppColors.textSecondary.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

String? _imageUrl(String? path) {
  if (path == null || path.isEmpty) return null;
  if (path.startsWith('http')) return path;
  return '${AppConstants.baseUrl.replaceAll('/api', '')}$path';
}

String _statusLabel(String status, bool isAr) {
  return switch (status) {
    'en_attente' => isAr ? 'بانتظار' : 'En attente',
    'en_cours' => isAr ? 'جاري' : 'En cours',
    'livre' => isAr ? 'تم' : 'Livré',
    'annule' => isAr ? 'ملغي' : 'Annulé',
    _ => status,
  };
}
