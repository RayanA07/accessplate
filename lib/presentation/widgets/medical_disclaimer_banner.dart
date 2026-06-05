import 'package:flutter/material.dart';

import '../copy/app_copy.dart';
import 'section_card.dart';

class MedicalDisclaimerBanner extends StatelessWidget {
  const MedicalDisclaimerBanner({super.key, required this.copy});

  final AppCopy copy;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      borderRadius: 22,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      tintColor: const Color(0xFFE8F0FF),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              copy.medicalDisclaimerShort,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
