import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'dart:async';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/dictionary_service.dart';
import '../services/database_service.dart';

class GameScreen extends StatefulWidget {
  final int gridSize;
  final int maxMoves;

  const GameScreen({
    super.key,
    required this.gridSize,
    required this.maxMoves,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

enum PowerType { row, area, column, mega }

class PowerCell {
  final PowerType type;
  PowerCell(this.type);
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  List<List<String>> grid = [];
  List<List<PowerCell?>> powerGrid = [];
  List<List<bool>> explodingCells = [];
  List<List<int>> explodeDelays = [];
  List<List<bool>> fallingCells = [];
  List<List<GlobalKey>> cellKeys = [];
  int remainingMoves = 0;
  bool _gridReady = false;
  int score = 0;
  int _wordCount = 0;
  String _longestWord = '';
  final ValueNotifier<int> _secondsNotifier = ValueNotifier(0);
  Timer? _timer;
  List<List<int>> selectedCells = [];
  String currentWord = '';
  String message = '';
  Color messageColor = Colors.green;
  bool _isAnimating = false;
  bool _gameOver = false; // ★ oyun bitti flag — tekrar hamle yapılmasın
  List<int>? _lastHoveredCell;
  int _availableWordCount = 0;
  bool _isScanning = false;

  // Harf dokunuş sesi (pop)
  AudioPool? _audioPool;

  // Başarı sesi — joker/özel güç için (AudioPool)
  AudioPool? _successPool;

  // Geçerli kelime sesi — normal kelime bulununca
  AudioPool? _wordPool;

  // Jokerler
  int _jokerBalik = 0;
  int _jokerTekerlek = 0;
  int _jokerLolipop = 0;
  int _jokerDegistirme = 0;
  int _jokerKaristirma = 0;
  int _jokerParti = 0;
  bool _jokerLolipipActive = false;
  bool _jokerDegistirmeActive = false;
  bool _jokerTekerlekActive = false;
  List<int>? _firstSwapCell;

  static const Map<String, int> letterWeights = {
    'A': 12, 'E': 11, 'İ': 10, 'L': 9, 'R': 9, 'N': 9,
    'K': 7,  'M': 7,  'T': 7,  'S': 7, 'Y': 7, 'D': 7,
    'B': 4,  'C': 4,  'Ç': 4,  'G': 4, 'H': 4, 'O': 4,
    'P': 4,  'Ş': 4,  'U': 4,  'Z': 4,
    'F': 2,  'Ğ': 2,  'I': 2,  'Ö': 2, 'Ü': 2, 'V': 2,
    'J': 1,
  };

  static const Map<String, int> letterPoints = {
    'A': 1, 'B': 3, 'C': 4, 'Ç': 4, 'D': 3, 'E': 1,
    'F': 7, 'G': 5, 'Ğ': 8, 'H': 5, 'I': 2, 'İ': 1,
    'J': 10,'K': 1, 'L': 1, 'M': 2, 'N': 1, 'O': 2,
    'Ö': 7, 'P': 5, 'R': 1, 'S': 2, 'Ş': 4, 'T': 1,
    'U': 2, 'Ü': 3, 'V': 7, 'Y': 3, 'Z': 4,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    remainingMoves = widget.maxMoves;
    _loadJokers();
    _startTimer();

    // Harf dokunuş sesi
    AudioPool.create(
      source: AssetSource('sounds/pop.wav'),
      maxPlayers: 6,
    ).then((pool) => _audioPool = pool);

    // Başarı sesi — joker/özel güç için
    AudioPool.create(
      source: AssetSource('sounds/success.mp3'),
      maxPlayers: 4,
    ).then((pool) => _successPool = pool);

    // Kelime bulma sesi — normal geçerli kelime için
    AudioPool.create(
      source: AssetSource('sounds/word_found.mp3'),
      maxPlayers: 4,
    ).then((pool) => _wordPool = pool);

    DictionaryService.initialize().then((_) {
      if (mounted) {
        setState(() {
          _generateGrid();
          _gridReady = true;
        });
      }
    });
  }

  // ── Başarı sesi: anında çalar (AudioPool) ──────────────────────────────────
  void _playSuccessSound() {
    _successPool?.start(volume: 1.0);
  }

  // ── Geçerli kelime sesi (normal kelime, güç YOK) ─────────────────────────
  void _playWordFoundSound() {
    _wordPool?.start(volume: 1.0);
  }

  // ── Harf dokunuş sesi ────────────────────────────────────────────────────
  void _playLetterSound() {
    _audioPool?.start(volume: 1.0);
  }

  Future<void> _loadJokers() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _jokerBalik      = prefs.getInt('joker_balik') ?? 0;
      _jokerTekerlek   = prefs.getInt('joker_tekerlek') ?? 0;
      _jokerLolipop    = prefs.getInt('joker_lolipop') ?? 0;
      _jokerDegistirme = prefs.getInt('joker_degistirme') ?? 0;
      _jokerKaristirma = prefs.getInt('joker_karistirma') ?? 0;
      _jokerParti      = prefs.getInt('joker_parti') ?? 0;
    });
  }

  Future<void> _useJoker(String key) async {
    final prefs = await SharedPreferences.getInstance();
    int current = prefs.getInt(key) ?? 0;
    if (current > 0) await prefs.setInt(key, current - 1);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      if (_gridReady && remainingMoves > 0) _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _secondsNotifier.value++;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _secondsNotifier.dispose();
    _audioPool?.dispose();
    _successPool?.dispose();
    _wordPool?.dispose();
    super.dispose();
  }

  String _randomLetter() {
    final random = Random();
    final entries = letterWeights.entries.toList();
    int totalWeight = entries.fold(0, (sum, e) => sum + e.value);
    int randomValue = random.nextInt(totalWeight);
    int cumulative = 0;
    for (final entry in entries) {
      cumulative += entry.value;
      if (randomValue < cumulative) return entry.key;
    }
    return 'A';
  }

  void _generateGrid() {
    grid = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => _randomLetter()),
    );
    powerGrid = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => null),
    );
    explodingCells = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => false),
    );
    explodeDelays = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => 0),
    );
    fallingCells = List.generate(
      widget.gridSize,
      (_) => List.generate(widget.gridSize, (_) => false),
    );
    cellKeys = List.generate(
      widget.gridSize,
      (r) => List.generate(widget.gridSize, (c) => GlobalKey()),
    );
    selectedCells = [];
    currentWord = '';
    _lastHoveredCell = null;
    Future.microtask(() => _scanGridForWords());
  }

  bool _isAdjacent(List<int> a, List<int> b) {
    return (a[0] - b[0]).abs() <= 1 && (a[1] - b[1]).abs() <= 1;
  }

  bool _isSelected(int row, int col) {
    return selectedCells.any((c) => c[0] == row && c[1] == col);
  }

  void _handleDragStart(Offset globalPosition) {
    if (_isAnimating || _gameOver) return;
    if (_jokerLolipipActive || _jokerTekerlekActive || _jokerDegistirmeActive) {
      _selectCellAt(globalPosition);
      return;
    }
    setState(() {
      selectedCells = [];
      currentWord = '';
      _lastHoveredCell = null;
      message = '';
    });
    _selectCellAt(globalPosition);
  }

  void _handleDragUpdate(Offset globalPosition) {
    if (_isAnimating || _gameOver) return;
    _selectCellAt(globalPosition);
  }

  void _handleDragEnd() {
    if (_isAnimating || _gameOver) return;
    if (_jokerLolipipActive || _jokerTekerlekActive || _jokerDegistirmeActive) return;
    _submitWord();
  }

  void _selectCellAt(Offset globalPosition) {
    int? bestRow, bestCol;
    double bestDist = double.infinity;

    for (int row = 0; row < widget.gridSize; row++) {
      for (int col = 0; col < widget.gridSize; col++) {
        final key = cellKeys[row][col];
        final RenderBox? box =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null) continue;

        final Offset cellOffset = box.localToGlobal(Offset.zero);
        final Offset cellCenter =
            cellOffset + Offset(box.size.width / 2, box.size.height / 2);
        final double dist = (globalPosition - cellCenter).distance;

        final Rect cellRect = cellOffset & box.size;
        if (!cellRect.contains(globalPosition)) continue;

        if (dist < bestDist) {
          bestDist = dist;
          bestRow = row;
          bestCol = col;
        }
      }
    }

    if (bestRow == null || bestCol == null) return;
    final int row = bestRow;
    final int col = bestCol;

    if (_lastHoveredCell != null &&
        _lastHoveredCell![0] == row &&
        _lastHoveredCell![1] == col) return;

    _lastHoveredCell = [row, col];

    // ── Lolipop joker ──────────────────────────────────────────────────────
    if (_jokerLolipipActive) {
      _useJoker('joker_lolipop');
      _playSuccessSound(); // ★ Joker sesi
      setState(() {
        _jokerLolipop--;
        _jokerLolipipActive = false;
        message = '🍭 Harf silindi!';
        messageColor = Colors.pink;
      });
      _animateAndRemove({'$row,$col'});
      return;
    }

    // ── Tekerlek joker ─────────────────────────────────────────────────────
    if (_jokerTekerlekActive) {
      _useJoker('joker_tekerlek');
      Set<String> toRemove = {};
      for (int c = 0; c < widget.gridSize; c++) toRemove.add('$row,$c');
      for (int r = 0; r < widget.gridSize; r++) toRemove.add('$r,$col');
      _playSuccessSound(); // ★ Joker sesi
      setState(() {
        _jokerTekerlek--;
        _jokerTekerlekActive = false;
        message = '🎡 Satır ve sütun temizlendi!';
        messageColor = Colors.blue;
      });
      _animateAndRemove(toRemove);
      return;
    }

    // ── Değiştirme joker ───────────────────────────────────────────────────
    if (_jokerDegistirmeActive) {
      if (_firstSwapCell == null) {
        setState(() {
          _firstSwapCell = [row, col];
          message = '🤚 İkinci harfe dokun!';
        });
      } else {
        final first = _firstSwapCell!;
        if (_isAdjacent(first, [row, col])) {
          _useJoker('joker_degistirme');
          _playSuccessSound(); // ★ Joker sesi
          setState(() {
            String temp = grid[first[0]][first[1]];
            grid[first[0]][first[1]] = grid[row][col];
            grid[row][col] = temp;
            _jokerDegistirme--;
            _jokerDegistirmeActive = false;
            _firstSwapCell = null;
            message = '🤚 Harfler değiştirildi!';
            messageColor = Colors.green;
          });
        } else {
          setState(() {
            message = '🤚 Sadece komşu harfleri değiştirebilirsin!';
            messageColor = Colors.red;
            _firstSwapCell = null;
          });
        }
      }
      return;
    }

    if (_isSelected(row, col)) return;

    if (selectedCells.isNotEmpty &&
        !_isAdjacent(selectedCells.last, [row, col])) return;

    // Yeni harf eklendi — pop sesi
    _playLetterSound();

    setState(() {
      selectedCells.add([row, col]);
      currentWord += grid[row][col];
    });
  }

  // ── Balık joker ────────────────────────────────────────────────────────────
  Future<void> _activateBalik() async {
    if (_jokerBalik <= 0) return;
    await _useJoker('joker_balik');
    _playSuccessSound(); // ★ Joker sesi
    setState(() => _jokerBalik--);
    final random = Random();
    Set<String> toRemove = {};
    int count = widget.gridSize ~/ 2;
    while (toRemove.length < count) {
      int r = random.nextInt(widget.gridSize);
      int c = random.nextInt(widget.gridSize);
      toRemove.add('$r,$c');
    }
    setState(() {
      message = '🐟 Balık joker kullanıldı!';
      messageColor = Colors.blue;
    });
    await _animateAndRemove(toRemove);
  }

  // ── Karıştırma joker ───────────────────────────────────────────────────────
  Future<void> _activateKaristirma() async {
    if (_jokerKaristirma <= 0) return;
    await _useJoker('joker_karistirma');
    _playSuccessSound(); // ★ Joker sesi
    List<String> allLetters = [];
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        allLetters.add(grid[r][c]);
      }
    }
    allLetters.shuffle();
    int idx = 0;
    setState(() {
      _jokerKaristirma--;
      for (int r = 0; r < widget.gridSize; r++) {
        for (int c = 0; c < widget.gridSize; c++) {
          grid[r][c] = allLetters[idx++];
        }
      }
      message = '🎲 Harfler karıştırıldı!';
      messageColor = Colors.blue;
    });
  }

  // ── Parti joker ────────────────────────────────────────────────────────────
  Future<void> _activateParti() async {
    if (_jokerParti <= 0) return;
    await _useJoker('joker_parti');
    _playSuccessSound(); // ★ Joker sesi
    setState(() => _jokerParti--);
    Set<String> toRemove = {};
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        toRemove.add('$r,$c');
      }
    }
    setState(() {
      message = '🎉 Parti Güçlendiricisi!';
      messageColor = Colors.purple;
    });
    await _animateAndRemove(toRemove);
  }

  Future<void> _animateAndRemove(Set<String> cellKeys) async {
    setState(() => _isAnimating = true);

    double sumR = 0, sumC = 0;
    for (final key in cellKeys) {
      final p = key.split(',');
      sumR += int.parse(p[0]);
      sumC += int.parse(p[1]);
    }
    final centerR = sumR / cellKeys.length;
    final centerC = sumC / cellKeys.length;

    for (final key in cellKeys) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      final dist = ((r - centerR).abs() + (c - centerC).abs());
      explodeDelays[r][c] = (dist * 25).round().clamp(0, 80);
      explodingCells[r][c] = true;
    }
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 300));
    _removeSpecificCells(cellKeys);

    final Map<int, int> topRemovedRow = {};
    for (final key in cellKeys) {
      final parts = key.split(',');
      final r = int.parse(parts[0]);
      final c = int.parse(parts[1]);
      if (!topRemovedRow.containsKey(c) || r < topRemovedRow[c]!) {
        topRemovedRow[c] = r;
      }
    }

    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        explodingCells[r][c] = false;
        fallingCells[r][c] =
            topRemovedRow.containsKey(c) && r <= topRemovedRow[c]!;
      }
    }
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 380));
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) fallingCells[r][c] = false;
    }
    setState(() => _isAnimating = false);
    _scanGridForWords();
  }

  void _removeSpecificCells(Set<String> toRemoveKeys) {
    setState(() {
      for (int col = 0; col < widget.gridSize; col++) {
        List<int> rowsToRemove = [];
        for (final key in toRemoveKeys) {
          final parts = key.split(',');
          if (int.parse(parts[1]) == col) rowsToRemove.add(int.parse(parts[0]));
        }
        if (rowsToRemove.isEmpty) continue;
        List<String> newCol = [];
        List<PowerCell?> newPowerCol = [];
        for (int row = 0; row < widget.gridSize; row++) {
          if (!rowsToRemove.contains(row)) {
            newCol.add(grid[row][col]);
            newPowerCol.add(powerGrid[row][col]);
          }
        }
        while (newCol.length < widget.gridSize) {
          newCol.insert(0, _randomLetter());
          newPowerCol.insert(0, null);
        }
        for (int row = 0; row < widget.gridSize; row++) {
          grid[row][col] = newCol[row];
          powerGrid[row][col] = newPowerCol[row];
        }
      }
    });
  }

  int _calculateWordScore(String word) {
    int total = 0;
    for (final char in word.split('')) total += letterPoints[char] ?? 1;
    return total;
  }

  List<String> _findSubwords(String word) {
    final seen = <String>{};
    final subwords = <String>[];
    for (int i = 0; i < word.length; i++) {
      for (int j = i + 3; j <= word.length; j++) {
        final sub = word.substring(i, j);
        if (sub == word) continue;
        if (seen.contains(sub)) continue;
        if (DictionaryService.isOfflineWord(sub)) {
          seen.add(sub);
          subwords.add(sub);
        }
      }
    }
    return subwords;
  }

  PowerType? _getPowerForLength(int length) {
    if (length == 4) return PowerType.row;
    if (length == 5) return PowerType.area;
    if (length == 6) return PowerType.column;
    if (length >= 7) return PowerType.mega;
    return null;
  }

  String _powerIcon(PowerType type) {
    switch (type) {
      case PowerType.row:    return '⇆';
      case PowerType.area:   return '✹';
      case PowerType.column: return '⇅';
      case PowerType.mega:   return '✪';
    }
  }

  String _powerName(PowerType type) {
    switch (type) {
      case PowerType.row:    return 'Satır Temizle';
      case PowerType.area:   return 'Alan Patlat';
      case PowerType.column: return 'Sütun Temizle';
      case PowerType.mega:   return 'Mega Patlat';
    }
  }

  Color _powerColor(PowerType type) {
    switch (type) {
      case PowerType.row:    return Colors.blue;
      case PowerType.area:   return Colors.orange;
      case PowerType.column: return Colors.green;
      case PowerType.mega:   return Colors.red;
    }
  }

  Future<void> _submitWord() async {
    if (_isAnimating) return;
    if (_jokerLolipipActive || _jokerTekerlekActive || _jokerDegistirmeActive) return;
    if (selectedCells.isEmpty) return;

    List<int>? powerCellInWord;
    for (final cell in selectedCells) {
      if (powerGrid[cell[0]][cell[1]] != null) {
        powerCellInWord = cell;
        break;
      }
    }

    if (selectedCells.length == 1) {
      setState(() {
        message = 'En az 3 harf gerekli!';
        messageColor = Colors.red;
        selectedCells = [];
        currentWord = '';
      });
      remainingMoves--;
      _checkGameOver();
      return;
    }

    if (currentWord.length < 3) {
      setState(() {
        message = 'En az 3 harf gerekli!';
        messageColor = Colors.red;
        selectedCells = [];
        currentWord = '';
      });
      remainingMoves--;
      _checkGameOver();
      return;
    }

    bool isValid = DictionaryService.isOfflineWord(currentWord);
    remainingMoves--;

    if (isValid) {
      // Ses: güç yoksa word_found, güç varsa success (aşağıda güç bloğunda çalıyor)
      int wordScore = _calculateWordScore(currentWord);
      List<String> subwords = _findSubwords(currentWord);
      int comboScore = 0;
      for (final sub in subwords) comboScore += _calculateWordScore(sub);
      int totalScore = wordScore + comboScore;
      score += totalScore;
      _wordCount++;
      if (currentWord.length > _longestWord.length) _longestWord = currentWord;

      String comboText =
          subwords.isNotEmpty ? ' Combo: ${subwords.join(', ')}' : '';
      PowerType? newPower = _getPowerForLength(selectedCells.length);
      String powerText = newPower != null
          ? ' + ${_powerIcon(newPower)} ${_powerName(newPower)}!'
          : '';

      if (powerCellInWord != null) {
        final pt = powerGrid[powerCellInWord[0]][powerCellInWord[1]]!.type;
        powerText += ' ${_powerIcon(pt)} aktive!';
      }

      setState(() {
        message = '+$totalScore puan! $currentWord$comboText$powerText';
        messageColor = Colors.green;
      });

      if (powerCellInWord != null) {
        // ── Güç simgesi kelimede kullanıldı: ses çal + efekt uygula ────────
        final pr = powerCellInWord[0];
        final pc = powerCellInWord[1];
        final activatedPower = powerGrid[pr][pc]!;
        powerGrid[pr][pc] = null;

        final Set<String> allToRemove = {};

        for (final cell in selectedCells) {
          final r = cell[0];
          final c = cell[1];
          if (newPower != null &&
              cell[0] == selectedCells.last[0] &&
              cell[1] == selectedCells.last[1]) continue;
          allToRemove.add('$r,$c');
        }

        // ★ Özel güç aktive olunca başarı sesini çal
        _playSuccessSound();

        switch (activatedPower.type) {
          case PowerType.row:
            // Satır Temizleme (4 harfli kelimeden oluşan güç)
            for (int c = 0; c < widget.gridSize; c++) allToRemove.add('$pr,$c');
            setState(() => message += ' ⇆ Satır Temizlendi!');
            break;
          case PowerType.column:
            // Sütun Temizleme (6 harfli kelimeden oluşan güç)
            for (int r = 0; r < widget.gridSize; r++) allToRemove.add('$r,$pc');
            setState(() => message += ' ⇅ Sütun Temizlendi!');
            break;
          case PowerType.area:
            // Alan Patlatma (5 harfli kelimeden oluşan güç)
            for (int r = pr - 1; r <= pr + 1; r++) {
              for (int c = pc - 1; c <= pc + 1; c++) {
                if (r >= 0 && r < widget.gridSize && c >= 0 && c < widget.gridSize) {
                  allToRemove.add('$r,$c');
                }
              }
            }
            setState(() => message += ' ✹ Alan Patlatıldı!');
            break;
          case PowerType.mega:
            // Mega Patlatma (7+ harfli kelimeden oluşan güç)
            for (int r = pr - 2; r <= pr + 2; r++) {
              for (int c = pc - 2; c <= pc + 2; c++) {
                if (r >= 0 && r < widget.gridSize && c >= 0 && c < widget.gridSize) {
                  allToRemove.add('$r,$c');
                }
              }
            }
            setState(() => message += ' ✪ Mega Patlatma!');
            break;
        }

        if (newPower != null) {
          final last = selectedCells.last;
          grid[last[0]][last[1]] = grid[last[0]][last[1]];
          powerGrid[last[0]][last[1]] = PowerCell(newPower);
        }

        setState(() {
          selectedCells = [];
          currentWord = '';
        });
        await _animateAndRemove(allToRemove);
      } else {
        // Güç simgesi kullanılmadı — normal kelime sesi
        _playWordFoundSound();
        await _explodeCellsAnimated(power: newPower);
      }
    } else {
      setState(() {
        message = '"$currentWord" geçersiz kelime!';
        messageColor = Colors.red;
        selectedCells = [];
        currentWord = '';
        _availableWordCount = _availableWordCount;
      });
    }
    _checkGameOver();
  }

  Future<void> _explodeCellsAnimated({PowerType? power}) async {
    setState(() => _isAnimating = true);
    List<List<int>> toRemove = List.from(selectedCells);
    final lastCell = toRemove.isNotEmpty ? toRemove.last : null;

    if (power != null && lastCell != null) {
      toRemove.removeWhere(
          (c) => c[0] == lastCell[0] && c[1] == lastCell[1]);
    }

    for (int i = 0; i < toRemove.length; i++) {
      final cell = toRemove[i];
      explodingCells[cell[0]][cell[1]] = true;
      final delay =
          (i * (60 / toRemove.length.clamp(1, 10))).round().clamp(0, 60);
      explodeDelays[cell[0]][cell[1]] = delay;
    }
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 280));

    setState(() {
      final String? savedLastLetter = (power != null && lastCell != null)
          ? grid[lastCell[0]][lastCell[1]]
          : null;

      for (int col = 0; col < widget.gridSize; col++) {
        List<int> colRows =
            toRemove.where((c) => c[1] == col).map((c) => c[0]).toList();
        if (colRows.isEmpty) continue;
        List<String> newCol = [];
        List<PowerCell?> newPowerCol = [];
        for (int row = 0; row < widget.gridSize; row++) {
          if (!colRows.contains(row)) {
            newCol.add(grid[row][col]);
            newPowerCol.add(powerGrid[row][col]);
          }
        }
        while (newCol.length < widget.gridSize) {
          newCol.insert(0, _randomLetter());
          newPowerCol.insert(0, null);
        }
        for (int row = 0; row < widget.gridSize; row++) {
          grid[row][col] = newCol[row];
          powerGrid[row][col] = newPowerCol[row];
          explodingCells[row][col] = false;
          fallingCells[row][col] = false;
        }
      }
      if (power != null && lastCell != null && savedLastLetter != null) {
        grid[lastCell[0]][lastCell[1]] = savedLastLetter;
        powerGrid[lastCell[0]][lastCell[1]] = PowerCell(power);
      }
      selectedCells = [];
      currentWord = '';
    });

    final Map<int, int> topRemovedRow = {};
    for (final cell in toRemove) {
      final r = cell[0];
      final c = cell[1];
      if (!topRemovedRow.containsKey(c) || r < topRemovedRow[c]!) {
        topRemovedRow[c] = r;
      }
    }
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        fallingCells[r][c] =
            topRemovedRow.containsKey(c) && r <= topRemovedRow[c]!;
      }
    }
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 380));
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) fallingCells[r][c] = false;
    }
    setState(() => _isAnimating = false);
  }

  Future<void> _saveGame() async {
    _timer?.cancel();
    await DatabaseService.saveGame(
      gridSize: widget.gridSize,
      score: score,
      wordCount: _wordCount,
      longestWord: _longestWord.isEmpty ? '-' : _longestWord,
      duration: _secondsNotifier.value,
    );
  }

  Future<void> _scanGridForWords() async {
    if (_isScanning) return;
    setState(() => _isScanning = true);

    final flatGrid = <String>[];
    for (int r = 0; r < widget.gridSize; r++) {
      for (int c = 0; c < widget.gridSize; c++) {
        flatGrid.add(grid[r][c]);
      }
    }

    final int count = await compute(
      DictionaryService.scanGridSync,
      {
        'flatGrid': flatGrid,
        'gridSize': widget.gridSize,
        'words':    DictionaryService.wordSet.toList(),
      },
    );

    if (mounted) {
      setState(() {
        _availableWordCount = count;
        _isScanning         = false;
      });
    }
  }

  void _checkGameOver() {
    if (remainingMoves <= 0 && !_gameOver) {
      _gameOver = true; // ★ hemen set et — 500ms içinde yeni hamle yapılamasın
      _timer?.cancel();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _showGameOverDialog();
      });
    }
  }

  void _showGameOverDialog() {
    _saveGame();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Oyun Bitti!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star, color: Colors.amber, size: 60)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 10),
            Text('Toplam Puan: $score',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Bulunan Kelime: $_wordCount'),
            Text('En Uzun Kelime: ${_longestWord.isEmpty ? "-" : _longestWord}'),
            Text('Süre: ${_formatTime(_secondsNotifier.value)}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B3FA0),
              foregroundColor: Colors.white,
            ),
            child: const Text('Ana Menü'),
          ),
        ],
      ),
    );
  }

  Widget _jokerButton(
      String icon, String label, int count, VoidCallback onTap) {
    final bool isAsset = icon.startsWith('assets/');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF6B3FA0).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: const Color(0xFF6B3FA0).withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isAsset
                ? Image.asset(icon,
                    width: 36,
                    height: 36,
                    errorBuilder: (_, __, ___) =>
                        const Text('?', style: TextStyle(fontSize: 28)))
                : Text(icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 2),
            Text('$label ($count)',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF6B3FA0),
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_gridReady) {
      return Scaffold(
        backgroundColor: const Color(0xFF6B3FA0),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Yükleniyor...',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Çıkmak istiyor musunuz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hayır'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _saveGame();
                  if (!mounted) return;
                  final nav = Navigator.of(context);
                  nav.pop();
                  nav.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B3FA0),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Evet'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F0FF),
        appBar: AppBar(
          backgroundColor: const Color(0xFF6B3FA0),
          foregroundColor: Colors.white,
          title: Text('${widget.gridSize}x${widget.gridSize} Word Crush'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Çıkmak istiyor musunuz?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hayır'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await _saveGame();
                        if (!mounted) return;
                        final nav = Navigator.of(context);
                        nav.pop();
                        nav.pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6B3FA0),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Evet'),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: ValueListenableBuilder<int>(
                  valueListenable: _secondsNotifier,
                  builder: (_, val, __) => Text(
                    _formatTime(val),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // ── Üst bilgi çubuğu ─────────────────────────────────────────
            Container(
              color: const Color(0xFF6B3FA0),
              padding:
                  const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Puan: $score',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade700,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      currentWord.isEmpty ? 'Harf seç...' : currentWord,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text('Hamle: $remainingMoves',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            // ── Kelime tarama çubuğu ──────────────────────────────────────
            Container(
              color: const Color(0xFF3D1A78),
              padding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isScanning)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                          color: Colors.white70, strokeWidth: 2),
                    )
                  else
                    Icon(
                      Icons.search,
                      size: 14,
                      color: _availableWordCount == 0
                          ? Colors.redAccent
                          : Colors.white70,
                    ),
                  const SizedBox(width: 6),
                  Text(
                    _isScanning
                        ? 'Kelimeler taranıyor...'
                        : 'Gridde Oluşturulabilir Kelime Sayısı: $_availableWordCount',
                    style: TextStyle(
                      color: _availableWordCount == 0 && !_isScanning
                          ? Colors.redAccent
                          : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            // ── Mesaj bandı ───────────────────────────────────────────────
            // ★ Sabit yükseklik — mesaj var/yok grid asla kaymaz
            SizedBox(
              height: 36,
              width: double.infinity,
              child: message.isNotEmpty
                  ? Container(
                      color: messageColor.withValues(alpha: 0.15),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          message,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: messageColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 13),
                        ),
                      ),
                    ).animate().fadeIn(duration: 200.ms)
                  : const SizedBox.shrink(),
            ),
            // ── Grid ──────────────────────────────────────────────────────
            Expanded(
              child: GestureDetector(
                onPanStart: (d) => _handleDragStart(d.globalPosition),
                onPanUpdate: (d) => _handleDragUpdate(d.globalPosition),
                onPanEnd: (_) => _handleDragEnd(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: widget.gridSize,
                        crossAxisSpacing: 4,
                        mainAxisSpacing: 4,
                      ),
                      itemCount: widget.gridSize * widget.gridSize,
                      itemBuilder: (context, index) {
                        final row = index ~/ widget.gridSize;
                        final col = index % widget.gridSize;
                        final selected = _isSelected(row, col);
                        final isExploding = explodingCells[row][col];
                        final isFalling = fallingCells[row][col];
                        final power = powerGrid[row][col];

                        Widget cell = Container(
                          key: cellKeys[row][col],
                          decoration: BoxDecoration(
                            color: isExploding
                                ? Colors.orange.shade300
                                : power != null
                                    ? Colors.purple.shade100
                                    : selected
                                        ? const Color(0xFF6B3FA0)
                                        : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: selected
                                  ? const Color(0xFF9B6FD0)
                                  : isExploding
                                      ? Colors.orange
                                      : power != null
                                          ? const Color(0xFF3D1A78)
                                          : Colors.grey.shade300,
                              width:
                                  isExploding || power != null || selected
                                      ? 2
                                      : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isExploding
                                    ? Colors.orange.withValues(alpha: 0.5)
                                    : Colors.black12,
                                blurRadius: isExploding ? 12 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              power != null
                                  ? _powerIcon(power.type)
                                  : grid[row][col],
                              style: TextStyle(
                                fontSize: widget.gridSize == 6
                                    ? 22
                                    : widget.gridSize == 8
                                        ? 18
                                        : 14,
                                fontWeight: FontWeight.bold,
                                color: isExploding
                                    ? Colors.white
                                    : power != null
                                        ? _powerColor(power.type)
                                        : selected
                                            ? Colors.white
                                            : const Color(0xFF3D1A78),
                              ),
                            ),
                          ),
                        );

                        if (isExploding) {
                          final explodeDelay = explodeDelays[row][col];
                          cell = cell
                              .animate(delay: explodeDelay.ms)
                              .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.4, 1.4),
                                  duration: 80.ms,
                                  curve: Curves.easeOut)
                              .shimmer(
                                  duration: 80.ms,
                                  color: Colors.yellow
                                      .withValues(alpha: 0.8))
                              .then()
                              .scale(
                                  begin: const Offset(1.4, 1.4),
                                  end: const Offset(0, 0),
                                  duration: 120.ms,
                                  curve: Curves.easeIn)
                              .fadeOut(duration: 120.ms);
                        }

                        if (isFalling && !isExploding) {
                          cell = cell
                              .animate()
                              .slideY(
                                  begin: -1.2,
                                  end: 0,
                                  duration: 350.ms,
                                  curve: Curves.bounceOut)
                              .fadeIn(duration: 200.ms);
                        }

                        if (selected && !isExploding) {
                          cell = cell
                              .animate()
                              .scale(
                                  begin: const Offset(0.85, 0.85),
                                  end: const Offset(1.05, 1.05),
                                  duration: 100.ms,
                                  curve: Curves.easeOut)
                              .then()
                              .scale(
                                  begin: const Offset(1.05, 1.05),
                                  end: const Offset(1, 1),
                                  duration: 60.ms);
                        }

                        return cell;
                      },
                    ),
                  ),
                ),
              ),
            ),
            // ── Joker çubuğu ──────────────────────────────────────────────
            if (_jokerBalik > 0 ||
                _jokerTekerlek > 0 ||
                _jokerLolipop > 0 ||
                _jokerDegistirme > 0 ||
                _jokerKaristirma > 0 ||
                _jokerParti > 0)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      if (_jokerBalik > 0)
                        _jokerButton('assets/icons/gummy-fish.png', 'Balık',
                            _jokerBalik, _activateBalik),
                      if (_jokerTekerlek > 0)
                        _jokerButton('assets/icons/gummy.png', 'Tekerlek',
                            _jokerTekerlek, () {
                          setState(() {
                            _jokerTekerlekActive = true;
                            _jokerLolipipActive = false;
                            _jokerDegistirmeActive = false;
                            message = '🎡 Bir hücreye dokun!';
                            messageColor = Colors.blue;
                          });
                        }),
                      if (_jokerLolipop > 0)
                        _jokerButton('assets/icons/lollipop.png', 'Lolipop',
                            _jokerLolipop, () {
                          setState(() {
                            _jokerLolipipActive = true;
                            _jokerTekerlekActive = false;
                            _jokerDegistirmeActive = false;
                            message = '🍭 Silmek istediğin harfe dokun!';
                            messageColor = Colors.pink;
                          });
                        }),
                      if (_jokerDegistirme > 0)
                        _jokerButton('assets/icons/drag.png', 'Değiştir',
                            _jokerDegistirme, () {
                          setState(() {
                            _jokerDegistirmeActive = true;
                            _jokerLolipipActive = false;
                            _jokerTekerlekActive = false;
                            _firstSwapCell = null;
                            message = '🤚 İlk harfe dokun!';
                            messageColor = Colors.orange;
                          });
                        }),
                      if (_jokerKaristirma > 0)
                        _jokerButton(
                            'assets/icons/gumball-machine.png',
                            'Karıştır',
                            _jokerKaristirma,
                            _activateKaristirma),
                      if (_jokerParti > 0)
                        _jokerButton('assets/icons/party-popper.png',
                            'Parti', _jokerParti, _activateParti),
                    ],
                  ),
                ),
              ),
            // ── Alt butonlar ──────────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isAnimating
                            ? null
                            : () {
                                setState(() {
                                  selectedCells = [];
                                  currentWord = '';
                                  message = '';
                                  _jokerLolipipActive = false;
                                  _jokerTekerlekActive = false;
                                  _jokerDegistirmeActive = false;
                                  _firstSwapCell = null;
                                  _lastHoveredCell = null;
                                });
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade400,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Temizle',
                            style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: currentWord.isEmpty || _isAnimating
                            ? null
                            : () => _submitWord(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6B3FA0),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Text(
                          currentWord.isEmpty
                              ? 'Kelime Seç'
                              : '"$currentWord" Gönder',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}