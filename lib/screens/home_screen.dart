import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'game_screen.dart';
import 'score_screen.dart';
import 'market_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _username = '';
  int _gold = 0;
  AudioPool? _clickPool;
  final Map<String, bool> _buttonPressed = {};

  @override
  void dispose() {
    _clickPool?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    // Click sesi önceden yükle — gecikme olmaz
    AudioPool.create(
      source: AssetSource('sounds/click.wav'),
      maxPlayers: 4,
    ).then((pool) => _clickPool = pool);
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username') ?? '';
      _gold = prefs.getInt('gold') ?? 99999;
    });
    if (_gold == 0) {
      await prefs.setInt('gold', 99999);
      setState(() => _gold = 99999);
    }
  }

  Future<void> _changeUsername() async {
    final controller = TextEditingController(text: _username);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Adını Değiştir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Yeni kullanıcı adı',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString('username', newName);
                setState(() => _username = newName);
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B3FA0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _startNewGame() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Grid Boyutu Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _gridButton('6x6 Grid', 'Zor Seviye', 6, context),
            const SizedBox(height: 10),
            _gridButton('8x8 Grid', 'Orta Seviye', 8, context),
            const SizedBox(height: 10),
            _gridButton('10x10 Grid', 'Kolay Seviye', 10, context),
          ],
        ),
      ),
    );
  }

  Widget _gridButton(
      String title, String subtitle, int size, BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _playClickSound();
          Future.delayed(const Duration(milliseconds: 80), () {
            Navigator.pop(ctx);
            _selectMoves(size);
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B3FA0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  void _selectMoves(int gridSize) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hamle Sayısı Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _moveButton('Kolay', '25 Hamle', 25, gridSize, context),
            const SizedBox(height: 10),
            _moveButton('Orta', '20 Hamle', 20, gridSize, context),
            const SizedBox(height: 10),
            _moveButton('Zor', '15 Hamle', 15, gridSize, context),
          ],
        ),
      ),
    );
  }

  Widget _moveButton(String level, String subtitle, int moves, int gridSize,
      BuildContext ctx) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          _playClickSound();
          Future.delayed(const Duration(milliseconds: 80), () {
            Navigator.pop(ctx);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GameScreen(gridSize: gridSize, maxMoves: moves),
              ),
            ).then((_) => _loadData());
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF6B3FA0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Column(
          children: [
            Text(level,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            Text(subtitle,
                style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      body: SafeArea(
        child: Column(
          children: [
            // Üst bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Kullanıcı adı - tıklanabilir
                  GestureDetector(
                    onTap: _changeUsername,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B3FA0).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color:
                                const Color(0xFF6B3FA0).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircleAvatar(
                            backgroundColor: Color(0xFF6B3FA0),
                            radius: 14,
                            child: Icon(Icons.person,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _username,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B3FA0),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.edit,
                              size: 14, color: Color(0xFF6B3FA0)),
                        ],
                      ),
                    ),
                  ),
                  // Altın göstergesi
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 4),
                        Text(
                          '$_gold',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Logo
            const Spacer(),
            const Icon(Icons.grid_on, size: 80, color: Color(0xFF6B3FA0)),
            const SizedBox(height: 8),
            Text(
              'WORD CRUSH',
              style: GoogleFonts.nunito(
                fontSize: 36,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF6B3FA0),
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 60),

            // Butonlar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  _mainButton('🎮  Yeni Oyun', _startNewGame),
                  const SizedBox(height: 16),
                  _mainButton('🏆  Skor Tablosu', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ScoreScreen()),
                    );
                  }),
                  const SizedBox(height: 16),
                  _mainButton('🛒  Market', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MarketScreen()),
                    ).then((_) => _loadData());
                  }),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _playClickSound() {
    _clickPool?.start(volume: 1.0);
  }

  Widget _mainButton(String text, VoidCallback onTap) {
    final isPressed = _buttonPressed[text] ?? false;

    // Klavye tuşu anatomisi (2. resim referansı):
    // [  dış çerçeve / gövde  ]  ← koyu mor, yuvarlak köşe
    //   [ yüzey ]               ← açık mor gradient, içe gömülü
    //     parlama şeridi         ← üst sağda beyaz yansıma

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _buttonPressed[text] = true);
        _playClickSound();
      },
      onTapUp: (_) {
        setState(() => _buttonPressed[text] = false);
        onTap();
      },
      onTapCancel: () => setState(() => _buttonPressed[text] = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: double.infinity,
        height: 64,
        // Dış gövde — tuşun alt kısmı/yüksekliği buradan geliyor
        decoration: BoxDecoration(
          color: const Color(0xFF2A0A55), // koyu mor alt gövde
          borderRadius: BorderRadius.circular(14),
          boxShadow: isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  // Kalın sert alt gölge — klavye yükseklik hissi
                  BoxShadow(
                    color: const Color(0xFF150535),
                    blurRadius: 0,
                    offset: const Offset(0, 7),
                  ),
                  // Yumuşak dış gölge
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.30),
                    blurRadius: 10,
                    offset: const Offset(0, 9),
                  ),
                ],
        ),
        // Basılınca yüzey aşağı "batar", bırakınca yukarı çıkar
        padding: EdgeInsets.only(
          top: isPressed ? 7 : 2,
          bottom: isPressed ? 1 : 6,
          left: 4,
          right: 4,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          // Tuş yüzeyi
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isPressed
                  ? [
                      const Color(0xFF5A2EA0),
                      const Color(0xFF3D1A78),
                    ]
                  : [
                      const Color(0xFF9060CC),
                      const Color(0xFF6B3FA0),
                    ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: Colors.white.withValues(alpha: isPressed ? 0.08 : 0.18),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // Üst sol parlama — klavye tuşu yansıması (2. resimdeki gibi)
              if (!isPressed)
                Positioned(
                  top: 3,
                  left: 10,
                  child: Container(
                    width: 60,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                ),
              // Sağ alt küçük parlama noktası
              if (!isPressed)
                Positioned(
                  bottom: 5,
                  right: 14,
                  child: Container(
                    width: 22,
                    height: 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                ),
              // Buton metni — Nunito yazı tipi (klavye tuşu stili)
              Center(
                child: Text(
                  text,
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.8,
                    shadows: [
                      Shadow(
                        color: const Color(0xFF0D0030).withValues(alpha: 0.85),
                        offset: const Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}