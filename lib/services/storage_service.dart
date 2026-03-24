import 'package:hive/hive.dart';

class StorageService {
  /// Internal method to get the box safely.
  /// If for some reason it's not open, we attempt to open it.
  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen('iqVaultBox')) {
      return await Hive.openBox('iqVaultBox');
    }
    return Hive.box('iqVaultBox');
  }

  /// Saves a value to the box with the given key.
  Future<void> saveValue(String key, dynamic value) async {
    final box = await _getBox();
    await box.put(key, value);
  }

  /// Retrieves a value from the box by its key.
  /// Note: Reverting to async for safety during initialization.
  Future<dynamic> getValue(String key) async {
    final box = await _getBox();
    return box.get(key);
  }

  /// Deletes a value from the box by its key.
  Future<void> deleteValue(String key) async {
    final box = await _getBox();
    await box.delete(key);
  }
}
