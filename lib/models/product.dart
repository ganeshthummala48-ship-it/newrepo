import 'package:flutter/material.dart';

class Product {
  final String id;
  final String name;
  final String category; // 'Fertilizer', 'Seed', 'Pesticide'
  final double price;
  final String unit;
  final String description;
  final IconData imageIcon;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.unit,
    required this.description,
    required this.imageIcon,
    this.imageUrl,
  });
}
