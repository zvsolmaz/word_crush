import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  int _gold = 0;
  AudioPool? _coinPool;

  final List<Map<String, dynamic>> _jokers = [
    {
      'name': 'Balık',
      'icon': 'assets/icons/gummy-fish.png',
      'description': 'Gridde rastgele harfleri yok eder.',
      'cost': 100,
      'key': 'joker_balik',
    },
    {
      'name': 'Tekerlek',
      'icon': 'assets/icons/gummy.png',
      'description': 'Seçilen harfin satır ve sütununu temizler.',
      'cost': 200,
      'key': 'joker_tekerlek',
    },
    {
      'name': 'Lolipop Kırıcı',
      'icon': 'assets/icons/lollipop.png',
      'description': 'Seçilen tek bir harfi yok eder.',
      'cost': 75,
      'key': 'joker_lolipop',
    },
    {
      'name': 'Serbest Değiştirme',
      'icon': 'assets/icons/drag.png',
      'description': 'Birbirine temas eden iki harfi yer değiştirir.',
      'cost': 125,
      'key': 'joker_degistirme',
    },
    {
      'name': 'Harf Karıştırma',
      'icon': 'assets/icons/gumball-machine.png',
      'description': 'Tüm harfleri rastgele karıştırır.',
      'cost': 300,
      'key': 'joker_karistirma',
    },
    {
      'name': 'Parti Güçlendiricisi',
      'icon': 'assets/icons/party-popper.png',
      'description': 'Tüm harfleri yok eder ve yenilerini düşürür.',
      'cost': 400,
      'key': 'joker_parti',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadGold();
    AudioPool.create(
      source: AssetSource('sounds/coin.wav'),
      maxPlayers: 4,
    ).then((pool) => _coinPool = pool);
  }

  @override
  void dispose() {
    _coinPool?.dispose();
    super.dispose();
  }

  Future<void> _loadGold() async {
    final prefs = await SharedPreferences.getInstance();
    int gold = prefs.getInt('gold') ?? 0;
    // Başlangıçta yüksek altın ver
    if (gold == 0) {
      gold = 99999;
      await prefs.setInt('gold', gold);
    }
    setState(() => _gold = gold);
  }

  Future<void> _buyJoker(Map<String, dynamic> joker) async {
    if (_gold < joker['cost']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yeterli altınınız yok!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    int currentCount = prefs.getInt(joker['key']) ?? 0;
    await prefs.setInt(joker['key'], currentCount + 1);
    await prefs.setInt('gold', _gold - (joker['cost'] as int));
    setState(() => _gold -= (joker['cost'] as int));
    _coinPool?.start(volume: 1.0); // ★ Satın alma sesi

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${joker['name']} satın alındı! (${currentCount + 1} adet)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('Market'),
        backgroundColor: const Color(0xFF6B3FA0),
        foregroundColor: Colors.white,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                const Text('🪙', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 4),
                Text(
                  '$_gold',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.yellow,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Altın bilgi kartı
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6B3FA0), Color(0xFF3D1A78)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mevcut Altın',
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                    SizedBox(height: 4),
                  ],
                ),
                Row(
                  children: [
                    const Text('🪙', style: TextStyle(fontSize: 32)),
                    const SizedBox(width: 8),
                    Text(
                      '$_gold',
                      style: const TextStyle(
                        color: Colors.yellow,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.3, end: 0),

          // Joker listesi
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _jokers.length,
              itemBuilder: (context, index) {
                final joker = _jokers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B3FA0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Image.asset(
                          joker['icon'],
                          width: 36,
                          height: 36,
                          errorBuilder: (_, __, ___) =>
                              const Text('?', style: TextStyle(fontSize: 28)),
                        ),
                      ),
                    ),
                    title: Text(
                      joker['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF3D1A78),
                      ),
                    ),
                    subtitle: Text(
                      joker['description'],
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () => _buyJoker(joker),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B3FA0),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🪙', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 4),
                          Text(
                            '${joker['cost']}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                    .slideX(begin: 0.3, end: 0);
              },
            ),
          ),
        ],
      ),
    );
  }
}