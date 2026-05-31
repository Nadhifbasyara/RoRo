import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'rollator_policy.dart';

abstract class RollatorRepository {
  Future<RollatorRecord> createRollator({String? label});
  Future<RollatorClaimResult> claimCurrentUserToRollator(String rollatorCode);
  Future<void> unlinkCurrentUserFromRollator(String rollatorCode);
  Stream<RollatorRecord?> watchRollatorByCode(String rollatorCode);
}

class DemoRollatorRepository implements RollatorRepository {
  const DemoRollatorRepository();

  @override
  Future<RollatorRecord> createRollator({String? label}) async {
    final code = 'DEMO-${DateTime.now().millisecondsSinceEpoch}';
    return RollatorRecord(
      code: code,
      label: label,
      linkedAccountIds: const [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<RollatorClaimResult> claimCurrentUserToRollator(String rollatorCode) async {
    final code = rollatorCode.trim();
    if (code.isEmpty) {
      return const RollatorClaimResult.failure('Rollator code cannot be empty.');
    }
    return RollatorClaimResult.success(
      RollatorRecord(
        code: code,
        label: 'Demo Rollator',
        linkedAccountIds: const ['demo-user'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> unlinkCurrentUserFromRollator(String rollatorCode) async {}

  @override
  Stream<RollatorRecord?> watchRollatorByCode(String rollatorCode) {
    return Stream<RollatorRecord?>.value(
      RollatorRecord(
        code: rollatorCode.trim(),
        label: 'Demo Rollator',
        linkedAccountIds: const ['demo-user'],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }
}

class FirebaseRollatorRepository implements RollatorRepository {
  FirebaseRollatorRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.collection = 'rollators',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final String collection;
  static String? _fallbackUid;

  CollectionReference<Map<String, dynamic>> get _rollators => _firestore.collection(collection);

  Future<String> _ensureAuthenticatedUid() async {
    final existingUser = _auth.currentUser;
    if (existingUser != null && existingUser.uid.trim().isNotEmpty) {
      return existingUser.uid.trim();
    }

    try {
      final credential = await _auth.signInAnonymously();
      final uid = credential.user?.uid.trim();
      if (uid == null || uid.isEmpty) {
        throw StateError('Unable to create a temporary session. Check Firebase Auth setup.');
      }
      return uid;
    } on FirebaseAuthException catch (error) {
      if (error.code == 'unknown' && (error.message ?? '').contains('CONFIGURATION_NOT_FOUND')) {
        _fallbackUid ??= 'fallback-${DateTime.now().millisecondsSinceEpoch}';
        return _fallbackUid!;
      }
      throw StateError('Firebase Auth error: ${error.code} - ${error.message}');
    } catch (e) {
      _fallbackUid ??= 'fallback-${DateTime.now().millisecondsSinceEpoch}';
      return _fallbackUid!;
    }
  }

  @override
  Future<RollatorRecord> createRollator({String? label}) async {
    await _ensureAuthenticatedUid();
    final docRef = _rollators.doc();
    final cleanedLabel = label?.trim();
    final now = FieldValue.serverTimestamp();

    await docRef.set({
      'code': docRef.id,
      'label': cleanedLabel == null || cleanedLabel.isEmpty ? null : cleanedLabel,
      'linkedAccountIds': <String>[],
      'createdAt': now,
      'updatedAt': now,
    });

    return RollatorRecord(
      code: docRef.id,
      label: cleanedLabel == null || cleanedLabel.isEmpty ? null : cleanedLabel,
      linkedAccountIds: const [],
      createdAt: null,
      updatedAt: null,
    );
  }

  @override
  Future<RollatorClaimResult> claimCurrentUserToRollator(String rollatorCode) async {
    try {
      final uid = await _ensureAuthenticatedUid();

      final code = rollatorCode.trim();
      if (code.isEmpty) {
        return const RollatorClaimResult.failure('Rollator code cannot be empty.');
      }

      final docRef = _rollators.doc(code);
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw StateError('Rollator code not found.');
        }

        final record = RollatorRecord.fromSnapshot(snapshot);
        final updatedAccountIds = RollatorPolicy.claim(record.linkedAccountIds, uid);

        transaction.set(
          docRef,
          {
            'code': code,
            'label': record.label,
            'linkedAccountIds': updatedAccountIds,
            'createdAt': record.createdAt == null ? FieldValue.serverTimestamp() : Timestamp.fromDate(record.createdAt!),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
      final record = await watchRollatorByCode(code).first;
      return RollatorClaimResult.success(record ?? RollatorRecord(code: code, label: null, linkedAccountIds: const []));
    } on StateError catch (error) {
      return RollatorClaimResult.failure(error.message);
    } catch (error) {
      return RollatorClaimResult.failure(error.toString());
    }
  }

  @override
  Future<void> unlinkCurrentUserFromRollator(String rollatorCode) async {
    final code = rollatorCode.trim();
    if (code.isEmpty) {
      return;
    }

    final authUid = _auth.currentUser?.uid.trim();
    final uid = (authUid == null || authUid.isEmpty) ? _fallbackUid : authUid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    final docRef = _rollators.doc(code);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) {
        return;
      }

      final record = RollatorRecord.fromSnapshot(snapshot);
      final updatedIds = RollatorPolicy
          .normalizeAccountIds(record.linkedAccountIds)
          .where((id) => id != uid)
          .toList(growable: false);

      transaction.set(
        docRef,
        {
          'linkedAccountIds': updatedIds,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  @override
  Stream<RollatorRecord?> watchRollatorByCode(String rollatorCode) {
    final code = rollatorCode.trim();
    if (code.isEmpty) {
      return Stream<RollatorRecord?>.value(null);
    }

    return _rollators.doc(code).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }
      return RollatorRecord.fromSnapshot(snapshot);
    });
  }
}

class RollatorRecord {
  const RollatorRecord({
    required this.code,
    required this.linkedAccountIds,
    this.label,
    this.createdAt,
    this.updatedAt,
  });

  final String code;
  final String? label;
  final List<String> linkedAccountIds;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory RollatorRecord.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    final data = snapshot.data() ?? const <String, dynamic>{};
    return RollatorRecord(
      code: (data['code'] as String? ?? snapshot.id).trim(),
      label: (data['label'] as String?)?.trim(),
      linkedAccountIds: RollatorPolicy.normalizeAccountIds(
        (data['linkedAccountIds'] as List<dynamic>? ?? const <dynamic>[]).whereType<String>(),
      ),
      createdAt: _timestampToDateTime(data['createdAt']),
      updatedAt: _timestampToDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'label': label,
      'linkedAccountIds': linkedAccountIds,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
    };
  }

  static DateTime? _timestampToDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    }
    if (value is DateTime) {
      return value;
    }
    return null;
  }
}

class RollatorClaimResult {
  const RollatorClaimResult.success(this.rollator)
      : success = true,
        message = 'Rollator linked successfully.';

  const RollatorClaimResult.failure(this.message)
      : success = false,
        rollator = null;

  final bool success;
  final String message;
  final RollatorRecord? rollator;
}
