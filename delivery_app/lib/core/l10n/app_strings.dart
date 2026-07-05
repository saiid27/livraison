abstract class AppStrings {
  // App
  String get appName;
  String get tagline;

  // Common
  String get logout;
  String get cancel;
  String get yes;
  String get no;
  String get currency;
  String get required;
  String get invalid;

  // Logout dialog
  String get logoutTitle;
  String get logoutConfirm;
  String get disconnect;

  // Auth - Login
  String get welcome;
  String get loginSubtitle;
  String get email;
  String get emailRequired;
  String get emailInvalid;
  String get password;
  String get passwordRequired;
  String get passwordMin;
  String get loginBtn;
  String get noAccount;
  String get registerLink;

  // Auth - Register
  String get createAccount;
  String get registerSubtitle;
  String get fullName;
  String get nameRequired;
  String get phone;
  String get phoneRequired;
  String get iAm;
  String get roleClient;
  String get roleLivreur;
  String get registerBtn;
  String get alreadyAccount;
  String get loginLink;

  // Status
  String get statusWaiting;
  String get statusInProgress;
  String get statusDelivered;
  String get statusCancelled;

  // Client Home
  String get hello;
  String get quickActions;
  String get newOrderAction;
  String get myOrdersAction;
  String get liveTrackAction;
  String get activeOrder;
  String get recentOrders;
  String get noOrders;
  String get orderNow;
  String get trackDelivery;
  String get noActiveOrder;

  // Client Orders
  String get myOrders;
  String get cancelOrder;
  String get cancelOrderTitle;
  String get cancelOrderConfirm;
  String get cannotCancel;
  String get driver;

  // New Order
  String get newOrder;
  String get parcelDescription;
  String get whatToDeliver;
  String get whatToDeliverHint;
  String get addresses;
  String get pickupAddress;
  String get wherePickup;
  String get deliveryAddress;
  String get whereDeliver;
  String get proposedPrice;
  String get amount;
  String get sendOrder;
  String get orderCreated;
  String get descRequired;
  String get addrRequired;
  String get priceRequired;
  String get priceInvalid;

  // Track
  String get trackOrderPrefix;
  String get live;
  String get mapPlaceholder;
  String get deliveryStatus;
  String get orderReceived;
  String get orderReceivedSub;
  String get driverAssigned;
  String get driverAssignedSub;
  String get onTheWay;
  String get onTheWaySub;
  String get deliveredTitle;
  String get deliveredSub;

  // Profile (Client & Livreur)
  String get myProfile;
  String get personalInfo;
  String get orderHistory;
  String get helpSupport;

  // Livreur
  String get availableOrders;
  String get myDeliveries;
  String get online;
  String get offline;
  String get noAvailable;
  String get acceptOrder;
  String get orderAccepted;
  String get markDelivered;
  String get deliveriesLabel;
  String get ratingLabel;
  String get incomeLabel;
  String get myRatings;
  String get deliveryHistory;
  String get noDeliveries;

  // Admin
  String get dashboardTitle;
  String get platformOverview;
  String get totalOrders;
  String get pending;
  String get activeLabel;
  String get deliveredCount;
  String get cancelledCount;
  String get clientsLabel;
  String get livreursLabel;
  String get usersLabel;
  String get quickNav;
  String get manageOrders;
  String get manageOrdersSub;
  String get manageUsers;
  String get manageUsersSub;
  String get allLabel;
  String get noUser;
  String get statusLabel;

  // Captain History
  String get captainHistory;
  String get historyAll;
  String get historyInProgress;
  String get historyDelivered;
  String get historyCancelled;
  String get noHistoryOrders;
  String get cancelDelivery;
  String get cancelReasonTitle;
  String get cancelReasonHint;
  String get cancelReasonRequired;
  String get confirmCancel;
  String get cancellationReason;

  // Bottom Nav
  String get navHome;
  String get navOrders;
  String get navNewOrder;
  String get navProfile;
  String get navDeliveries;
  String get navDashboard;

  // Broadcast / Search
  String get searchingCaptain;
  String get broadcastAttempt;
  String get broadcastPause;
  String get broadcastExpired;
  String get noCaptainAvailable;
  String get contactCompany;
  String get captainFound;
  String get captainPhone;

  // Wallet
  String get myBalance;
  String get reloadBalance;
  String get walletTitle;
  String get commissionRate;
  String get insufficientBalance;
  String get insufficientBalanceMsg;
}

// ── French ──────────────────────────────────────────────────────────────────

class FrStrings extends AppStrings {
  @override
  String get appName => 'mayahsar';
  @override
  String get tagline => 'Livraison rapide & fiable';

  @override
  String get logout => 'Se déconnecter';
  @override
  String get cancel => 'Annuler';
  @override
  String get yes => 'Oui';
  @override
  String get no => 'Non';
  @override
  String get currency => 'MRU';
  @override
  String get required => 'Champ requis';
  @override
  String get invalid => 'Valeur invalide';

  @override
  String get logoutTitle => 'Déconnexion';
  @override
  String get logoutConfirm => 'Voulez-vous vraiment vous déconnecter ?';
  @override
  String get disconnect => 'Se déconnecter';

  @override
  String get welcome => 'Bienvenue !';
  @override
  String get loginSubtitle => 'Connectez-vous à votre compte';
  @override
  String get email => 'Email';
  @override
  String get emailRequired => 'Email requis';
  @override
  String get emailInvalid => 'Email invalide';
  @override
  String get password => 'Mot de passe';
  @override
  String get passwordRequired => 'Mot de passe requis';
  @override
  String get passwordMin => 'Minimum 6 caractères';
  @override
  String get loginBtn => 'Se connecter';
  @override
  String get noAccount => 'Pas de compte ?';
  @override
  String get registerLink => "S'inscrire";

  @override
  String get createAccount => 'Créer un compte';
  @override
  String get registerSubtitle => 'Rejoignez notre plateforme';
  @override
  String get fullName => 'Nom complet';
  @override
  String get nameRequired => 'Nom requis';
  @override
  String get phone => 'Téléphone';
  @override
  String get phoneRequired => 'Téléphone requis';
  @override
  String get iAm => 'Je suis :';
  @override
  String get roleClient => 'Client';
  @override
  String get roleLivreur => 'Livreur';
  @override
  String get registerBtn => "S'inscrire";
  @override
  String get alreadyAccount => 'Déjà un compte ?';
  @override
  String get loginLink => 'Se connecter';

  @override
  String get statusWaiting => 'En attente';
  @override
  String get statusInProgress => 'En cours';
  @override
  String get statusDelivered => 'Livré';
  @override
  String get statusCancelled => 'Annulé';

  @override
  String get hello => 'Bonjour 👋';
  @override
  String get quickActions => 'Actions rapides';
  @override
  String get newOrderAction => 'Nouvelle\ncommande';
  @override
  String get myOrdersAction => 'Mes\ncommandes';
  @override
  String get liveTrackAction => 'Suivi\nlive';
  @override
  String get activeOrder => 'Commande en cours';
  @override
  String get recentOrders => 'Commandes récentes';
  @override
  String get noOrders => 'Aucune commande';
  @override
  String get orderNow => 'Commander maintenant';
  @override
  String get trackDelivery => 'Suivre la livraison';
  @override
  String get noActiveOrder => 'Aucune commande en cours';

  @override
  String get myOrders => 'Mes commandes';
  @override
  String get cancelOrder => 'Annuler la commande';
  @override
  String get cancelOrderTitle => 'Annuler la commande ?';
  @override
  String get cancelOrderConfirm => 'Cette action est irréversible.';
  @override
  String get cannotCancel =>
      'Impossible d\'annuler une commande en cours ou livrée';
  @override
  String get driver => 'Livreur';

  @override
  String get newOrder => 'Nouvelle commande';
  @override
  String get parcelDescription => 'Description du colis';
  @override
  String get whatToDeliver => 'Que voulez-vous livrer ?';
  @override
  String get whatToDeliverHint => 'Ex: Documents importants, colis fragile...';
  @override
  String get addresses => 'Adresses';
  @override
  String get pickupAddress => 'Adresse de ramassage';
  @override
  String get wherePickup => 'Où récupérer le colis ?';
  @override
  String get deliveryAddress => 'Adresse de livraison';
  @override
  String get whereDeliver => 'Où livrer le colis ?';
  @override
  String get proposedPrice => 'Prix proposé';
  @override
  String get amount => 'Montant (MRU)';
  @override
  String get sendOrder => 'Envoyer la commande';
  @override
  String get orderCreated => 'Commande créée avec succès !';
  @override
  String get descRequired => 'Description requise';
  @override
  String get addrRequired => 'Adresse requise';
  @override
  String get priceRequired => 'Prix requis';
  @override
  String get priceInvalid => 'Prix invalide';

  @override
  String get trackOrderPrefix => 'Suivi commande #';
  @override
  String get live => 'En direct';
  @override
  String get mapPlaceholder => 'Carte en temps réel\n(Google Maps)';
  @override
  String get deliveryStatus => 'Statut de la livraison';
  @override
  String get orderReceived => 'Commande reçue';
  @override
  String get orderReceivedSub => 'Votre commande a été enregistrée';
  @override
  String get driverAssigned => 'Livreur assigné';
  @override
  String get driverAssignedSub => 'Un livreur a accepté votre commande';
  @override
  String get onTheWay => 'En route';
  @override
  String get onTheWaySub => 'Le livreur est en chemin';
  @override
  String get deliveredTitle => 'Livré';
  @override
  String get deliveredSub => 'Commande livrée avec succès';

  @override
  String get myProfile => 'Mon profil';
  @override
  String get personalInfo => 'Informations personnelles';
  @override
  String get orderHistory => 'Historique des commandes';
  @override
  String get helpSupport => 'Aide & Support';

  @override
  String get availableOrders => 'Commandes disponibles';
  @override
  String get myDeliveries => 'Mes livraisons';
  @override
  String get online => '● En ligne';
  @override
  String get offline => '● Hors ligne';
  @override
  String get noAvailable => 'Aucune commande disponible';
  @override
  String get acceptOrder => 'Accepter la commande';
  @override
  String get orderAccepted => 'Commande acceptée !';
  @override
  String get markDelivered => 'Marquer comme livré';
  @override
  String get deliveriesLabel => 'Livraisons';
  @override
  String get ratingLabel => 'Note';
  @override
  String get incomeLabel => 'Revenus';
  @override
  String get myRatings => 'Mes évaluations';
  @override
  String get deliveryHistory => 'Historique des livraisons';
  @override
  String get noDeliveries => 'Aucune livraison en cours';

  @override
  String get dashboardTitle => 'Dashboard Admin';
  @override
  String get platformOverview => "Vue d'ensemble de la plateforme";
  @override
  String get totalOrders => 'Commandes totales';
  @override
  String get pending => 'En attente';
  @override
  String get activeLabel => 'En cours';
  @override
  String get deliveredCount => 'Livrés';
  @override
  String get cancelledCount => 'Annulés';
  @override
  String get clientsLabel => 'Clients';
  @override
  String get livreursLabel => 'Livreurs';
  @override
  String get usersLabel => 'Utilisateurs';
  @override
  String get quickNav => 'Navigation rapide';
  @override
  String get manageOrders => 'Gérer les commandes';
  @override
  String get manageOrdersSub => 'Voir et modifier toutes les commandes';
  @override
  String get manageUsers => 'Gérer les utilisateurs';
  @override
  String get manageUsersSub => 'Clients et livreurs de la plateforme';
  @override
  String get allLabel => 'Tous';
  @override
  String get noUser => 'Aucun';
  @override
  String get statusLabel => 'Statut';

  @override
  String get captainHistory => 'Historique des demandes';
  @override
  String get historyAll => 'Toutes';
  @override
  String get historyInProgress => 'En cours';
  @override
  String get historyDelivered => 'Livrées';
  @override
  String get historyCancelled => 'Annulées';
  @override
  String get noHistoryOrders => 'Aucune demande dans cette catégorie';
  @override
  String get cancelDelivery => 'Annuler la livraison';
  @override
  String get cancelReasonTitle => 'Motif d\'annulation';
  @override
  String get cancelReasonHint =>
      'Expliquez pourquoi vous annulez cette livraison...';
  @override
  String get cancelReasonRequired => 'Le motif est obligatoire';
  @override
  String get confirmCancel => 'Confirmer l\'annulation';
  @override
  String get cancellationReason => 'Motif d\'annulation';

  @override
  String get navHome => 'Accueil';
  @override
  String get navOrders => 'Commandes';
  @override
  String get navNewOrder => 'Commander';
  @override
  String get navProfile => 'Profil';
  @override
  String get navDeliveries => 'Livraisons';
  @override
  String get navDashboard => 'Dashboard';

  @override
  String get searchingCaptain => 'Recherche d\'un capitaine...';
  @override
  String get broadcastAttempt => 'Tentative';
  @override
  String get broadcastPause => 'Pause avant la prochaine tentative';
  @override
  String get broadcastExpired => 'Aucun capitaine n\'a répondu';
  @override
  String get noCaptainAvailable =>
      'Aucun capitaine n\'est actuellement disponible à proximité de votre position. Veuillez contacter la société.';
  @override
  String get contactCompany => 'Contacter la société';
  @override
  String get captainFound => 'Capitaine trouvé !';
  @override
  String get captainPhone => 'Téléphone';

  @override
  String get myBalance => 'Mon solde';
  @override
  String get reloadBalance => 'Recharger le solde';
  @override
  String get walletTitle => 'Portefeuille';
  @override
  String get commissionRate => 'Commission plateforme : 9%';
  @override
  String get insufficientBalance => 'Solde insuffisant';
  @override
  String get insufficientBalanceMsg =>
      'Votre solde est insuffisant pour accepter cette commande. Rechargez votre portefeuille.';
}

// ── Arabic ───────────────────────────────────────────────────────────────────

class ArStrings extends AppStrings {
  @override
  String get appName => 'mayahsar';
  @override
  String get tagline => 'توصيل سريع وموثوق';

  @override
  String get logout => 'تسجيل الخروج';
  @override
  String get cancel => 'إلغاء';
  @override
  String get yes => 'نعم';
  @override
  String get no => 'لا';
  @override
  String get currency => 'أوقية';
  @override
  String get required => 'الحقل مطلوب';
  @override
  String get invalid => 'قيمة غير صالحة';

  @override
  String get logoutTitle => 'تسجيل الخروج';
  @override
  String get logoutConfirm => 'هل تريد تسجيل الخروج ؟';
  @override
  String get disconnect => 'خروج';

  @override
  String get welcome => 'أهلاً وسهلاً !';
  @override
  String get loginSubtitle => 'سجل الدخول إلى حسابك';
  @override
  String get email => 'البريد الإلكتروني';
  @override
  String get emailRequired => 'البريد الإلكتروني مطلوب';
  @override
  String get emailInvalid => 'بريد إلكتروني غير صالح';
  @override
  String get password => 'كلمة المرور';
  @override
  String get passwordRequired => 'كلمة المرور مطلوبة';
  @override
  String get passwordMin => '6 أحرف على الأقل';
  @override
  String get loginBtn => 'تسجيل الدخول';
  @override
  String get noAccount => 'ليس لديك حساب ؟';
  @override
  String get registerLink => 'إنشاء حساب';

  @override
  String get createAccount => 'إنشاء حساب جديد';
  @override
  String get registerSubtitle => 'انضم إلى منصتنا';
  @override
  String get fullName => 'الاسم الكامل';
  @override
  String get nameRequired => 'الاسم مطلوب';
  @override
  String get phone => 'رقم الهاتف';
  @override
  String get phoneRequired => 'رقم الهاتف مطلوب';
  @override
  String get iAm => ':أنا';
  @override
  String get roleClient => 'عميل';
  @override
  String get roleLivreur => 'مندوب توصيل';
  @override
  String get registerBtn => 'إنشاء حساب';
  @override
  String get alreadyAccount => 'لديك حساب ؟';
  @override
  String get loginLink => 'تسجيل الدخول';

  @override
  String get statusWaiting => 'في الانتظار';
  @override
  String get statusInProgress => 'جارٍ';
  @override
  String get statusDelivered => 'تم التوصيل';
  @override
  String get statusCancelled => 'ملغي';

  @override
  String get hello => 'مرحباً 👋';
  @override
  String get quickActions => 'إجراءات سريعة';
  @override
  String get newOrderAction => 'طلب\nجديد';
  @override
  String get myOrdersAction => 'طلباتي';
  @override
  String get liveTrackAction => 'تتبع\nمباشر';
  @override
  String get activeOrder => 'طلب جارٍ';
  @override
  String get recentOrders => 'الطلبات الأخيرة';
  @override
  String get noOrders => 'لا توجد طلبات';
  @override
  String get orderNow => 'اطلب الآن';
  @override
  String get trackDelivery => 'تتبع التوصيل';
  @override
  String get noActiveOrder => 'لا يوجد طلب جارٍ';

  @override
  String get myOrders => 'طلباتي';
  @override
  String get cancelOrder => 'إلغاء الطلب';
  @override
  String get cancelOrderTitle => 'إلغاء الطلب ؟';
  @override
  String get cancelOrderConfirm => 'هذا الإجراء لا يمكن التراجع عنه.';
  @override
  String get cannotCancel => 'لا يمكن إلغاء طلب جارٍ أو تم توصيله';
  @override
  String get driver => 'المندوب';

  @override
  String get newOrder => 'طلب جديد';
  @override
  String get parcelDescription => 'وصف الطرد';
  @override
  String get whatToDeliver => 'ماذا تريد توصيله ؟';
  @override
  String get whatToDeliverHint => 'مثال: وثائق مهمة، طرد هش...';
  @override
  String get addresses => 'العناوين';
  @override
  String get pickupAddress => 'عنوان الاستلام';
  @override
  String get wherePickup => 'من أين يُستلم الطرد ؟';
  @override
  String get deliveryAddress => 'عنوان التوصيل';
  @override
  String get whereDeliver => 'إلى أين يُوصَّل الطرد ؟';
  @override
  String get proposedPrice => 'السعر المقترح';
  @override
  String get amount => 'المبلغ (أوقية)';
  @override
  String get sendOrder => 'إرسال الطلب';
  @override
  String get orderCreated => '!تم إنشاء الطلب بنجاح';
  @override
  String get descRequired => 'الوصف مطلوب';
  @override
  String get addrRequired => 'العنوان مطلوب';
  @override
  String get priceRequired => 'السعر مطلوب';
  @override
  String get priceInvalid => 'سعر غير صالح';

  @override
  String get trackOrderPrefix => 'تتبع الطلب #';
  @override
  String get live => 'مباشر';
  @override
  String get mapPlaceholder => 'الخريطة المباشرة\n(Google Maps)';
  @override
  String get deliveryStatus => 'حالة التوصيل';
  @override
  String get orderReceived => 'تم استلام الطلب';
  @override
  String get orderReceivedSub => 'تم تسجيل طلبك بنجاح';
  @override
  String get driverAssigned => 'تم تعيين مندوب';
  @override
  String get driverAssignedSub => 'قبل مندوب طلبك';
  @override
  String get onTheWay => 'في الطريق';
  @override
  String get onTheWaySub => 'المندوب في طريقه إليك';
  @override
  String get deliveredTitle => 'تم التوصيل';
  @override
  String get deliveredSub => 'تم توصيل طلبك بنجاح';

  @override
  String get myProfile => 'ملفي الشخصي';
  @override
  String get personalInfo => 'المعلومات الشخصية';
  @override
  String get orderHistory => 'سجل الطلبات';
  @override
  String get helpSupport => 'المساعدة والدعم';

  @override
  String get availableOrders => 'الطلبات المتاحة';
  @override
  String get myDeliveries => 'توصيلاتي';
  @override
  String get online => '● متصل';
  @override
  String get offline => '● غير متصل';
  @override
  String get noAvailable => 'لا توجد طلبات متاحة';
  @override
  String get acceptOrder => 'قبول الطلب';
  @override
  String get orderAccepted => '!تم قبول الطلب';
  @override
  String get markDelivered => 'تحديد كمُوصَّل';
  @override
  String get deliveriesLabel => 'توصيلات';
  @override
  String get ratingLabel => 'التقييم';
  @override
  String get incomeLabel => 'الدخل';
  @override
  String get myRatings => 'تقييماتي';
  @override
  String get deliveryHistory => 'سجل التوصيلات';
  @override
  String get noDeliveries => 'لا توجد توصيلات';

  @override
  String get dashboardTitle => 'لوحة التحكم';
  @override
  String get platformOverview => 'نظرة عامة على المنصة';
  @override
  String get totalOrders => 'إجمالي الطلبات';
  @override
  String get pending => 'في الانتظار';
  @override
  String get activeLabel => 'جارٍ';
  @override
  String get deliveredCount => 'تم التوصيل';
  @override
  String get cancelledCount => 'ملغي';
  @override
  String get clientsLabel => 'العملاء';
  @override
  String get livreursLabel => 'المندوبون';
  @override
  String get usersLabel => 'المستخدمون';
  @override
  String get quickNav => 'التنقل السريع';
  @override
  String get manageOrders => 'إدارة الطلبات';
  @override
  String get manageOrdersSub => 'عرض وتعديل جميع الطلبات';
  @override
  String get manageUsers => 'إدارة المستخدمين';
  @override
  String get manageUsersSub => 'عملاء ومندوبو المنصة';
  @override
  String get allLabel => 'الكل';
  @override
  String get noUser => 'لا يوجد';
  @override
  String get statusLabel => 'الحالة';

  @override
  String get captainHistory => 'سجل الطلبات';
  @override
  String get historyAll => 'الكل';
  @override
  String get historyInProgress => 'جارٍ';
  @override
  String get historyDelivered => 'مُوصَّلة';
  @override
  String get historyCancelled => 'ملغية';
  @override
  String get noHistoryOrders => 'لا توجد طلبات في هذه الفئة';
  @override
  String get cancelDelivery => 'إلغاء التوصيل';
  @override
  String get cancelReasonTitle => 'سبب الإلغاء';
  @override
  String get cancelReasonHint => 'اكتب سبب إلغاء هذا التوصيل...';
  @override
  String get cancelReasonRequired => 'السبب مطلوب';
  @override
  String get confirmCancel => 'تأكيد الإلغاء';
  @override
  String get cancellationReason => 'سبب الإلغاء';

  @override
  String get navHome => 'الرئيسية';
  @override
  String get navOrders => 'الطلبات';
  @override
  String get navNewOrder => 'اطلب';
  @override
  String get navProfile => 'ملفي';
  @override
  String get navDeliveries => 'التوصيلات';
  @override
  String get navDashboard => 'الرئيسية';

  @override
  String get searchingCaptain => '...جارٍ البحث عن كابتن';
  @override
  String get broadcastAttempt => 'محاولة';
  @override
  String get broadcastPause => 'توقف مؤقت قبل المحاولة التالية';
  @override
  String get broadcastExpired => 'لم يستجب أي كابتن';
  @override
  String get noCaptainAvailable =>
      'لا يوجد حالياً أي كابتن متاح بالقرب من موقعك. يرجى التواصل مع الشركة.';
  @override
  String get contactCompany => 'التواصل مع الشركة';
  @override
  String get captainFound => '!تم العثور على كابتن';
  @override
  String get captainPhone => 'الهاتف';

  @override
  String get myBalance => 'رصيدي';
  @override
  String get reloadBalance => 'شحن الرصيد';
  @override
  String get walletTitle => 'المحفظة';
  @override
  String get commissionRate => 'عمولة المنصة: 9%';
  @override
  String get insufficientBalance => 'رصيد غير كافٍ';
  @override
  String get insufficientBalanceMsg =>
      'رصيدك غير كافٍ لقبول هذا الطلب. يرجى شحن محفظتك.';
}
