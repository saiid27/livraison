from app import db
from app.models.delivery_pricing import DeliveryLocation, DeliveryPrice


DEFAULT_DELIVERY_PRICE = 100.0

DEFAULT_DELIVERY_LOCATIONS = {
    'كرفور تنسويلم',
    'تنسويلم الطلحاية',
    'تنسويلم مسجد زينب',
    'كرفور كوميسيريا الزعتر',
    'الزعتر فيراج الاول',
    'مدريد -كارافور بكار',
    'مدريد - مجمع البيت',
    'مدريد - الجسر',
    'مدريد - ليزين الخظرة',
    'مدريد - سوق مكة',
    'مدريد - مصحة النجاح',
    'مدريد - كارت الكرد',
    'مدريد - طب إيطاليا',
    'مدريد -مسجد الفاروق',
    'مدريد - كارافور أم قصر',
    'مدريد - حي الحرس الوطني',
    'مدريد - بقالة الله أكبر',
    'مدريد - معهد طيبة للعلوم الإسلامية',
    'مدريد - شارع ابوليس',
    'عرفات - كارفور لحواله',
    'عرفات - كارافور لابرار',
    'عرفات -RESTAURANT SNAPPY 2',
    'عرفات - مطعم المائدة',
    'عرفات - الدايه عشرين',
    'عرفات - مطعم دمشق الفلوجة',
    'عرفات -معرض الساحل للمفروشات',
    'عرفات - اعدادية عرفات 8',
    'عرفات -مسجد الزاوية',
    'عرفات -مدرسة الفاروق',
    'عرفات -École El Maladh Privé',
    'عرفات -الداية 19',
    'عرفات -مركز تكوين العلماء',
    'عرفات - مسجد الصحابة',
    'عرفات -الداية 18',
    'عرفات - الداية 17',
    'عرفات - الداية 15',
    'عرفات -مجمع عرفات',
    'عرفات -مستشفى الصداقة',
    'عرفات -دكان المنهل',
    'عرفات - إدارة العامة للتجمع العام لأمن الطرق',
    'عرفات -الشركة الوطنية للكهرباء',
    'عرفات -صونادير',
    'عرفات -بقالة جكني',
    'عرفات -مسجد شهداء بدر',
    'عرفات -مطعم POLITANO',
    'عرفات -مدرسة ذو النورين',
    'عرفات -مشوي جاك الخير',
    'عرفات -الداية 13',
    'عرفات - الداية 11',
    'عرفات -مجمع القدس',
    'عرفات -عالم الياسمين',
    'عرفات -قصر العدل بولاية انواكشوط الجنوبية',
    'عرفات -مسجد التقوى',
    'عرفات -مقهى ومطعم الامتياز',
    'عرفات -بقالة سعد الجاه',
    'عرفات - كارفور نانسي',
    "عرفات - Lycée d'exellence 2",
    'عرفات -ربينة اليابان',
    'عرفات - الداية 6',
    'عرفات - كارفور المعرض',
    'عرفات - مدرسة الرجاء الحرة',
    'عرفات -Restaurant Ali Baba',
    'عرفات - Scolaire Hamaho Allah',
    'عرفات - سوق تامشكط',
    'عرفات - مخبزة وحلويات المحجة البيضاء 2',
    'عرفات - ثانوية عرفات 1',
    'عرفات - الداية الرابعه',
    'عرفات - فور النجمة',
    'عرفات - الدايات اثلاثه',
    'عرفات - مجمع مدارس بلوغ المرام الحرة',
    'عرفات - فور الكواسر',
    'عرفات - مسجد أهل محمد سالم',
    'عرفات - مدرسة أحمد زروق',
    'عرفات - بيتقات عشرة',
    'عرفات - وقفة لحمار',
    'عرفات - معهد الإمام ورش',
    'عرفات -مجمع بلادي',
    'عرفات -بقالة جهينة',
    'عرفات - سوق الحرمين',
    'عرفات - مسجد ذو النورين',
    'عرفات - مسجد الحرمين',
    'عرفات -مجمع الزيتونة',
    'عرفات - مجمع المغاربه',
    'عرفات - كارفور مسجد النور',
    'عرفات - دريم كافي',
    'عرفات - كارفور قندهار',
    'عرفات - بقالة الدعاة',
    'عرفات - كارفور شرم الشيخ',
    'عرفات - صيدلية شرم الشيخ',
    'عرفات - مجمع أرض الجنتين',
    'عرفات - عيادة الجلدية والتناسلية وال ابنو',
    'عرفات - مسجد السنة',
    'عرفات - صيدلية سيف الاسلام',
    'عرفات - محظرة البيان لتحفيظ القرءان',
    'عرفات - مدرسة النزاري',
    'عرفات -مجمع لعصابة',
    'عرفات - مدرسة العمورية',
    'عرفات - بيت ابوليس',
    'عرفات - مطعم أطار للوجبات التقليدية',
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
}

# Backward-compatible name for existing imports.
DELIVERY_LOCATIONS = DEFAULT_DELIVERY_LOCATIONS


def seed_default_delivery_locations():
    for name in sorted(DEFAULT_DELIVERY_LOCATIONS):
        exists = DeliveryLocation.query.filter_by(name=name).first()
        if not exists:
            db.session.add(DeliveryLocation(name=name, is_active=True))


def all_delivery_locations():
    try:
        locations = DeliveryLocation.query.filter_by(is_active=True).order_by(
            DeliveryLocation.name.asc(),
        ).all()
        names = [location.name for location in locations]
        return names or sorted(DEFAULT_DELIVERY_LOCATIONS)
    except Exception:
        return sorted(DEFAULT_DELIVERY_LOCATIONS)


def is_delivery_location(name):
    if not name:
        return False
    try:
        exists = DeliveryLocation.query.filter_by(
            name=name,
            is_active=True,
        ).first()
        return exists is not None or name in DEFAULT_DELIVERY_LOCATIONS
    except Exception:
        return name in DEFAULT_DELIVERY_LOCATIONS


def _location_by_name(name):
    return DeliveryLocation.query.filter_by(name=name, is_active=True).first()


def trial_delivery_price(pickup, delivery):
    if not pickup or not delivery or pickup == delivery:
        return None
    try:
        pickup_location = _location_by_name(pickup)
        delivery_location = _location_by_name(delivery)
        if pickup_location and delivery_location:
            price = DeliveryPrice.query.filter_by(
                pickup_location_id=pickup_location.id,
                delivery_location_id=delivery_location.id,
            ).first()
            if not price:
                price = DeliveryPrice.query.filter_by(
                    pickup_location_id=delivery_location.id,
                    delivery_location_id=pickup_location.id,
                ).first()
            return price.price if price else DEFAULT_DELIVERY_PRICE
    except Exception:
        pass

    if pickup in DEFAULT_DELIVERY_LOCATIONS and delivery in DEFAULT_DELIVERY_LOCATIONS:
        return DEFAULT_DELIVERY_PRICE
    return None
