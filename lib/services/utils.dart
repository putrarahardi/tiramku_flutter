String formatNumber(dynamic value) {
  if (value == null) return '0';
  final num = value is int ? value : int.tryParse(value.toString()) ?? 0;
  return num.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]}.',
      );
}
