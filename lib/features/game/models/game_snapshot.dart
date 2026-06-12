class GameSnapshot {
  const GameSnapshot({
    required this.id,
    required this.status,
    required this.version,
    required this.players,
    required this.viewerAvailableActions,
    required this.viewerLegalCardIds,
    required this.currentTrick,
    required this.roundScores,
    this.roundScoreAckCount = 0,
    this.viewerRoundScoreAcked = false,
    this.currentTurnPlayerId,
    this.dealerPlayerId,
    this.highestBidderPlayerId,
    this.trumpSuit,
    this.leadSuit,
    this.winnerPlayerIds = const [],
    this.roundNumber = 0,
    this.totalRounds = 0,
    this.cardsPerPlayer = 0,
  });

  final String id;
  final String status;
  final int version;
  final List<PlayerSnapshot> players;
  final String? currentTurnPlayerId;
  final String? dealerPlayerId;
  final String? highestBidderPlayerId;
  final String? trumpSuit;
  final String? leadSuit;
  final List<String> winnerPlayerIds;
  final int roundNumber;
  final int totalRounds;
  final int cardsPerPlayer;
  final List<String> viewerAvailableActions;
  final List<String> viewerLegalCardIds;
  final List<PlayedCardSnapshot> currentTrick;
  final List<RoundScoreSnapshot> roundScores;
  final int roundScoreAckCount;
  final bool viewerRoundScoreAcked;

  factory GameSnapshot.fromJson(Map<String, dynamic> json) {
    return GameSnapshot(
      id: json['id'] as String,
      status: json['status'] as String,
      version: json['version'] as int,
      currentTurnPlayerId: json['currentTurnPlayerId'] as String?,
      dealerPlayerId: json['dealerPlayerId'] as String?,
      highestBidderPlayerId: json['highestBidderPlayerId'] as String?,
      trumpSuit: json['trumpSuit'] as String?,
      leadSuit: json['leadSuit'] as String?,
      winnerPlayerIds: ((json['winnerPlayerIds'] as List<dynamic>?) ?? [])
          .map((item) => item as String)
          .toList(),
      roundNumber: (json['roundNumber'] as int?) ?? 0,
      totalRounds: (json['totalRounds'] as int?) ?? 0,
      cardsPerPlayer: (json['cardsPerPlayer'] as int?) ?? 0,
      viewerAvailableActions:
          ((json['viewerAvailableActions'] as List<dynamic>?) ?? [])
              .map((item) => item as String)
              .toList(),
      viewerLegalCardIds: ((json['viewerLegalCardIds'] as List<dynamic>?) ?? [])
          .map((item) => item as String)
          .toList(),
      currentTrick: ((json['currentTrick'] as List<dynamic>?) ?? [])
          .map((item) =>
              PlayedCardSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
      roundScores: ((json['roundScores'] as List<dynamic>?) ?? [])
          .map((item) =>
              RoundScoreSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
      roundScoreAckCount: (json['roundScoreAckCount'] as int?) ?? 0,
      viewerRoundScoreAcked: (json['viewerRoundScoreAcked'] as bool?) ?? false,
      players: (json['players'] as List<dynamic>)
          .map((item) => PlayerSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  PlayerSnapshot? player(String playerId) {
    for (final player in players) {
      if (player.id == playerId) {
        return player;
      }
    }
    return null;
  }
}

class RoundScoreSnapshot {
  const RoundScoreSnapshot({
    required this.roundNumber,
    required this.players,
  });

  final int roundNumber;
  final List<PlayerRoundScoreSnapshot> players;

  factory RoundScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return RoundScoreSnapshot(
      roundNumber: (json['roundNumber'] as int?) ?? 0,
      players: (((json['players'] ?? json['Players']) as List<dynamic>?) ?? [])
          .map((item) =>
              PlayerRoundScoreSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlayerRoundScoreSnapshot {
  const PlayerRoundScoreSnapshot({
    required this.playerId,
    required this.bid,
    required this.tricksWon,
    required this.scoreEarned,
    required this.totalScore,
  });

  final String playerId;
  final int bid;
  final int tricksWon;
  final int scoreEarned;
  final int totalScore;

  factory PlayerRoundScoreSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerRoundScoreSnapshot(
      playerId: json['playerId'] as String,
      bid: (json['bid'] as int?) ?? 0,
      tricksWon: (json['tricksWon'] as int?) ?? 0,
      scoreEarned: (json['scoreEarned'] as int?) ?? 0,
      totalScore: (json['totalScore'] as int?) ?? 0,
    );
  }
}

class PlayerSnapshot {
  const PlayerSnapshot({
    required this.id,
    required this.seat,
    required this.status,
    required this.handSize,
    required this.bid,
    required this.hasBid,
    required this.tricksWon,
    required this.roundScore,
    required this.totalScore,
    required this.hand,
  });

  final String id;
  final int seat;
  final String status;
  final int handSize;
  final int bid;
  final bool hasBid;
  final int tricksWon;
  final int roundScore;
  final int totalScore;
  final List<CardSnapshot> hand;

  factory PlayerSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSnapshot(
      id: json['id'] as String,
      seat: json['seat'] as int,
      status: json['status'] as String,
      handSize: json['handSize'] as int,
      bid: (json['bid'] as int?) ?? 0,
      hasBid: (json['hasBid'] as bool?) ?? false,
      tricksWon: (json['tricksWon'] as int?) ?? 0,
      roundScore: (json['roundScore'] as int?) ?? 0,
      totalScore: (json['totalScore'] as int?) ?? 0,
      hand: ((json['hand'] as List<dynamic>?) ?? <dynamic>[])
          .map((item) => CardSnapshot.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class PlayedCardSnapshot {
  const PlayedCardSnapshot({
    required this.playerId,
    required this.card,
  });

  final String playerId;
  final CardSnapshot card;

  factory PlayedCardSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayedCardSnapshot(
      playerId: json['playerId'] as String,
      card: CardSnapshot.fromJson(json['card'] as Map<String, dynamic>),
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
