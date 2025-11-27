import 'package:flutter/material.dart';

class InstructionsModal extends StatelessWidget {
  const InstructionsModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(20),
          constraints: const BoxConstraints(maxHeight: 600, maxWidth: 500),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.purple.shade600],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Cara Bermain',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRuleCard(
                        icon: Icons.casino_rounded,
                        title: 'Tujuan Game',
                        color: Colors.blue,
                        content: [
                          '🎯 Capai kotak finish (100) dengan menjawab kuis TBC',
                          '📊 Jawab minimal kuis sesuai level yang dipilih',
                          '🏆 Menang dengan mencapai finish + kuis terpenuhi',
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      _buildRuleCard(
                        icon: Icons.play_arrow,
                        title: 'Cara Bermain',
                        color: Colors.green,
                        content: [
                          '🎲 Lempar dadu untuk bergerak',
                          '❓ Jawab kuis TBC saat mendarat di kotak tertentu',
                          '🔄 Bergantian dengan pemain lain (multiplayer)',
                          '⏱️ Kuis memiliki batas waktu',
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      _buildRuleCard(
                        icon: Icons.trending_up,
                        title: 'Tangga (Perilaku Baik)',
                        color: Colors.orange,
                        content: [
                          '📈 Naik tangga = perilaku pencegahan TBC',
                          '🎉 Dapat bonus poin dan naik level',
                          '💡 Pelajari tips pencegahan TBC',
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      _buildRuleCard(
                        icon: Icons.trending_down,
                        title: 'Ular (Perilaku Buruk)',
                        color: Colors.red,
                        content: [
                          '📉 Turun ular = perilaku berisiko TBC',
                          '😱 Kehilangan progress dan turun level',
                          '⚠️ Pelajari bahaya perilaku buruk',
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      _buildRuleCard(
                        icon: Icons.quiz,
                        title: 'Sistem Kuis',
                        color: Colors.purple,
                        content: [
                          '📚 Kuis tentang TBC dan kesehatan',
                          '✅ Jawab benar = lanjut permainan',
                          '❌ Jawab salah = pelajari jawaban yang benar',
                          '🎯 Capai jumlah kuis minimal untuk menang',
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Bottom button
              Container(
                padding: const EdgeInsets.all(20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Mengerti, Mulai Bermain!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRuleCard({
    required IconData icon,
    required String title,
    required MaterialColor color,
    required List<String> content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.shade200, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color.shade800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...content.map((text) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
              )),
        ],
      ),
    );
  }
}