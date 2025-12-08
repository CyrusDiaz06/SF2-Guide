import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;


void main() {
  runApp(const Sf2GuideApp());
}

class Move {
  final String name;
  final String input;
  final String type; // "Special", "Normal", "Throw"
  final List<String> tags;
  final String notes;

  const Move({
    required this.name,
    required this.input,
    required this.type,
    this.tags = const [],
    this.notes = '',
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
    );
  }
}

class Fighter {
  final String id;
  final String name;
  final String archetype;
  final List<Move> moves;

  const Fighter({
    required this.id,
    required this.name,
    required this.archetype,
    required this.moves,
  });

  factory Fighter.fromJson(Map<String, dynamic> json) {
    final movesJson = json['moves'] as List<dynamic>? ?? [];
    return Fighter(
      id: json['id'] as String,
      name: json['name'] as String,
      archetype: json['archetype'] as String,
      moves: movesJson
          .map((m) => Move.fromJson(m as Map<String, dynamic>))
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
          primary: Color(0xFFF5C542),
          secondary: Color(0xFF3FA7FF),
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

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

          final fighters = snapshot.data ?? [];

          return CharacterListScreen(fighters: fighters);
        },
      ),
    );
  }
}


class CharacterDetailScreen extends StatelessWidget {
  final Fighter fighter;

  const CharacterDetailScreen({super.key, required this.fighter});

  @override
  Widget build(BuildContext context) {
    final specials =
        fighter.moves.where((m) => m.type == 'Special').toList();
    final normals =
        fighter.moves.where((m) => m.type == 'Normal').toList();
    final throws =
        fighter.moves.where((m) => m.type == 'Throw').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(fighter.name),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
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
      ),
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
}
