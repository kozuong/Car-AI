import 'package:flutter/material.dart';
import '../config/constants.dart';

class PerformanceStats extends StatelessWidget {
  final String power;
  final String acceleration;
  final String topSpeed;
  final String langCode;

  const PerformanceStats({
    super.key,
    required this.power,
    required this.acceleration,
    required this.topSpeed,
    required this.langCode,
  });

  String _cleanNumber(String value) {
    final regex = RegExp(r'(\d+\.?\d*)');
    final match = regex.firstMatch(value);
    return match?.group(1) ?? value;
  }

  String _getUnit(String value) {
    if (value.toLowerCase().contains('hp')) return 'hp';
    if (value.toLowerCase().contains('mph')) return 'mph';
    if (value.toLowerCase().contains('km/h')) return 'km/h';
    if (value.toLowerCase().contains('s')) return 's';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVi = langCode == 'vi';

    return Card(
      elevation: AppConstants.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (power.isNotEmpty)
              _buildStat(
                context,
                _cleanNumber(power),
                _getUnit(power),
                isVi ? 'Công suất' : 'Power',
              ),
            if (acceleration.isNotEmpty)
              _buildStat(
                context,
                _cleanNumber(acceleration),
                _getUnit(acceleration),
                isVi ? 'Tăng tốc' : 'Acceleration',
              ),
            if (topSpeed.isNotEmpty)
              _buildStat(
                context,
                _cleanNumber(topSpeed),
                _getUnit(topSpeed),
                isVi ? 'Tốc độ tối đa' : 'Top Speed',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String value,
    String unit,
    String label,
  ) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            unit,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
} 