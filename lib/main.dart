import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const Sf2GuideApp());
}

/// ROOT APP

class Sf2GuideApp extends StatelessWidget {
  const Sf2GuideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SFII Guide',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060714),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFF5C542), // arcade yellow
          secondary: Color(0xFF3FA7FF), // electric blue
        ),
        cardColor: const Color(0xFF101426),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101426),
          foregroundColor: Colors.white,
          elevation: 2,
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<List<Fighter>>(
        future: loadFighters(),
        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Text(
                  'Failed to load data',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          // Success
          final fighters = snapshot.data ?? [];

          return CharacterListScreen(fighters: fighters);
        },
      ),
    );
  }
}

/// MODELS + JSON LOADING

class FrameData {
  final int? startup;
  final int? active;
  final int? recovery;
  final int? onHit;
  final int? onBlock;

  const FrameData({
    this.startup,
    this.active,
    this.recovery,
    this.onHit,
    this.onBlock,
  });

  factory FrameData.fromJson(Map<String, dynamic> json) {
    return FrameData(
      startup: json['startup'] as int?,
      active: json['active'] as int?,
      recovery: json['recovery'] as int?,
      onHit: json['onHit'] as int?,
      onBlock: json['onBlock'] as int?,
    );
  }
}

class Move {
  final String name;
  final String input;
  final String type; // "Special", "Normal", "Throw"
  final List<String> tags;
  final String notes;
  final FrameData? frameData;
  final int? damage;
  final int? stun;

  const Move({
    required this.name,
    required this.input,
    required this.type,
    this.tags = const [],
    this.notes = '',
    this.frameData,
    this.damage,
    this.stun,
  });

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      name: json['name'] as String,
      input: json['input'] as String,
      type: json['type'] as String,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      notes: json['notes'] as String? ?? '',
      damage: json['damage'] as int?,
      stun: json['stun'] as int?,
      frameData: json['frameData'] != null
          ? FrameData.fromJson(json['frameData'] as Map<String, dynamic>)
          : null,
    );
  }
}

class Stats {
  final int? health;
  final double? walkSpeedForward;
  final double? walkSpeedBackward;
  final double? jumpArc;
  final List<String> strengths;
  final List<String> weaknesses;

  const Stats({
    this.health,
    this.walkSpeedForward,
    this.walkSpeedBackward,
    this.jumpArc,
    this.strengths = const [],
    this.weaknesses = const [],
  });

  factory Stats.fromJson(Map<String, dynamic> json) {
    return Stats(
      health: json['health'] as int?,
      walkSpeedForward: (json['walkSpeedForward'] as num?)?.toDouble(),
      walkSpeedBackward: (json['walkSpeedBackward'] as num?)?.toDouble(),
      jumpArc: (json['jumpArc'] as num?)?.toDouble(),
      strengths: (json['strengths'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
      weaknesses: (json['weaknesses'] as List<dynamic>? ?? [])
          .map((e) => e as String)
          .toList(),
    );
  }
}

class Matchup {
  final String opponentId; // e.g. "guile"
  final double ratio; // e.g. 6.0 -> 6-4
  final String summary;
  final String notes;

  const Matchup({
    required this.opponentId,
    required this.ratio,
    required this.summary,
    required this.notes,
  });

  factory Matchup.fromJson(Map<String, dynamic> json) {
    return Matchup(
      opponentId: json['opponentId'] as String,
      ratio: (json['ratio'] as num).toDouble(),
      summary: json['summary'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }
}

class Fighter {
  final String id;
  final String name;
  final String archetype;
  final Stats? stats;
  final List<Move> moves;
  final List<Matchup> matchups;

  const Fighter({
    required this.id,
    required this.name,
    required this.archetype,
    this.stats,
    required this.moves,
    this.matchups = const [],
  });

  factory Fighter.fromJson(Map<String, dynamic> json) {
    final movesJson = json['moves'] as List<dynamic>? ?? [];
    final matchupsJson = json['matchups'] as List<dynamic>? ?? [];

    return Fighter(
      id: json['id'] as String,
      name: json['name'] as String,
      archetype: json['archetype'] as String,
      stats: json['stats'] != null
          ? Stats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      moves: movesJson
          .map((m) => Move.fromJson(m as Map<String, dynamic>))
          .toList(),
      matchups: matchupsJson
          .map((m) => Matchup.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }
}

Future<List<Fighter>> loadFighters() async {
  final jsonString = await rootBundle.loadString('assets/sf2_characters.json');
  final List<dynamic> jsonList = jsonDecode(jsonString) as List<dynamic>;
  return jsonList
      .map((item) => Fighter.fromJson(item as Map<String, dynamic>))
      .toList();
}

/// CHARACTER LIST SCREEN

class CharacterListScreen extends StatelessWidget {
  final List<Fighter> fighters;

  const CharacterListScreen({
    super.key,
    required this.fighters,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SFII: World Warrior Guide'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 4 / 3,
          ),
          itemCount: fighters.length,
          itemBuilder: (context, index) {
            final fighter = fighters[index];
            return FighterCard(fighter: fighter);
          },
        ),
      ),
    );
  }
}

class FighterCard extends StatelessWidget {
  final Fighter fighter;

  const FighterCard({super.key, required this.fighter});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => CharacterDetailScreen(fighter: fighter),
          ),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 4,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF101426),
                Color(0xFF151A30),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fighter.name,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5F5F5),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                fighter.archetype,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFFF5C542),
                ),
              ),
              const Spacer(),
              const Text(
                'View moves',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3FA7FF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CHARACTER DETAIL (TABS: OVERVIEW / MOVES / MATCHUPS)

class CharacterDetailScreen extends StatelessWidget {
  final Fighter fighter;

  const CharacterDetailScreen({super.key, required this.fighter});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(fighter.name),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Moves'),
              Tab(text: 'Matchups'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OverviewTab(fighter: fighter),
            _MovesTab(fighter: fighter),
            _MatchupsTab(fighter: fighter),
          ],
        ),
      ),
    );
  }
}

/// OVERVIEW TAB

class _OverviewTab extends StatelessWidget {
  final Fighter fighter;

  const _OverviewTab({required this.fighter});

  @override
  Widget build(BuildContext context) {
    final stats = fighter.stats;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${fighter.name} • ${fighter.archetype}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFF5F5F5),
            ),
          ),
          const SizedBox(height: 16),
          if (stats != null) ...[
            const Text(
              'STATS',
              style: TextStyle(
                fontSize: 14,
                letterSpacing: 1.2,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5C542),
              ),
            ),
            const SizedBox(height: 8),
            _statRow('Health', stats.health?.toString() ?? 'Unknown'),
            _statRow(
              'Walk Speed (Fwd)',
              stats.walkSpeedForward?.toString() ?? '-',
            ),
            _statRow(
              'Walk Speed (Back)',
              stats.walkSpeedBackward?.toString() ?? '-',
            ),
            _statRow('Jump Arc', stats.jumpArc?.toString() ?? '-'),
            const SizedBox(height: 16),
            if (stats.strengths.isNotEmpty) ...[
              const Text(
                'STRENGTHS',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5C542),
                ),
              ),
              const SizedBox(height: 8),
              ...stats.strengths.map(_bulletText),
              const SizedBox(height: 16),
            ],
            if (stats.weaknesses.isNotEmpty) ...[
              const Text(
                'WEAKNESSES',
                style: TextStyle(
                  fontSize: 14,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5C542),
                ),
              ),
              const SizedBox(height: 8),
              ...stats.weaknesses.map(_bulletText),
            ],
          ] else
            const Text(
              'No stats available yet.',
              style: TextStyle(color: Color(0xFFB0BEC5)),
            ),
        ],
      ),
    );
  }

  static Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFB0BEC5),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFF5F5F5),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _bulletText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: Color(0xFFF5F5F5),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFF5F5F5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// MOVES TAB

class _MovesTab extends StatelessWidget {
  final Fighter fighter;

  const _MovesTab({required this.fighter});

  @override
  Widget build(BuildContext context) {
    final specials = fighter.moves.where((m) => m.type == 'Special').toList();
    final normals = fighter.moves.where((m) => m.type == 'Normal').toList();
    final throws = fighter.moves.where((m) => m.type == 'Throw').toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (specials.isNotEmpty) ...[
          const SectionHeader(title: 'Special Moves'),
          const SizedBox(height: 8),
          ...specials.map(MoveCard.new),
          const SizedBox(height: 16),
        ],
        if (normals.isNotEmpty) ...[
          const SectionHeader(title: 'Normals'),
          const SizedBox(height: 8),
          ...normals.map(MoveCard.new),
          const SizedBox(height: 16),
        ],
        if (throws.isNotEmpty) ...[
          const SectionHeader(title: 'Throws'),
          const SizedBox(height: 8),
          ...throws.map(MoveCard.new),
        ],
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;

  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: const TextStyle(
        fontSize: 14,
        letterSpacing: 1.2,
        fontWeight: FontWeight.bold,
        color: Color(0xFFF5C542),
      ),
    );
  }
}

class MoveCard extends StatelessWidget {
  final Move move;

  const MoveCard(this.move, {super.key});

  @override
  Widget build(BuildContext context) {
    final fd = move.frameData;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: const Color(0xFF101426),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              move.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFFF5F5F5),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              move.input,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF3FA7FF),
              ),
            ),
            if (move.tags.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: move.tags
                    .map(
                      (tag) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: const Color(0xFF151A30),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFFF5F5F5),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
            if (fd != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Frame Data',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFF5C542),
                ),
              ),
              const SizedBox(height: 4),
              _frameRow('Startup', fd.startup),
              _frameRow('Active', fd.active),
              _frameRow('Recovery', fd.recovery),
              _frameRow('On Hit', fd.onHit),
              _frameRow('On Block', fd.onBlock),
            ],
            if (move.notes.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                move.notes,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFB0BEC5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static Widget _frameRow(String label, int? value) {
    if (value == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFB0BEC5),
            ),
          ),
          Text(
            value.toString(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFFF5F5F5),
            ),
          ),
        ],
      ),
    );
  }
}

/// MATCHUPS TAB

class _MatchupsTab extends StatelessWidget {
  final Fighter fighter;

  const _MatchupsTab({required this.fighter});

  @override
  Widget build(BuildContext context) {
    final matchups = fighter.matchups;

    if (matchups.isEmpty) {
      return const Center(
        child: Text(
          'No matchup data yet.',
          style: TextStyle(color: Color(0xFFB0BEC5)),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matchups.length,
      itemBuilder: (context, index) {
        final mu = matchups[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: const Color(0xFF101426),
            ),
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'vs ${mu.opponentId.toUpperCase()}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFF5F5F5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Matchup: ${mu.ratio}-4',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFF5C542),
                  ),
                ),
                if (mu.summary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    mu.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF3FA7FF),
                    ),
                  ),
                ],
                if (mu.notes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    mu.notes,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFB0BEC5),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
