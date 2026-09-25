import 'package:correspondencia_sipe_sipe/core/util/enums.dart';
import 'package:correspondencia_sipe_sipe/features/home/side_menu/helpers/menu_options.dart';
import 'package:flutter_test/flutter_test.dart';

bool _hasMenu(List<dynamic> menus, MenuEnum menu) {
  return menus.any((item) => item.menu == menu && !item.isSection);
}

void main() {
  group('MenuOptions', () {
    test('muestra bandejas operativas visibles', () {
      final menus = MenuOptions.build(
        counts: const {'inbox': 2, 'sent': 5},
      );

      expect(_hasMenu(menus, MenuEnum.dashboard), isTrue);
      expect(_hasMenu(menus, MenuEnum.correspondences), isTrue);
      expect(_hasMenu(menus, MenuEnum.inbox), isTrue);
      expect(_hasMenu(menus, MenuEnum.sent), isTrue);
    });

    test('oculta bandejas mock sin semántica funcional', () {
      final menus = MenuOptions.build(
        counts: const {'inbox': 1, 'sent': 1},
      );

      expect(_hasMenu(menus, MenuEnum.received), isFalse);
      expect(_hasMenu(menus, MenuEnum.observed), isFalse);
      expect(_hasMenu(menus, MenuEnum.archived), isFalse);
    });
  });
}
