import 'package:flutter/material.dart';
import 'first_aid_detail_screen.dart';
import '../../utils/custom_header.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class EmergencyKnowledge {
  final String title;
  final List<String> keywords;
  final List<String> advice;
  final bool requiresImmediateVet;

  const EmergencyKnowledge({
    required this.title,
    required this.keywords,
    required this.advice,
    required this.requiresImmediateVet,
  });
}

class FirstAidScreen extends StatefulWidget {
  const FirstAidScreen({super.key});

  @override
  State<FirstAidScreen> createState() => _FirstAidScreenState();
}

class _FirstAidScreenState extends State<FirstAidScreen> {
  final List<EmergencyKnowledge> emergencyDatabase = const [
    EmergencyKnowledge(
      title: 'Vomiting & Upset Stomach',
      keywords: [
        'vomit',
        'vomiting',
        'puke',
        'puking',
        'throw up',
        'throwing up',
        'stomach',
        'nausea'
      ],
      advice: [
        'Withhold food for 12-24 hours (but provide small amounts of water).',
        'After fasting, offer a bland diet (boiled chicken and white rice).',
        'Monitor for lethargy or blood in the vomit.',
      ],
      requiresImmediateVet: false,
    ),
    EmergencyKnowledge(
      title: 'Diarrhea',
      keywords: ['diarrhea', 'poop', 'stool', 'liquid', 'loose', 'bowel'],
      advice: [
        'Ensure your pet stays hydrated by providing plenty of fresh water.',
        'Feed a bland diet like boiled plain chicken breast and white rice.',
        'Add a small amount of plain canned pumpkin (not pie filling).',
      ],
      requiresImmediateVet: false,
    ),
    EmergencyKnowledge(
      title: 'Bleeding & Wounds',
      keywords: [
        'bleed',
        'blood',
        'bleeding',
        'cut',
        'wound',
        'scrape',
        'bite',
        'laceration'
      ],
      advice: [
        'Apply direct, firm pressure to the wound with a clean cloth or gauze for 5-10 minutes.',
        'Do not keep lifting the cloth to check if bleeding stopped.',
        'If blood soaks through, add another layer of cloth on top.',
        'Elevate the injured area if possible.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Choking',
      keywords: [
        'choke',
        'choking',
        'breathe',
        'breathing',
        'throat',
        'gasping',
        'stuck'
      ],
      advice: [
        'Check inside the mouth for visible objects and carefully remove them if safe.',
        'Do not blindly reach down the throat as you may push the object deeper.',
        'If the pet is unconscious, perform a modified Heimlich maneuver (gentle but firm pressure below the rib cage).',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Poisoning / Toxin Ingestion',
      keywords: [
        'poison',
        'toxic',
        'chocolate',
        'grape',
        'onion',
        'garlic',
        'antifreeze',
        'xylitol',
        'swallowed',
        'ate',
        'ingested',
        'chemical'
      ],
      advice: [
        'Identify exactly what the pet ate, how much, and when.',
        'Do NOT induce vomiting unless specifically instructed by a veterinarian.',
        'Call the Pet Poison Helpline or your local emergency vet immediately.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Seizures',
      keywords: [
        'seizure',
        'shaking',
        'convulsion',
        'convulsing',
        'fit',
        'twitching',
        'tremor'
      ],
      advice: [
        'Do not try to restrain the pet. Keep hands away from their mouth.',
        'Move furniture or objects away to prevent injury.',
        'Time the seizure (most last less than 2-3 minutes).',
        'Keep the environment dark and quiet.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Heatstroke',
      keywords: [
        'heat',
        'hot',
        'heatstroke',
        'panting',
        'sun',
        'summer',
        'overheated',
        'temperature'
      ],
      advice: [
        'Move the pet to a cool, shaded, or air-conditioned area immediately.',
        'Apply cool (NOT ice-cold) water to their body, especially paws, belly, and armpits.',
        'Offer fresh water to drink, but do not force them.',
        'Use a fan to help cool them down.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Broken Bones / Fractures',
      keywords: [
        'break',
        'broke',
        'broken',
        'bone',
        'limp',
        'leg',
        'fracture',
        'hit',
        'car',
        'fall'
      ],
      advice: [
        'Minimize the pet\'s movement to prevent further injury.',
        'Support the injured limb with a makeshift splint or rolled towel, but do not force it.',
        'Use a flat board or stretcher to move the pet.',
        'Be careful, as pets in severe pain may bite.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Burns',
      keywords: [
        'burn',
        'burned',
        'fire',
        'hot water',
        'electrical',
        'chemical',
        'scald'
      ],
      advice: [
        'Run cool water over the burn for 10-15 minutes.',
        'Do NOT apply ice, butter, ointments, or creams.',
        'Cover the area with a loose, clean, damp cloth.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Allergic Reaction',
      keywords: [
        'swelling',
        'hive',
        'hives',
        'bite',
        'sting',
        'bee',
        'allergic',
        'allergy',
        'face',
        'swollen'
      ],
      advice: [
        'Check for difficulty breathing, which is a life-threatening emergency.',
        'If stung by a bee, try to scrape the stinger out with a credit card (do not squeeze).',
        'Apply a cold compress to reduce swelling.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Eye Injury',
      keywords: [
        'eye',
        'squinting',
        'red',
        'tear',
        'scratch',
        'cornea',
        'blind'
      ],
      advice: [
        'Prevent your pet from rubbing or scratching the eye (use an Elizabethan collar if available).',
        'Flush the eye gently with sterile saline solution if there is debris.',
        'Do not apply any human eye drops.',
      ],
      requiresImmediateVet: true,
    ),
    EmergencyKnowledge(
      title: 'Unconsciousness / CPR',
      keywords: [
        'faint',
        'unconscious',
        'collapse',
        'collapsed',
        'cpr',
        'pulse',
        'heartbeat',
        'not responding'
      ],
      advice: [
        'Check for a heartbeat and breathing.',
        'If there is no heartbeat, lay the pet on their right side.',
        'Perform chest compressions (100-120 per minute) over the widest part of the chest.',
        'Provide rescue breaths if trained to do so.',
      ],
      requiresImmediateVet: true,
    ),
  ];

  final List<Map<String, dynamic>> firstAidTopics = const [
    {
      'title': 'Bleeding & Wounds',
      'icon': Icons.healing,
      'color': Colors.red,
      'steps': [
        'Stay calm and keep your pet calm',
        'Apply direct pressure with a clean cloth or gauze',
        'Hold pressure for 5-10 minutes without lifting',
        'If bleeding continues, apply additional layers without removing the first',
        'For severe bleeding, elevate the wound if possible',
        'Seek immediate veterinary care',
      ],
      'warnings': [
        'Do not use hydrogen peroxide on deep wounds',
        'Do not remove objects embedded in wounds',
        'Watch for signs of shock (pale gums, rapid breathing)',
      ],
    },
    {
      'title': 'Choking',
      'icon': Icons.warning,
      'color': Colors.orange,
      'steps': [
        'Check if the pet can breathe or cough',
        'If conscious, open mouth and look for visible obstruction',
        'Try to remove the object carefully with fingers or tweezers',
        'For dogs: Perform Heimlich maneuver - place hands below ribcage and thrust upward',
        'For cats: Hold upside down and apply pressure below ribcage',
        'Rush to vet immediately if object cannot be removed',
      ],
      'warnings': [
        'Do not blindly reach into throat - may push object deeper',
        'Be careful of being bitten',
        'Time is critical - seek help immediately',
      ],
    },
    {
      'title': 'Poisoning',
      'icon': Icons.dangerous,
      'color': Colors.purple,
      'steps': [
        'Identify the substance if possible',
        'Remove pet from the source',
        'Do NOT induce vomiting unless directed by a vet',
        'Call veterinarian or poison control immediately',
        'Bring the substance container to the vet',
        'Monitor breathing and consciousness',
      ],
      'warnings': [
        'Never induce vomiting for corrosive substances',
        'Common poisons: chocolate, grapes, onions, xylitol, antifreeze',
        'Time is critical - seek help immediately',
      ],
    },
    {
      'title': 'Heatstroke',
      'icon': Icons.thermostat,
      'color': Colors.deepOrange,
      'steps': [
        'Move pet to a cool, shaded area immediately',
        'Apply cool (not cold) water to body, especially paws and belly',
        'Offer small amounts of cool water to drink',
        'Place wet towels on pet and use a fan',
        'Take rectal temperature if possible (normal: 100-102.5°F)',
        'Transport to vet immediately',
      ],
      'warnings': [
        'Do not use ice or very cold water',
        'Never leave pets in hot cars',
        'Brachycephalic breeds are more susceptible',
      ],
    },
    {
      'title': 'Fractures & Broken Bones',
      'icon': Icons.accessibility_new,
      'color': Colors.blue,
      'steps': [
        'Keep pet as still as possible',
        'Do not try to set the bone yourself',
        'If leg is broken, gently support it',
        'Use a board or firm surface as a stretcher',
        'Cover any open wounds with clean cloth',
        'Transport carefully to veterinarian',
      ],
      'warnings': [
        'Do not move pet unnecessarily',
        'Watch for shock symptoms',
        'Internal injuries may not be visible',
      ],
    },
    {
      'title': 'Seizures',
      'icon': Icons.vibration,
      'color': Colors.indigo,
      'steps': [
        'Stay calm and time the seizure',
        'Remove nearby objects that could cause injury',
        'Do NOT put anything in the pet\'s mouth',
        'Keep hands away from mouth',
        'After seizure, keep pet calm and comfortable',
        'Contact vet, especially if seizure lasts over 5 minutes',
      ],
      'warnings': [
        'Never restrain during a seizure',
        'Multiple seizures require immediate care',
        'Note seizure duration and symptoms',
      ],
    },
    {
      'title': 'Dehydration',
      'icon': Icons.water_drop,
      'color': Colors.cyan,
      'steps': [
        'Check for dehydration: lift skin - should snap back quickly',
        'Check gums - should be moist and pink',
        'Offer small amounts of water frequently',
        'Use ice chips if pet won\'t drink',
        'Monitor urination',
        'Seek vet care if severe or persists',
      ],
      'warnings': [
        'Signs: dry gums, sunken eyes, lethargy',
        'Can be life-threatening if severe',
        'Common in hot weather or illness',
      ],
    },
    {
      'title': 'Burns',
      'icon': Icons.local_fire_department,
      'color': Colors.deepOrange,
      'steps': [
        'Remove pet from heat source',
        'Cool the burn with lukewarm (not cold) water for 10-20 minutes',
        'Do not apply ice',
        'Cover with clean, damp cloth',
        'Do not apply ointments or butter',
        'Seek immediate veterinary care',
      ],
      'warnings': [
        'Chemical burns need immediate flushing',
        'Electrical burns may have internal damage',
        'All burns should be examined by a vet',
      ],
    },
  ];

  EmergencyKnowledge? _analyzeEmergency(String query) {
    if (query.trim().isEmpty) return null;

    final lowerQuery = query.toLowerCase();

    // Simple punctuation removal and tokenization
    final words = lowerQuery.replaceAll(RegExp(r'[^\w\s]'), '').split(' ');

    EmergencyKnowledge? bestMatch;
    int maxScore = 0;

    for (final knowledge in emergencyDatabase) {
      int score = 0;
      for (final keyword in knowledge.keywords) {
        // Exact word match or partial word match depending on length
        if (words.contains(keyword)) {
          score += 2;
        } else if (lowerQuery.contains(keyword)) {
          score += 1;
        }
      }
      if (score > maxScore) {
        maxScore = score;
        bestMatch = knowledge;
      }
    }

    // Threshold to ensure we don't return entirely irrelevant matches
    if (maxScore >= 1) {
      return bestMatch;
    }
    return null;
  }

  void _openAssistant() {
    final TextEditingController emergencyController = TextEditingController();
    bool isAnalyzing = false;
    EmergencyKnowledge? matchedEmergency;
    bool hasSearched = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                height: 0.75.sh,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(20.r),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B35),
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(24.r)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.medical_services,
                              color: Colors.white, size: 28.r),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Text(
                              'Emergency Assistant',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(20.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Describe the emergency:',
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: emergencyController,
                              maxLines: 4,
                              decoration: InputDecoration(
                                hintText:
                                    'e.g., My dog just ate chocolate, what should I do?',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                            ),
                            SizedBox(height: 16.h),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isAnalyzing
                                    ? null
                                    : () async {
                                        final query =
                                            emergencyController.text.trim();
                                        if (query.isEmpty) return;

                                        setState(() {
                                          isAnalyzing = true;
                                          hasSearched = false;
                                        });

                                        // Simulate a brief delay for analysis UX
                                        await Future.delayed(
                                            const Duration(milliseconds: 600));

                                        final result = _analyzeEmergency(query);

                                        setState(() {
                                          isAnalyzing = false;
                                          matchedEmergency = result;
                                          hasSearched = true;
                                        });
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF6B35),
                                  foregroundColor: Colors.white,
                                  padding:
                                      EdgeInsets.symmetric(vertical: 16.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                ),
                                child: isAnalyzing
                                    ? SizedBox(
                                        height: 24.h,
                                        width: 24.w,
                                        child: const CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
                                        'Analyze Situation',
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: 24.h),
                            if (hasSearched && matchedEmergency != null) ...[
                              Text(
                                'Identified: ${matchedEmergency!.title}',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFFFF6B35),
                                ),
                              ),
                              SizedBox(height: 12.h),
                              if (matchedEmergency!.requiresImmediateVet)
                                Container(
                                  padding: EdgeInsets.all(12.r),
                                  margin: EdgeInsets.only(bottom: 12.h),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8.r),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning,
                                          color: Colors.red[700], size: 20.r),
                                      SizedBox(width: 8.w),
                                      Expanded(
                                        child: Text(
                                          'Seek immediate veterinary care!',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp,
                                            ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border:
                                      Border.all(color: Colors.orange[200]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: matchedEmergency!.advice
                                      .map((step) => Padding(
                                            padding: EdgeInsets.only(
                                                bottom: 8.r),
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('• ',
                                                    style: TextStyle(
                                                        fontSize: 14.sp,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                Expanded(
                                                  child: Text(
                                                    step,
                                                    style: TextStyle(
                                                      fontSize: 14.sp,
                                                      height: 1.4,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ),
                            ] else if (hasSearched &&
                                matchedEmergency == null) ...[
                              Container(
                                padding: EdgeInsets.all(16.r),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12.r),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Could not confidently identify the emergency.',
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    SizedBox(height: 8.h),
                                    Text(
                                      'Please check the manual categories below or seek immediate veterinary care if the situation is critical.',
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomHeaderScreen(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAssistant,
        icon: Icon(Icons.search),
        label: Text('Need help?'),
        backgroundColor: const Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 10.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 Icon(
                   Icons.medical_services,
                   size: 32.r,
                   color: Colors.white,
                 ),
                 SizedBox(height: 12.h),
                 Text(
                   'Emergency First Aid',
                   style: TextStyle(
                     fontSize: 26.sp,
                     fontWeight: FontWeight.w900,
                     color: Colors.white,
                     letterSpacing: 0.5,
                   ),
                 ),
                 SizedBox(height: 4.h),
                 Text(
                   'Quick guidance for pet emergencies',
                   style: TextStyle(
                     fontSize: 14.sp,
                     color: Colors.white70,
                   ),
                 ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(24.r),
              itemCount: firstAidTopics.length,
              itemBuilder: (context, index) {
                final topic = firstAidTopics[index];
                return Container(
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 20.r,
                        offset: Offset(0, 10.h),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FirstAidDetailScreen(
                              title: topic['title'],
                              icon: topic['icon'],
                              color: topic['color'],
                              steps: List<String>.from(topic['steps']),
                              warnings: List<String>.from(topic['warnings']),
                            ),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(24.r),
                      child: Padding(
                        padding: EdgeInsets.all(20.r),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(16.r),
                              decoration: BoxDecoration(
                                color: (topic['color'] as Color)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                               child: Icon(
                                 topic['icon'],
                                 color: topic['color'],
                                 size: 28.r,
                               ),
                            ),
                             SizedBox(width: 16.w),
                            Expanded(
                              child: Text(
                                topic['title'],
                                 style: TextStyle(
                                   fontSize: 16.sp,
                                   fontWeight: FontWeight.w800,
                                   color: Colors.black87,
                                 ),
                              ),
                            ),
                             Container(
                               padding: EdgeInsets.all(10.r),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6B35)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                               child: Icon(
                                 Icons.arrow_forward_ios,
                                 color: const Color(0xFFFF6B35),
                                 size: 14.r,
                               ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          /* Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
          ),*/
        ],
      ),
    );
  }
}
