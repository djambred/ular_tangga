import 'package:flutter/material.dart';

class Player {
  final int id;
  final String name;
  int position;
  final MaterialColor color;

  Player({
    required this.id,
    required this.name,
    this.position = 0,
    required this.color,
  });
}
