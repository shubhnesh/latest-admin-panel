import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/category_model.dart';
import '../models/menu_item_model.dart';
import '../services/category_service.dart';
import '../services/menu_service.dart';

class MenuProvider extends ChangeNotifier {
  final MenuService _service;
  final CategoryService _categoryService;

  MenuProvider(this._service, {CategoryService? categoryService})
      : _categoryService = categoryService ?? CategoryService();

  List<MenuItemModel> _items = [];
  List<CategoryModel> _categoryList = [];

  bool isLoading = false;
  String? errorMessage;

  String selectedCategory = 'All';
  String searchQuery = '';

  List<MenuItemModel> get items => List.unmodifiable(_items);

  /// Categories as fetched from the `menu_categories` collection, each
  /// carrying its own (optional) subcategories. No hardcoded category.
  List<CategoryModel> get categoryList => List.unmodifiable(_categoryList);

  List<String> get categories =>
      ['All', ..._categoryList.map((category) => category.name)];

  List<MenuItemModel> get filteredItems {
    final query = searchQuery.trim().toLowerCase();

    return _items.where((item) {
      final matchesCategory = selectedCategory == 'All' ||
          item.primaryCategoryId == _categoryId(selectedCategory);

      final matchesSearch = query.isEmpty ||
          item.name.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query);

      return matchesCategory && matchesSearch;
    }).toList();
  }

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.fetchMenuItems(),
        _categoryService.fetchCategories(),
      ]);
      _items = results[0] as List<MenuItemModel>;
      _categoryList = results[1] as List<CategoryModel>;
    } catch (e) {
      errorMessage = 'Failed to load menu: $e';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// Refreshes just the category list (e.g. after creating one elsewhere)
  /// without re-fetching every menu item.
  Future<void> loadCategories() async {
    try {
      _categoryList = await _categoryService.fetchCategories();
      notifyListeners();
    } catch (_) {
      // Category refresh is non-critical — keep whatever was loaded before.
    }
  }

  Future<MenuItemModel> getItemById(String id) {
    return _service.fetchItemById(id);
  }

  List<String> subCategoriesFor(String category) {
    final match = _categoryList.where((item) => item.name == category);
    if (match.isEmpty) return [];
    return match.first.subcategories.map((sub) => sub.name).toList();
  }

  String _categoryId(String category) {
    final match = _categoryList.where((item) => item.name == category);
    return match.isEmpty ? category : match.first.id;
  }

  void setCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    notifyListeners();
  }

  Future<bool> saveItem(MenuItemModel item) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _service.saveItem(item);

      // Reload so the newly created Firestore document and
      // server timestamps are reflected in the provider.
      _items = await _service.fetchMenuItems();

      return true;
    } catch (e) {
      errorMessage = 'Failed to save menu item.';
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleAvailability(
    MenuItemModel item,
  ) async {
    try {
      final newValue = !item.available;

      await _service.toggleAvailability(
        item.id,
        newValue,
      );

      final index = _items.indexWhere(
        (element) => element.id == item.id,
      );

      if (index != -1) {
        _items[index] = item.copyWith(
          available: newValue,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update availability.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteItem(String id) async {
    try {
      await _service.deleteItem(id);

      _items.removeWhere(
        (item) => item.id == id,
      );

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to delete menu item.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateDisplaySettings({
    required MenuItemModel item,
    required bool showOnMobileApp,
    required bool featuredItem,
  }) async {
    try {
      await _service.updateDisplaySettings(
        id: item.id,
        showOnMobileApp: showOnMobileApp,
        featuredItem: featuredItem,
      );

      final index = _items.indexWhere(
        (element) => element.id == item.id,
      );

      if (index != -1) {
        _items[index] = item.copyWith(
          showOnMobileApp: showOnMobileApp,
          featuredItem: featuredItem,
        );
      }

      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'Failed to update display settings.';
      notifyListeners();
      return false;
    }
  }
}

/// Riverpod provider wrapping [MenuProvider].
final menuProvider = ChangeNotifierProvider<MenuProvider>(
  (ref) => MenuProvider(MenuService()),
);
