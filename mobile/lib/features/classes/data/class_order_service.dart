import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final classOrderServiceProvider = Provider((ref) => ClassOrderService());

class ClassOrderService {
  static const String _classOrderKey = 'class_order';

  Future<List<String>> getClassOrder() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_classOrderKey) ?? [];
  }

  Future<void> saveClassOrder(List<String> orderedIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_classOrderKey, orderedIds);
  }
}
