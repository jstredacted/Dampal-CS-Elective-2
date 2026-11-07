import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product_filter.dart';
import '../providers/product_filter_provider.dart';
import '../utils/format.dart';

class PriceFilter extends ConsumerStatefulWidget {
  const PriceFilter({super.key});

  @override
  ConsumerState<PriceFilter> createState() => _PriceFilterState();
}

class _PriceFilterState extends ConsumerState<PriceFilter> {
  // Holds the handles' position only while the user is dragging. When it is
  // null, the slider shows the price range saved in the provider.
  RangeValues? _dragValues;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(productFilterProvider);
    final values = _dragValues ?? RangeValues(filter.minPrice, filter.maxPrice);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Price', style: Theme.of(context).textTheme.titleSmall),
            const Spacer(),
            Text(
              '${formatPeso(values.start)} – ${formatPeso(values.end)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        RangeSlider(
          values: values,
          min: minPriceLimit,
          max: maxPriceLimit,
          // 30 divisions → the handles move in ₱500 steps.
          divisions: 30,
          labels: RangeLabels(formatPeso(values.start), formatPeso(values.end)),
          onChanged: (newValues) {
            setState(() => _dragValues = newValues);
          },
          // Only query Supabase once the user lets go of the handle.
          onChangeEnd: (newValues) {
            setState(() => _dragValues = null);
            ref
                .read(productFilterProvider.notifier)
                .setPriceRange(newValues.start, newValues.end);
          },
        ),
      ],
    );
  }
}
