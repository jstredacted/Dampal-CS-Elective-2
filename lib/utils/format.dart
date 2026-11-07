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
