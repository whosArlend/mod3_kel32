import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mod3_kel32/main.dart';
import 'package:mod3_kel32/screens/detail.dart';
import 'package:mod3_kel32/screens/favorites.dart';
import 'package:mod3_kel32/screens/history.dart';
import 'package:mod3_kel32/screens/home.dart';

void main() {
  setUp(() {
    FavoritesManager.favoritesNotifier.value = [];
    HistoryManager.historyNotifier.value = [];
  });

  testWidgets(
    'Country app displays its 4 main navigation tabs, search bar, and region filter',
    (WidgetTester tester) async {
      await tester.pumpWidget(const CountryApp());

      expect(find.text('Countries'), findsOneWidget);
      expect(find.text('Search country...'), findsOneWidget);
      expect(find.text('Region: '), findsOneWidget);
      expect(find.text('All Regions'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
    },
  );

  testWidgets('Navigation switches across all 4 pages',
      (WidgetTester tester) async {
    await tester.pumpWidget(const CountryApp());

    // Switch to Favorites
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();
    expect(find.text('No favorite countries'), findsOneWidget);

    // Switch to History
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No history yet'), findsOneWidget);

    // Switch to Profile
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Alif Arlendi Putra Priyanto'), findsOneWidget);
    expect(find.text('21120123140042'), findsOneWidget);

    // Return to Home via Home icon on Profile AppBar
    await tester.tap(find.byIcon(Icons.home).first);
    await tester.pumpAndSettle();
    expect(find.text('Countries'), findsOneWidget);
  });

  group('HistoryManager Tests', () {
    final countryA = Country(
      name: 'Indonesia',
      region: 'Asia',
      population: 273523615,
      capital: 'Jakarta',
    );
    final countryB = Country(
      name: 'Japan',
      region: 'Asia',
      population: 125836021,
      capital: 'Tokyo',
    );

    test('Adding to history inserts at the beginning and avoids duplicates', () {
      HistoryManager.addToHistory(countryA);
      expect(HistoryManager.history.length, 1);
      expect(HistoryManager.history.first.name, 'Indonesia');

      HistoryManager.addToHistory(countryB);
      expect(HistoryManager.history.length, 2);
      expect(HistoryManager.history.first.name, 'Japan');

      // Re-adding Indonesia moves it to the top
      HistoryManager.addToHistory(countryA);
      expect(HistoryManager.history.length, 2);
      expect(HistoryManager.history.first.name, 'Indonesia');
      expect(HistoryManager.history[1].name, 'Japan');
    });

    test('Hard delete single item removes item from history', () {
      HistoryManager.addToHistory(countryA);
      HistoryManager.addToHistory(countryB);

      HistoryManager.removeFromHistory(countryA);
      expect(HistoryManager.history.length, 1);
      expect(HistoryManager.history.any((c) => c.name == 'Indonesia'), isFalse);
    });

    test('Hard delete all clears the history completely', () {
      HistoryManager.addToHistory(countryA);
      HistoryManager.addToHistory(countryB);

      HistoryManager.clearHistory();
      expect(HistoryManager.history.isEmpty, isTrue);
    });
  });

  testWidgets(
      'DetailPage automatically adds country to history and updates position',
      (WidgetTester tester) async {
    final country = Country(
      name: 'Germany',
      region: 'Europe',
      population: 83240525,
      capital: 'Berlin',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DetailPage(country: country),
      ),
    );

    expect(HistoryManager.history.length, 1);
    expect(HistoryManager.history.first.name, 'Germany');
  });

  testWidgets(
      'HistoryPage displays items and supports single delete and clear all',
      (WidgetTester tester) async {
    final country1 = Country(
      name: 'Canada',
      region: 'Americas',
      population: 38005238,
      capital: 'Ottawa',
    );
    final country2 = Country(
      name: 'Brazil',
      region: 'Americas',
      population: 212559417,
      capital: 'Brasília',
    );

    HistoryManager.addToHistory(country1);
    HistoryManager.addToHistory(country2);

    await tester.pumpWidget(
      const MaterialApp(
        home: HistoryPage(),
      ),
    );

    expect(find.text('Brazil'), findsOneWidget);
    expect(find.text('Canada'), findsOneWidget);

    // Hard delete single item (Brazil)
    final deleteButtons = find.byIcon(Icons.delete_outline);
    await tester.tap(deleteButtons.first);
    await tester.pumpAndSettle();

    expect(find.text('Brazil'), findsNothing);
    expect(find.text('Canada'), findsOneWidget);

    // Hard delete all via clear button
    final clearAllBtn = find.byIcon(Icons.delete_sweep);
    await tester.tap(clearAllBtn);
    await tester.pumpAndSettle();

    // Confirm dialog
    expect(find.text('Clear All History'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(find.text('No history yet'), findsOneWidget);
    expect(HistoryManager.history.isEmpty, isTrue);
  });

  test('Search and Region filtering logic works correctly and in combination', () {
    final list = [
      Country(name: 'Indonesia', region: 'Asia', population: 273523615),
      Country(name: 'India', region: 'Asia', population: 1380004385),
      Country(name: 'Japan', region: 'Asia', population: 125836021),
      Country(name: 'Germany', region: 'Europe', population: 83240525),
      Country(name: 'United States', region: 'Americas', population: 331002651),
      Country(name: 'United Kingdom', region: 'Europe', population: 67215293),
    ];

    List<Country> filter(String query, String region) {
      return list.where((country) {
        final matchesSearch = country.name
            .toLowerCase()
            .contains(query.trim().toLowerCase());
        final matchesRegion = region == 'All Regions' ||
            country.region.trim().toLowerCase() == region.toLowerCase();
        return matchesSearch && matchesRegion;
      }).toList();
    }

    // Search only
    expect(filter('indo', 'All Regions').map((c) => c.name).toList(), ['Indonesia']);
    expect(filter('jap', 'All Regions').map((c) => c.name).toList(), ['Japan']);
    expect(filter('united', 'All Regions').map((c) => c.name).toList(), ['United States', 'United Kingdom']);

    // Region only
    expect(filter('', 'Asia').length, 3);
    expect(filter('', 'Europe').length, 2);

    // Combined search and region
    expect(filter('united', 'Europe').map((c) => c.name).toList(), ['United Kingdom']);
    expect(filter('indo', 'Asia').map((c) => c.name).toList(), ['Indonesia']);
    expect(filter('indo', 'Europe').isEmpty, isTrue);
  });
}