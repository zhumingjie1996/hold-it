import 'dart:convert';
import 'package:uuid/uuid.dart';

class ResistRecord {
  final String id;
  String category;
  String categoryEmoji;
  String categoryID;
  String note;
  final DateTime createdAt;
  double? amount;

  ResistRecord({
    String? id,
    required this.category,
    required this.categoryEmoji,
    required this.categoryID,
    this.note = '',
    this.amount,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now();

  String get effectiveCategoryID => categoryID.isEmpty ? category : categoryID;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'category_emoji': categoryEmoji,
      'category_id': categoryID,
      'note': note,
      'created_at': createdAt.millisecondsSinceEpoch,
      'amount': amount,
    };
  }

  factory ResistRecord.fromMap(Map<String, dynamic> map) {
    return ResistRecord(
      id: map['id'],
      category: map['category'],
      categoryEmoji: map['category_emoji'],
      categoryID: map['category_id'],
      note: map['note'],
      amount: map['amount'],
    );
  }
}

class CustomCategory {
  final String id;
  String emoji;
  String name;
  bool hasAmount;
  double? defaultAmount;
  final DateTime createdAt;

  CustomCategory({
    String? id,
    required this.emoji,
    required this.name,
    required this.hasAmount,
    this.defaultAmount,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'emoji': emoji,
      'name': name,
      'has_amount': hasAmount ? 1 : 0,
      'default_amount': defaultAmount,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory CustomCategory.fromMap(Map<String, dynamic> map) {
    return CustomCategory(
      id: map['id'],
      emoji: map['emoji'],
      name: map['name'],
      hasAmount: map['has_amount'] == 1,
      defaultAmount: map['default_amount'],
    );
  }
}

class ResistCategory {
  final String id;
  final String emoji;
  final String name;
  final bool hasAmount;
  final double? defaultAmount;
  final bool isCustom;
  final String? customCategoryID;
  final String? fixedID;
  final String placeholder;

  String get stableID {
    if (isCustom && customCategoryID != null) {
      return customCategoryID!;
    }
    return fixedID ?? name;
  }

  ResistCategory({
    required this.id,
    required this.emoji,
    required this.name,
    this.defaultAmount,
    this.isCustom = false,
    this.customCategoryID,
    this.fixedID,
    this.placeholder = '',
  })  : hasAmount = defaultAmount != null;

  ResistCategory.fromCustom(CustomCategory custom)
      : id = custom.id,
        emoji = custom.emoji,
        name = custom.name,
        hasAmount = custom.hasAmount,
        defaultAmount = custom.defaultAmount,
        isCustom = true,
        customCategoryID = custom.id,
        fixedID = null,
        placeholder = '';

  static List<ResistCategory> get defaults => [
        ResistCategory(
          id: const Uuid().v4(),
          emoji: '🧋',
          name: '奶茶',
          defaultAmount: 15,
          fixedID: 'default_milk_tea',
          placeholder: '忍住没喝一杯…',
        ),
        ResistCategory(
          id: const Uuid().v4(),
          emoji: '💸',
          name: '冲动消费',
          defaultAmount: 100,
          fixedID: 'default_impulse_buy',
          placeholder: '忍住买了一个…',
        ),
        ResistCategory(
          id: const Uuid().v4(),
          emoji: '🎮',
          name: '游戏',
          fixedID: 'default_gaming',
          placeholder: '忍住又玩了一局…',
        ),
        ResistCategory(
          id: const Uuid().v4(),
          emoji: '📱',
          name: '短视频',
          fixedID: 'default_short_video',
          placeholder: '忍住刷了一会…',
        ),
        ResistCategory(
          id: const Uuid().v4(),
          emoji: '❤️',
          name: '想TA',
          fixedID: 'default_miss_him',
          placeholder: '聊表心意',
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResistCategory && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum RewardStatus { inProgress, unlocked, redeemed }

class Reward {
  final String id;
  String title;
  String rewardDescription;
  List<int>? imageData;
  int targetCoins;
  int currentCoins;
  List<String> categoryIDs;
  RewardStatus status;
  final DateTime createdAt;
  DateTime? unlockedAt;
  DateTime? redeemedAt;

  double get progress => targetCoins > 0 ? (currentCoins / targetCoins).clamp(0.0, 1.0) : 0.0;

  Reward({
    String? id,
    required this.title,
    this.rewardDescription = '',
    this.imageData,
    required this.targetCoins,
    required this.categoryIDs,
  })  : id = id ?? const Uuid().v4(),
        currentCoins = 0,
        status = RewardStatus.inProgress,
        createdAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'reward_description': rewardDescription,
      'image_data': imageData,
      'target_coins': targetCoins,
      'current_coins': currentCoins,
      'category_ids': jsonEncode(categoryIDs),
      'status_raw': status.name,
      'created_at': createdAt.millisecondsSinceEpoch,
      'unlocked_at': unlockedAt?.millisecondsSinceEpoch,
      'redeemed_at': redeemedAt?.millisecondsSinceEpoch,
    };
  }

  factory Reward.fromMap(Map<String, dynamic> map) {
    final r = Reward(
      id: map['id'],
      title: map['title'],
      rewardDescription: map['reward_description'],
      imageData: map['image_data'],
      targetCoins: map['target_coins'],
      categoryIDs: List<String>.from(jsonDecode(map['category_ids'])),
    );
    r.currentCoins = map['current_coins'];
    r.status = RewardStatus.values.firstWhere(
      (e) => e.name == map['status_raw'],
      orElse: () => RewardStatus.inProgress,
    );
    if (map['unlocked_at'] != null) {
      r.unlockedAt = DateTime.fromMillisecondsSinceEpoch(map['unlocked_at']);
    }
    if (map['redeemed_at'] != null) {
      r.redeemedAt = DateTime.fromMillisecondsSinceEpoch(map['redeemed_at']);
    }
    return r;
  }
}

class RewardCoinRecord {
  final String id;
  String rewardID;
  String restraintRecordID;
  int coins;
  final DateTime createdAt;

  RewardCoinRecord({
    String? id,
    required this.rewardID,
    required this.restraintRecordID,
    this.coins = 1,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'reward_id': rewardID,
      'restraint_record_id': restraintRecordID,
      'coins': coins,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory RewardCoinRecord.fromMap(Map<String, dynamic> map) {
    return RewardCoinRecord(
      id: map['id'],
      rewardID: map['reward_id'],
      restraintRecordID: map['restraint_record_id'],
      coins: map['coins'],
    );
  }
}
