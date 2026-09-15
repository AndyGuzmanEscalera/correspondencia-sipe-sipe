import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class MenuItemData extends Equatable {
  const MenuItemData({
    required this.menu,
    required this.title,
    required this.icon,
    this.badge,
    this.isSection = false,
  });

  final MenuEnum menu;
  final String title;
  final IconData icon;
  final int? badge;
  final bool isSection;

  @override
  List<Object?> get props => [menu, title, icon, badge, isSection];
}
