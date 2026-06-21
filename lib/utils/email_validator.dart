bool isValidEmailAddress(String value) {
  final email = value.trim();
  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email);
}
