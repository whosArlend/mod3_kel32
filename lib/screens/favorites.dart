import 'package:flutter/material.dart';
import 'detail.dart';
import 'home.dart';

class FavoritesManager {
  static final ValueNotifier<List<Country>> favoritesNotifier =
      ValueNotifier<List<Country>>([]);

  static List<Country> get favorites => favoritesNotifier.value;

  static bool isFavorite(Country country) {
    return favoritesNotifier.value.any((c) => c.name == country.name);
  }

  static void toggleFavorite(Country country) {
    final currentList = List<Country>.from(favoritesNotifier.value);
    final index = currentList.indexWhere((c) => c.name == country.name);
    if (index >= 0) {
      currentList.removeAt(index);
    } else {
      currentList.add(country);
    }
    favoritesNotifier.value = currentList;
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: ValueListenableBuilder<List<Country>>(
        valueListenable: FavoritesManager.favoritesNotifier,
        builder: (context, favorites, _) {
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'No favorite countries',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, i) {
              final country = favorites[i];

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
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      FavoritesManager.toggleFavorite(country);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Removed ${country.name} from favorites',
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
