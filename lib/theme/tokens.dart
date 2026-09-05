import 'package:flutter/material.dart';

class SplytPalette {
  static const deep = Color(0xFF061018);
  static const ink = Color(0xFF0B1A22);
  static const surface = Color(0xFF12262F);
  static const surfaceHigh = Color(0xFF1A3340);
  static const mint = Color(0xFF00E5A8);
  static const mintDeep = Color(0xFF0B8F6E);
  static const coral = Color(0xFFFF5A36);
  static const gold = Color(0xFFFFC857);
  static const mist = Color(0xFFD7EDE4);
  static const mute = Color(0xFF7F9A91);
  static const cream = Color(0xFFF4FBF7);
  static const lightBg = Color(0xFFECF4F0);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightInk = Color(0xFF102027);

  static const categorySwatches = <int>[
    0xFF00E5A8,
    0xFFFF5A36,
    0xFF4D9FFF,
    0xFFFFC857,
    0xFFB388FF,
    0xFFFF7AD9,
    0xFF2EE6D6,
    0xFFFF8A5B,
    0xFF7CFFB2,
    0xFF5B7CFF,
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
