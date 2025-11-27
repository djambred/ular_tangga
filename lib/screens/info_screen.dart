import 'package:flutter/material.dart';
import 'instructions_modal.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.purple.shade600,
              Colors.purple.shade400,
              Colors.pink.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  title: const Text(
                    'Informasi TBC',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.purple.shade700,
                          Colors.purple.shade500,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Cara Bermain Button
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            PageRouteBuilder(
                              pageBuilder: (context, animation, secondaryAnimation) => 
                                const InstructionsModal(),
                              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                return FadeTransition(opacity: animation, child: child);
                              },
                              opaque: false,
                            ),
                          );
                        },
                        icon: const Icon(Icons.school_rounded, size: 24),
                        label: const Text(
                          'Cara Bermain',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                      ),
                    ),
                    
                    _buildInfoCard(
                      icon: Icons.medical_information,
                      title: 'Apa itu TBC?',
                      content:
                          'Tuberkulosis (TBC) adalah penyakit menular yang disebabkan oleh bakteri Mycobacterium tuberculosis. TBC biasanya menyerang paru-paru, tetapi juga bisa menyerang organ tubuh lainnya.',
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.coronavirus,
                      title: 'Bagaimana TBC Menular?',
                      content:
                          'TBC menular melalui udara ketika penderita TBC batuk, bersin, atau berbicara. Droplet (percikan dahak) yang mengandung bakteri dapat terhirup oleh orang di sekitarnya.',
                      color: Colors.red,
                      additionalContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildBulletPoint('Tidak menular melalui:'),
                          _buildBulletPoint('• Berjabat tangan', isSubPoint: true),
                          _buildBulletPoint('• Berbagi makanan/minuman', isSubPoint: true),
                          _buildBulletPoint('• Menyentuh barang', isSubPoint: true),
                          _buildBulletPoint('• Pelukan', isSubPoint: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.sick,
                      title: 'Gejala TBC',
                      color: Colors.orange,
                      additionalContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBulletPoint('• Batuk berdahak selama 2 minggu atau lebih'),
                          _buildBulletPoint('• Batuk berdarah'),
                          _buildBulletPoint('• Demam (terutama sore/malam)'),
                          _buildBulletPoint('• Berkeringat di malam hari'),
                          _buildBulletPoint('• Berat badan menurun'),
                          _buildBulletPoint('• Nafsu makan berkurang'),
                          _buildBulletPoint('• Mudah lelah'),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Jika mengalami gejala di atas, segera periksa ke dokter!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.medication,
                      title: 'Pengobatan TBC',
                      content:
                          'TBC BISA DISEMBUHKAN! Pengobatan TBC memerlukan waktu minimal 6 bulan dan harus diminum secara teratur tanpa putus.',
                      color: Colors.green,
                      additionalContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          _buildBulletPoint('Fase Intensif (2 bulan):'),
                          _buildBulletPoint('• Minum 4 jenis obat setiap hari', isSubPoint: true),
                          const SizedBox(height: 8),
                          _buildBulletPoint('Fase Lanjutan (4 bulan):'),
                          _buildBulletPoint('• Minum 2 jenis obat setiap hari', isSubPoint: true),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Obat TBC GRATIS di Puskesmas dan RS Pemerintah!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.shield,
                      title: 'Pencegahan TBC',
                      color: Colors.teal,
                      additionalContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBulletPoint('✓ Imunisasi BCG untuk bayi'),
                          _buildBulletPoint('✓ Tutup mulut saat batuk/bersin'),
                          _buildBulletPoint('✓ Buka jendela rumah setiap hari'),
                          _buildBulletPoint('✓ Jemur kasur di bawah sinar matahari'),
                          _buildBulletPoint('✓ Gunakan masker jika ada yang sakit'),
                          _buildBulletPoint('✓ Makan makanan bergizi'),
                          _buildBulletPoint('✓ Olahraga teratur'),
                          _buildBulletPoint('✓ Istirahat cukup'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    _buildInfoCard(
                      icon: Icons.do_not_disturb,
                      title: 'Mitos vs Fakta',
                      color: Colors.indigo,
                      additionalContent: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMythFact(
                            myth: '❌ TBC adalah penyakit kutukan',
                            fact: '✅ TBC disebabkan oleh bakteri',
                          ),
                          const Divider(height: 20),
                          _buildMythFact(
                            myth: '❌ TBC tidak bisa disembuhkan',
                            fact: '✅ TBC bisa disembuhkan dengan obat',
                          ),
                          const Divider(height: 20),
                          _buildMythFact(
                            myth: '❌ TBC menular lewat pelukan',
                            fact: '✅ TBC hanya menular lewat udara',
                          ),
                          const Divider(height: 20),
                          _buildMythFact(
                            myth: '❌ Obat TBC harus beli sendiri',
                            fact: '✅ Obat TBC gratis di Puskesmas',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.amber.shade400, Colors.orange.shade400],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.call, color: Colors.white, size: 40),
                          const SizedBox(height: 10),
                          const Text(
                            'Butuh Bantuan?',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Hubungi Puskesmas atau RS terdekat\nuntuk konsultasi lebih lanjut',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    String? content,
    required Color color,
    Widget? additionalContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          if (content != null) ...[
            const SizedBox(height: 15),
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
                height: 1.6,
              ),
            ),
          ],
          if (additionalContent != null) ...[
            const SizedBox(height: 10),
            additionalContent,
          ],
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text, {bool isSubPoint = false}) {
    return Padding(
      padding: EdgeInsets.only(
        left: isSubPoint ? 20 : 0,
        bottom: 6,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey.shade700,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildMythFact({required String myth, required String fact}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MITOS:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          myth,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'FAKTA:',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          fact,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
