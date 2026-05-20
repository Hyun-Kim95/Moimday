/// Extract invite token from pasted URL or deep link.
String? parseInviteToken(String input) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return null;
  final uri = Uri.tryParse(trimmed);
  if (uri != null) {
    if (uri.scheme == 'moimday' && uri.host == 'invite') {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : uri.path.replaceFirst('/', '');
    }
    final segments = uri.pathSegments;
    final inviteIdx = segments.indexOf('invite');
    if (inviteIdx >= 0 && inviteIdx + 1 < segments.length) {
      return segments[inviteIdx + 1];
    }
  }
  if (!trimmed.contains('/')) return trimmed;
  return null;
}
