import 'package:flutter/material.dart';

class SplytPalette {
  static const deep = Color(0xFF0E2B2E);
  static const deepTeal = Color(0xFF0E2B2E);
  static const ink = Color(0xFF10262A);
  static const surface = Color(0xFF14383C);
  static const tealCard = Color(0xFF14383C);
  static const surfaceHigh = Color(0xFF1B4A46);
  static const mint = Color(0xFF1E8E6D);
  static const mintDeep = Color(0xFF1E8E6D);
  static const coral = Color(0xFFC05C3B);
  static const gold = Color(0xFFD9A441);
  static const goldSoft = Color(0xFFF3DFAF);
  static const mist = Color(0xFFE9E4D6);
  static const mute = Color(0xFF6E7C7C);
  static const cream = Color(0xFFF6F3EC);
  static const lightBg = Color(0xFFF6F3EC);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF10262A);
  static const line = Color(0xFFE7E2D6);
  static const greenSoft = Color(0xFFDCEFE6);
  static const claySoft = Color(0xFFF5E1DA);

  static const categorySwatches = <int>[
    0xFF1E8E6D,
    0xFFC05C3B,
    0xFF4D7C8A,
    0xFFD9A441,
    0xFF7C6B9B,
    0xFFB76E79,
    0xFF3C9C91,
    0xFFB87850,
    0xFF5E9A73,
    0xFF5B7C8A,
  ];
}

class CategoryGlyph {
  const CategoryGlyph(this.key, this.icon, this.label);

  final String key;
  final IconData icon;
  final String label;
}

const categoryGlyphs = <CategoryGlyph>[
  CategoryGlyph('spark', Icons.bolt_rounded, 'Spark'),
  CategoryGlyph('wallet', Icons.account_balance_wallet_rounded, 'Wallet'),
  CategoryGlyph('food', Icons.ramen_dining_rounded, 'Food'),
  CategoryGlyph('bus', Icons.directions_bus_filled_rounded, 'Ride'),
  CategoryGlyph('home', Icons.cottage_rounded, 'Home'),
  CategoryGlyph('heart', Icons.favorite_rounded, 'Love'),
  CategoryGlyph('work', Icons.work_rounded, 'Work'),
  CategoryGlyph('school', Icons.school_rounded, 'Learn'),
  CategoryGlyph('fit', Icons.fitness_center_rounded, 'Move'),
  CategoryGlyph('bag', Icons.shopping_bag_rounded, 'Shop'),
  CategoryGlyph('laptop', Icons.laptop_mac_rounded, 'Tech'),
  CategoryGlyph('save', Icons.savings_rounded, 'Save'),
  CategoryGlyph('music', Icons.headphones_rounded, 'Play'),
  CategoryGlyph('health', Icons.medical_services_rounded, 'Health'),
  CategoryGlyph('phone', Icons.smartphone_rounded, 'Phone'),
  CategoryGlyph('gift', Icons.card_giftcard_rounded, 'Gift'),
  CategoryGlyph('coffee', Icons.local_cafe_rounded, 'Cafe'),
  CategoryGlyph('plane', Icons.flight_takeoff_rounded, 'Travel'),
  CategoryGlyph('pet', Icons.pets_rounded, 'Pets'),
  CategoryGlyph('leaf', Icons.eco_rounded, 'Green'),
];

IconData iconForKey(String key) {
  return categoryGlyphs
      .firstWhere(
        (g) => g.key == key,
        orElse: () => categoryGlyphs.first,
      )
      .icon;
}
