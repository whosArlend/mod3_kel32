import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'detail.dart';
import 'favorites.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Country>> countries;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedRegion = 'All Regions';

  final List<String> _regions = const [
    'All Regions',
    'Africa',
    'Americas',
    'Asia',
    'Europe',
    'Oceania',
  ];

  @override
  void initState() {
    super.initState();
    countries = fetchCountries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<List<Country>> fetchCountries() async {
    final uri = Uri.parse('https://www.apicountries.com/countries');
    final request = await HttpClient().getUrl(uri);
    final response = await request.close();

    if (response.statusCode == 200) {
      final respBody = await response.transform(utf8.decoder).join();
      final List jsonData = jsonDecode(respBody);

      return jsonData.map((j) => Country.fromJson(j)).toList();
    } else {
      throw Exception(
        'Failed to load countries: ${response.statusCode}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Countries'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search country...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: Row(
              children: [
                const Icon(Icons.public, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Region: ',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: _selectedRegion,
                        items: _regions.map((String region) {
                          return DropdownMenuItem<String>(
                            value: region,
                            child: Text(region),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRegion = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Country>>(
              future: countries,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No countries found'),
                  );
                }

                final allCountries = snapshot.data!;
                final filteredCountries = allCountries.where((country) {
                  final matchesSearch = country.name
                      .toLowerCase()
                      .contains(_searchQuery.trim().toLowerCase());
                  final matchesRegion = _selectedRegion == 'All Regions' ||
                      country.region.trim().toLowerCase() ==
                          _selectedRegion.toLowerCase();
                  return matchesSearch && matchesRegion;
                }).toList();

                if (filteredCountries.isEmpty) {
                  return const Center(
                    child: Text('No countries found'),
                  );
                }

                return ListView.builder(
                  itemCount: filteredCountries.length,
                  itemBuilder: (context, i) {
                    final country = filteredCountries[i];

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
                        trailing: ValueListenableBuilder<List<Country>>(
                          valueListenable: FavoritesManager.favoritesNotifier,
                          builder: (context, favorites, _) {
                            final isFav =
                                favorites.any((c) => c.name == country.name);
                            return IconButton(
                              icon: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : null,
                              ),
                              onPressed: () {
                                FavoritesManager.toggleFavorite(country);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFav
                                          ? 'Removed ${country.name} from favorites'
                                          : 'Added ${country.name} to favorites',
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  DetailPage(country: country),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class Country {
  final String name;
  final String region;
  final String? capital;
  final int population;
  final String? flagsPng;
  final List<dynamic>? languages;
  final List<dynamic>? currencies;

  Country({
    required this.name,
    required this.region,
    required this.population,
    this.capital,
    this.flagsPng,
    this.languages,
    this.currencies,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    List<dynamic>? langs;

    if (json['languages'] != null) {
      langs = (json['languages'] as List)
          .map((l) => l['name'].toString())
          .toList();
    }

    List<dynamic>? cur;

    if (json['currencies'] != null) {
      cur = (json['currencies'] as List)
          .map((c) => c['name'].toString())
          .toList();
    }

    return Country(
      name: json['name'] ?? 'N/A',
      region: json['region'] ?? 'N/A',
      population: json['population'] ?? 0,
      capital: json['capital'],
      flagsPng: json['flags'] != null
          ? json['flags']['png']
          : null,
      languages: langs,
      currencies: cur,
    );
  }
}