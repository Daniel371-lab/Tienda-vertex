import 'package:firebase_analytics/firebase_analytics.dart';

import '../../models/order_model.dart';
import '../../models/product_model.dart';

/// Wrapper ligero sobre Firebase Analytics.
/// Envuelve los eventos de e-commerce en métodos tipados
/// para no saturar el código de constantes string.
class AnalyticsService {
  AnalyticsService(this._analytics);
  final FirebaseAnalytics _analytics;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  Future<void> logHomeViewed({String? categorySlug}) =>
      _analytics.logEvent(
        name: 'view_home',
        parameters: {'category': categorySlug ?? 'global'},
      );

  Future<void> logItemListViewed({
    required String categorySlug,
    String? subcategorySlug,
    required int itemCount,
  }) =>
      _analytics.logEvent(
        name: 'view_item_list',
        parameters: {
          'category': categorySlug,
          'subcategory': subcategorySlug ?? 'all',
          'item_count': itemCount,
        },
      );

  Future<void> logItemViewed(Product product) =>
      _analytics.logEvent(
        name: 'view_item',
        parameters: {
          'item_id': product.id,
          'item_name': product.title,
          'price': product.price,
          'category': product.categoryId,
        },
      );

  Future<void> logAddToCart(Product product, int quantity) =>
      _analytics.logEvent(
        name: 'add_to_cart',
        parameters: {
          'item_id': product.id,
          'item_name': product.title,
          'price': product.price,
          'quantity': quantity,
        },
      );

  Future<void> logBeginCheckout({
    required int total,
    required int itemCount,
  }) =>
      _analytics.logEvent(
        name: 'begin_checkout',
        parameters: {
          'value': total,
          'currency': 'PYG',
          'items_count': itemCount,
        },
      );

  Future<void> logPurchase(Order order) =>
      _analytics.logEvent(
        name: 'purchase',
        parameters: {
          'transaction_id': order.id,
          'value': order.total,
          'currency': 'PYG',
          'items_count': order.itemCount,
        },
      );

  Future<void> logSearch(String query, int resultCount) =>
      _analytics.logEvent(
        name: 'search',
        parameters: {'search_term': query, 'results': resultCount},
      );
}