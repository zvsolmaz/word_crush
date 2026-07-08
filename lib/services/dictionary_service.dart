import 'package:flutter/services.dart';

class DictionaryService {
  static Set<String>? _words;
  static bool _assetsLoaded = false;

  /// 49.466 kelimelik Türkçe listeyi yükler.
  static Future<void> initialize() async {
    if (_assetsLoaded) return;
    _assetsLoaded = true;
    try {
      final String data = await rootBundle.loadString('assets/words.txt');
      _words = data
          .split('\n')
          .map((w) => w.trim())
          .where((w) => w.length >= 2)
          .toSet();
    } catch (e) {
      _words = {};
      print('HATA: assets/words.txt yuklenemedi: $e');
    }
  }

  /// Kelime setini disariya aciyoruz - compute() isolate parametresi icin
  static Set<String> get wordSet => _words ?? {};

  /// Senkron offline kontrol
  static bool isOfflineWord(String word) {
    if (_words == null) return false;
    return _words!.contains(word.toUpperCase());
  }

  /// Asenkron wrapper
  static Future<bool> isValidWord(String word) async {
    if (!_assetsLoaded) await initialize();
    return isOfflineWord(word);
  }

  /// compute() ile arka plan isolate'de calisan grid tarama fonksiyonu.
  /// Proje geregi: ortak harf kullanamayacak sekilde kac kelime olusturulabilir.
  /// Greedy yaklasim: kisa kelimeler once islenir, ortak hucre kullananlar atlanir.
  static int scanGridSync(Map<String, dynamic> params) {
    final List<String> flatGrid = List<String>.from(params['flatGrid'] as List);
    final int gridSize = params['gridSize'] as int;
    final Set<String> words = Set<String>.from(params['words'] as List);

    const List<List<int>> dirs = [
      [-1, -1], [-1, 0], [-1, 1],
      [ 0, -1],          [ 0, 1],
      [ 1, -1], [ 1, 0], [ 1, 1],
    ];

    // Her gecerli kelime icin kullandigi hucre indekslerini sakla
    // [yol_indeksleri_listesi, ...]
    final List<List<int>> foundPaths = [];
    final Set<String> foundWords = {};

    void dfs(int row, int col, String word, List<bool> visited, List<int> currentPath) {
      if (word.length >= 3 && words.contains(word) && !foundWords.contains(word)) {
        foundWords.add(word);
        foundPaths.add(List<int>.from(currentPath));
      }
      if (word.length >= 7) return;
      for (final d in dirs) {
        final nr = row + d[0];
        final nc = col + d[1];
        if (nr < 0 || nr >= gridSize || nc < 0 || nc >= gridSize) continue;
        final idx = nr * gridSize + nc;
        if (visited[idx]) continue;
        visited[idx] = true;
        currentPath.add(idx);
        dfs(nr, nc, word + flatGrid[idx], visited, currentPath);
        currentPath.removeLast();
        visited[idx] = false;
      }
    }

    // Tum gecerli kelimeleri ve yollarini bul
    for (int r = 0; r < gridSize; r++) {
      for (int c = 0; c < gridSize; c++) {
        final startIdx = r * gridSize + c;
        final visited = List<bool>.filled(gridSize * gridSize, false);
        visited[startIdx] = true;
        dfs(r, c, flatGrid[startIdx], visited, [startIdx]);
      }
    }

    // Greedy: kisa kelimeler once (daha az hucre tuketir, daha fazla kelime sigar)
    foundPaths.sort((a, b) => a.length.compareTo(b.length));

    final Set<int> usedCells = {};
    int count = 0;

    for (final wordPath in foundPaths) {
      // Bu kelimenin hücrelerinden herhangi biri zaten kullanildi mi?
      bool overlaps = false;
      for (final idx in wordPath) {
        if (usedCells.contains(idx)) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) continue;
      // Çakışma yok — bu kelimeyi say ve hücrelerini işaretle
      usedCells.addAll(wordPath);
      count++;
    }

    return count;
  }
}