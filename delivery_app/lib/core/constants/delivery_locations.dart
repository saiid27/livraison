const deliveryLocations = <String>[
  'كرفور تنسويلم',
  'تنسويلم الطلحاية',
  'تنسويلم مسجد زينب',
  'كرفور كوميسيريا الزعتر',
  'الزعتر فيراج الاول',
  'عرفات الداية عشرين',
  'عرفات الداية 18',
  'عرفات الداية 18 بقالة لمغاربة',
  'عرفات الداية 15',
  'عرفات الدايات 3',
  'عرفات الداية 4',
  'طب عرفات',
  'طب الصداقة',
  'مدريد جسر الصداقة',
  'مدريد كراج',
  'مدريد جمع البيت',
  'مدريد سوق مكة',
  'مدريد ليزين',
  'سوق الاتحاد',
  'مرسة كبتال',
  'بي ام دي BMD',
  'افاركو',
  'لكبيد انخيلة',
  'الرابع والعشرين',
  'لمسيد لحمر',
  'كرفور النائب',
  'كرفور انمبيت عشرة',
  'كرفور وقفت توجونين',
];

double? trialDeliveryPrice(String pickup, String delivery) {
  final hasValidPoints =
      deliveryLocations.contains(pickup) &&
      deliveryLocations.contains(delivery) &&
      pickup != delivery;
  return hasValidPoints ? 100 : null;
}
