class GameSnapshot {
  const GameSnapshot({
    required this.id,
    required this.status,
    required this.version,
    required this.players,
    this.currentTurnPlayerId,
    this.winnerPlayerId,
  });

  final String id;
  final String status;
  final int version;
  final List<PlayerSnapshot> players;
  final String? currentTurnPlayerId;
  final String? winnerPlayerId;

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      id: json['id'] as String,
      status: json['status'] as String,
      version: json['version'] as int,
      currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
      winnerPlayerId: json['winnerPlayerId'] as String?,
      players: (json['players'] as List<dynamic>)
          .map((item) => PlayerSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.id,
    required this.seat,
    required this.status,
    required this.handSize,
    required this.score,
    required this.hand,
  });

  final String id;
  final int seat;
  final String status;
  final int handSize;
  final int score;
  final List<CardSnapshot> hand;

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSnapshot(
      id: json['id'] as String,
      seat: json['seat'] as int,
      status: json['status'] as String,
      handSize: json['handSize'] as int,
      score: json['score'] as int,
      hand: ((json['hand'] as List<dynamic>?) ?? <dynamic>[])
          .map((item) => CardSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class CardSnapshot {
  const CardSnapshot({
    required this.id,
    required this.rank,
    required this.suit,
    required this.value,
  });

  final String id;
  final String rank;
  final String suit;
  final int value;

  factory CardSnapshot.fromJson(Map<String, dynamic> json) {
    return CardSnapshot(
      id: json['id'] as String,
      rank: json['rank'] as String,
      suit: json['suit'] as String,
      value: json['value'] as int,
    );
  }
}
