import 'package:cloud_firestore/cloud_firestore.dart';

abstract class DistanceRepository {
  Stream<int> watchDistanceTodayMeters();
  Stream<int> watchWalkingTimeMinutes();
  Stream<int> watchWeeklyTotalMeters();
  Stream<int> watchWeeklyWalkingTimeMinutes();
  Stream<int> watchTodayTargetAchievementMeters();
  Stream<int> watchTodayTargetGoalMeters();
  Stream<String> watchOperatingMode();
  Stream<bool> watchHasWalkedToday();
  Stream<int> watchWalkStreakDays();
  Future<void> markWalkedToday();
}

class DemoDistanceRepository implements DistanceRepository {
  const DemoDistanceRepository({
    this.seedDistanceMeters = 1240,
    this.seedWalkingTimeMinutes = 42,
    this.seedWeeklyTotalMeters = 4200,
    this.seedWeeklyWalkingTimeMinutes = 342,
    this.seedTodayTargetAchievementMeters = 320,
    this.seedTodayTargetGoalMeters = 500,
    this.seedWalkStreakDays = 7,
  });

  final int seedDistanceMeters;
  final int seedWalkingTimeMinutes;
  final int seedWeeklyTotalMeters;
  final int seedWeeklyWalkingTimeMinutes;
  final int seedTodayTargetAchievementMeters;
  final int seedTodayTargetGoalMeters;
  final int seedWalkStreakDays;
  final String seedOperatingMode = 'assist';
  final bool seedHasWalkedToday = true;

  @override
  Stream<int> watchDistanceTodayMeters() => Stream<int>.value(seedDistanceMeters);

  @override
  Stream<int> watchWalkingTimeMinutes() => Stream<int>.value(seedWalkingTimeMinutes);

  @override
  Stream<int> watchWeeklyTotalMeters() => Stream<int>.value(seedWeeklyTotalMeters);

  @override
  Stream<int> watchWeeklyWalkingTimeMinutes() => Stream<int>.value(seedWeeklyWalkingTimeMinutes);

  @override
  Stream<int> watchTodayTargetAchievementMeters() => Stream<int>.value(seedTodayTargetAchievementMeters);

  @override
  Stream<int> watchTodayTargetGoalMeters() => Stream<int>.value(seedTodayTargetGoalMeters);

  @override
  Stream<String> watchOperatingMode() => Stream<String>.value(seedOperatingMode);

  @override
  Stream<bool> watchHasWalkedToday() => Stream<bool>.value(seedHasWalkedToday);

  @override
  Stream<int> watchWalkStreakDays() => Stream<int>.value(seedWalkStreakDays);

  @override
  Future<void> markWalkedToday() async {}
}

class FirebaseDistanceRepository implements DistanceRepository {
  FirebaseDistanceRepository({
    FirebaseFirestore? firestore,
    this.collection = 'dashboard',
    this.documentId = 'albert',
    this.distanceField = 'distanceTodayMeters',
    this.walkingTimeField = 'walkingTimeMinutes',
    this.weeklyTotalMetersField = 'weeklyTotalMeters',
    this.weeklyWalkingTimeMinutesField = 'weeklyWalkingTimeMinutes',
    this.todayTargetAchievementMetersField = 'todayTargetAchievementMeters',
    this.todayTargetGoalMetersField = 'todayTargetGoalMeters',
    this.operatingModeField = 'operatingMode',
    this.hasWalkedTodayField = 'hasWalkedToday',
    this.walkStreakDaysField = 'walkStreakDays',
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  final String collection;
  final String documentId;
  final String distanceField;
  final String walkingTimeField;
  final String weeklyTotalMetersField;
  final String weeklyWalkingTimeMinutesField;
  final String todayTargetAchievementMetersField;
  final String todayTargetGoalMetersField;
  final String operatingModeField;
  final String hasWalkedTodayField;
  final String walkStreakDaysField;

  // Cache the document snapshot stream so every StreamBuilder reuses the
  // same underlying Firestore listener instead of opening a new one on
  // each rebuild. asBroadcastStream() lets multiple listeners subscribe.
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _docStream =
      _firestore
          .collection(collection)
          .doc(documentId)
          .snapshots()
          .asBroadcastStream();

  @override
  Stream<int> watchDistanceTodayMeters() => _mapInt(distanceField);

  @override
  Stream<int> watchWalkingTimeMinutes() => _mapInt(walkingTimeField);

  @override
  Stream<int> watchWeeklyTotalMeters() => _mapInt(weeklyTotalMetersField);

  @override
  Stream<int> watchWeeklyWalkingTimeMinutes() =>
      _mapInt(weeklyWalkingTimeMinutesField);

  @override
  Stream<int> watchTodayTargetAchievementMeters() =>
      _mapInt(todayTargetAchievementMetersField);

  @override
  Stream<int> watchTodayTargetGoalMeters() =>
      _mapInt(todayTargetGoalMetersField);

  @override
  Stream<String> watchOperatingMode() {
    return _docStream.map((snapshot) {
      final data = snapshot.data();
      final raw = data?[operatingModeField];
      if (raw is String && raw.trim().isNotEmpty) {
        return raw.trim().toLowerCase();
      }
      return 'assist';
    });
  }

  @override
  Stream<bool> watchHasWalkedToday() {
    return _docStream.map((snapshot) {
      final data = snapshot.data();
      final parsed = _toBool(data?[hasWalkedTodayField]);
      if (parsed != null) {
        return parsed;
      }

      final walkingMinutes = _toInt(data?[walkingTimeField]) ?? 0;
      final distanceMeters = _toInt(data?[distanceField]) ?? 0;
      return walkingMinutes > 0 || distanceMeters > 0;
    });
  }

  @override
  Stream<int> watchWalkStreakDays() => _mapInt(walkStreakDaysField);

  @override
  Future<void> markWalkedToday() async {
    final docRef = _firestore.collection(collection).doc(documentId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final data = snapshot.data();

      final alreadyWalkedToday = _toBool(data?[hasWalkedTodayField]) ?? false;
      final currentStreak = _toInt(data?[walkStreakDaysField]) ?? 0;

      if (alreadyWalkedToday) {
        transaction.set(
          docRef,
          {hasWalkedTodayField: true},
          SetOptions(merge: true),
        );
        return;
      }

      transaction.set(
        docRef,
        {
          hasWalkedTodayField: true,
          walkStreakDaysField: currentStreak + 1,
        },
        SetOptions(merge: true),
      );
    });
  }

  Stream<int> _mapInt(String fieldName) {
    return _docStream.map((snapshot) {
      final data = snapshot.data();
      return _toInt(data?[fieldName]) ?? 0;
    });
  }

  int? _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is double) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value);
    }
    return null;
  }

  bool? _toBool(dynamic value) {
    if (value is bool) {
      return value;
    }
    if (value is int) {
      return value != 0;
    }
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
        return true;
      }
      if (normalized == 'false' || normalized == 'no' || normalized == '0') {
        return false;
      }
    }
    return null;
  }
}
