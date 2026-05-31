class RollatorPolicy {
  static const int maxLinkedAccounts = 2;

  static List<String> normalizeAccountIds(Iterable<String> accountIds) {
    final normalized = <String>[];
    for (final accountId in accountIds) {
      final trimmed = accountId.trim();
      if (trimmed.isEmpty) {
        continue;
      }
      if (!normalized.contains(trimmed)) {
        normalized.add(trimmed);
      }
    }
    return normalized;
  }

  static bool canClaim(List<String> linkedAccountIds, String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      return false;
    }

    final normalizedIds = normalizeAccountIds(linkedAccountIds);
    if (normalizedIds.contains(normalizedUid)) {
      return true;
    }

    return normalizedIds.length < maxLinkedAccounts;
  }

  static List<String> claim(List<String> linkedAccountIds, String uid) {
    final normalizedUid = uid.trim();
    if (normalizedUid.isEmpty) {
      throw StateError('User must be signed in to claim a rollator.');
    }

    final normalizedIds = normalizeAccountIds(linkedAccountIds);
    if (normalizedIds.contains(normalizedUid)) {
      return normalizedIds;
    }

    if (normalizedIds.length >= maxLinkedAccounts) {
      throw StateError('Rollator already has the maximum number of accounts.');
    }

    return <String>[...normalizedIds, normalizedUid];
  }
}
