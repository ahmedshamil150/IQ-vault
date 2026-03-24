import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class StorageTestScreen extends StatefulWidget {
  const StorageTestScreen({super.key});

  @override
  State<StorageTestScreen> createState() => _StorageTestScreenState();
}

class _StorageTestScreenState extends State<StorageTestScreen> {
  final StorageService _storageService = StorageService();
  final TextEditingController _controller = TextEditingController();
  String _storedValue = 'No value stored';
  final String _sampleKey = 'sample_key';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _saveValue() async {
    if (_controller.text.isNotEmpty) {
      await _storageService.saveValue(_sampleKey, _controller.text);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Value saved!')));
      }
    }
  }

  void _readValue() async {
    final value = await _storageService.getValue(_sampleKey);
    setState(() {
      _storedValue = (value as String?) ?? 'No value found';
    });
  }

  void _deleteValue() async {
    await _storageService.deleteValue(_sampleKey);
    setState(() {
      _storedValue = 'Value deleted';
    });
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Value deleted!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive Storage Test'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                labelText: 'Enter value to save',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _saveValue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save'),
                ),
                ElevatedButton(
                  onPressed: _readValue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Read'),
                ),
                ElevatedButton(
                  onPressed: _deleteValue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Delete'),
                ),
              ],
            ),
            const SizedBox(height: 40),
            const Text(
              'Stored Value:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(_storedValue, style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
