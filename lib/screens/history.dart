import 'package:flutter/material.dart';
import 'detail.dart';
import 'home.dart';

class HistoryManager {
  static final ValueNotifier<List<Country>> historyNotifier =
      ValueNotifier<List<Country>>([]);

  static List<Country> get history => historyNotifier.value;

  /// Menambahkan negara ke riwayat.
  /// Jika negara sudah ada, entri lama dihapus dan dipindahkan ke posisi paling depan (terbaru).
  static void addToHistory(Country country) {
    final currentList = List<Country>.from(historyNotifier.value);
    currentList.removeWhere((c) => c.name == country.name);
    currentList.insert(0, country);
    historyNotifier.value = currentList;
  }

  /// Menghapus satu item negara dari riwayat (hard delete).
  static void removeFromHistory(Country country) {
    final currentList = List<Country>.from(historyNotifier.value);
    currentList.removeWhere((c) => c.name == country.name);
    historyNotifier.value = currentList;
  }

  /// Menghapus seluruh riwayat (hard delete all).
  static void clearHistory() {
    historyNotifier.value = [];
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          ValueListenableBuilder<List<Country>>(
            valueListenable: HistoryManager.historyNotifier,
            builder: (context, history, _) {
              if (history.isEmpty) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                tooltip: 'Clear all history',
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear All History'),
                      content: const Text(
                        'Are you sure you want to delete all viewing history?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            HistoryManager.clearHistory();
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('All history cleared'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          },
                          child: const Text(
                            'Clear',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      body: ValueListenableBuilder<List<Country>>(
        valueListenable: HistoryManager.historyNotifier,
        builder: (context, history, _) {
          if (history.isEmpty) {
            return const Center(
              child: Text(
                'No history yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, i) {
              final country = history[i];

              return Card(
                child: ListTile(
                  leading: country.flagsPng != null
                      ? Image.network(
                          country.flagsPng!,
                          width: 50,
                        )
                      : const SizedBox(width: 50),
                  title: Text(country.name),
                  subtitle: Text(country.region),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
                    tooltip: 'Remove from history',
                    onPressed: () {
                      HistoryManager.removeFromHistory(country);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Removed ${country.name} from history',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailPage(country: country),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
