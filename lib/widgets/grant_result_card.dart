import 'package:flutter/material.dart';

class GrantResultCard extends StatelessWidget {
    final int chance;
    final String specialtyCode;
    final String specialtyName;
    final String competitionType;
    final String universityInfo;

    const GrantResultCard({
        super.key,
        required this.chance,
        required this.specialtyCode,
        required this.specialtyName,
        required this.competitionType,
        required this.universityInfo,
    });

    @override
    Widget build(BuildContext context) {
        return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Row(
                            children: [
                                // Chance Circle
                                Stack(
                                    alignment: Alignment.center,
                                    children: [
                                        SizedBox(
                                            height: 50,
                                            width: 50,
                                            child: CircularProgressIndicator(
                                                value: chance / 100,
                                                strokeWidth: 5,
                                                backgroundColor: Colors.grey.shade300,
                                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                                            ),
                                        ),
                                        Text('$chance%', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                            Text(specialtyCode, style: const TextStyle(fontWeight: FontWeight.bold)),
                                            Text(specialtyName, style: const TextStyle(color: Colors.grey)),
                                        ],
                                    ),
                                ),
                                Text(competitionType, style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                            ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(child: Text(universityInfo, style: const TextStyle(fontSize: 14))),
                            const Icon(Icons.keyboard_arrow_down, color: Colors.grey)
                          ],
                        )
                    ],
                ),
            ),
        );
    }
}