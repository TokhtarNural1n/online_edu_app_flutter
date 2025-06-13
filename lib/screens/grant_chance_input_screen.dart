import 'package:flutter/material.dart';
import 'grant_chance_results_screen.dart';

class GrantChanceInputScreen extends StatefulWidget {
  const GrantChanceInputScreen({super.key});

  @override
  State<GrantChanceInputScreen> createState() => _GrantChanceInputScreenState();
}

class _GrantChanceInputScreenState extends State<GrantChanceInputScreen> {
    double _currentScore = 127;
    bool _ruralQuota = true;
    bool _serpin = true;
    bool _largeFamily = false;
    bool _disability = false;
    String? _selectedSubjects = 'Биология - Химия';


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Узнать шансы на грант'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Профильные предметы', style: TextStyle(fontSize: 16, color: Colors.grey)),
            const SizedBox(height: 8),
            Container(
                 padding: const EdgeInsets.symmetric(horizontal: 12.0),
                 decoration: BoxDecoration(
                     color: Colors.white,
                     borderRadius: BorderRadius.circular(8.0),
                     border: Border.all(color: Colors.grey.shade300)),
                 child: DropdownButtonHideUnderline(
                     child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedSubjects,
                        items: <String>['Биология - Химия', 'Математика - Физика', 'История - География']
                             .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                        );
                        }).toList(),
                        onChanged: (String? newValue) {
                            setState(() {
                                _selectedSubjects = newValue;
                            });
                        },
                    ),
                 ),
            ),
            const SizedBox(height: 24),
            CheckboxListTile(
              title: const Text('Сельская квота'),
              value: _ruralQuota,
              onChanged: (bool? value) {
                setState(() {
                  _ruralQuota = value ?? false;
                });
              },
              activeColor: Colors.teal,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
             CheckboxListTile(
              title: const Text('Серпін'),
              value: _serpin,
              onChanged: (bool? value) {
                setState(() {
                  _serpin = value ?? false;
                });
              },
              activeColor: Colors.teal,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
             CheckboxListTile(
              title: const Text('Многодетная семья'),
              value: _largeFamily,
              onChanged: (bool? value) {
                setState(() {
                  _largeFamily = value ?? false;
                });
              },
              activeColor: Colors.teal,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: const Text('Инвалидность'),
              value: _disability,
              onChanged: (bool? value) {
                setState(() {
                  _disability = value ?? false;
                });
              },
              activeColor: Colors.teal,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),

            const Spacer(),
            Center(
                child: Text('Ваш балл: ${_currentScore.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            Slider(
              value: _currentScore,
              min: 0,
              max: 140,
              divisions: 140,
              label: _currentScore.round().toString(),
              onChanged: (double value) {
                setState(() {
                  _currentScore = value;
                });
              },
              activeColor: Colors.teal,
            ),
             const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const GrantChanceResultsScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Узнать шанс',
                style: TextStyle(fontSize: 16, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}