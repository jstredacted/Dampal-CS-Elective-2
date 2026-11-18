// Formats a price like 12999 as "₱12,999.00".
String formatPeso(double amount) {
  final parts = amount.toStringAsFixed(2).split('.');
  final whole = parts[0];
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    // Add a comma before every group of three digits from the right.
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  return '₱$buffer.${parts[1]}';
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

// Formats a date like "Nov 18, 2026 · 3:05 PM".
String formatDateTime(DateTime date) {
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour < 12 ? 'AM' : 'PM';
  return '${_months[date.month - 1]} ${date.day}, ${date.year} · '
      '$hour:$minute $period';
}
