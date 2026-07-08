import 'package:flutter/material.dart';
import '../services/database_service.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  List<Map<String, dynamic>> _games = [];
  Map<String, dynamic> _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final games = await DatabaseService.getGames();
    final stats = await DatabaseService.getStats();
    setState(() {
      _games = games;
      _stats = stats;
      _loading = false;
    });
  }

  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return '${minutes}dk ${secs}sn';
  }

  String _formatTotalDuration(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '$hours saat $minutes dakika';
    return '$minutes dakika';
  }

  String _gridSizeText(int size) {
    if (size == 6) return '6x6';
    if (size == 8) return '8x8';
    return '10x10';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F0FF),
      appBar: AppBar(
        title: const Text('Skor Tablosu'),
        backgroundColor: const Color(0xFF6B3FA0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Skorları Sıfırla',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Skorları Sıfırla'),
                  content: const Text(
                      'Tüm oyun geçmişi silinecek. Emin misiniz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('İptal'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Sil'),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await DatabaseService.clearGames();
                _loadData();
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _games.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sports_esports,
                          size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Henüz oyun oynanmadı!',
                          style:
                              TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Özet kartı
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B3FA0),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text('Genel İstatistikler',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statItem('Toplam Oyun',
                                    '${_stats['totalGames']}'),
                                _statItem('En Yüksek Puan',
                                    '${_stats['maxScore']}'),
                                _statItem('Ortalama Puan',
                                    '${_stats['avgScore']}'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _statItem('Toplam Kelime',
                                    '${_stats['totalWords']}'),
                                _statItem('En Uzun Kelime',
                                    '${_stats['longestWord']}'),
                                _statItem('Toplam Süre',
                                    _formatTotalDuration(
                                        _stats['totalDuration'] ?? 0)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Oyun listesi
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _games.length,
                        itemBuilder: (context, index) {
                          final game = _games[index];
                          final date = DateTime.parse(game['date']);
                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 6,
                                    offset: Offset(0, 2))
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Oyun ${_games.length - index}',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF6B3FA0)),
                                    ),
                                    Text(
                                      '${date.day}.${date.month}.${date.year}',
                                      style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _gameInfo('Grid',
                                        _gridSizeText(game['gridSize'])),
                                    _gameInfo(
                                        'Puan', '${game['score']}'),
                                    _gameInfo('Kelime',
                                        '${game['wordCount']}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    _gameInfo('En Uzun',
                                        '${game['longestWord']}'),
                                    _gameInfo('Süre',
                                        _formatDuration(game['duration'])),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _statItem(String label, String value) {
    return Flexible(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _gameInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: Colors.grey, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }
}