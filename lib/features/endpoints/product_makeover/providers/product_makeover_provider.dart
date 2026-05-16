import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/providers/auth_provider.dart';
import '../data/product_makeover_repository.dart';

class ProductMakeoverState {
  final String? productImageUrl;
  final String? resultUrl;
  final bool isLoading;
  final String? error;

  const ProductMakeoverState({this.productImageUrl, this.resultUrl, this.isLoading = false, this.error});

  ProductMakeoverState copyWith({String? productImageUrl, String? resultUrl, bool? isLoading, String? error}) {
    return ProductMakeoverState(productImageUrl: productImageUrl ?? this.productImageUrl, resultUrl: resultUrl ?? this.resultUrl, isLoading: isLoading ?? this.isLoading, error: error);
  }
}

class ProductMakeoverNotifier extends Notifier<ProductMakeoverState> {
  @override
  ProductMakeoverState build() => const ProductMakeoverState();

  void setProductImageUrl(String url) => state = state.copyWith(productImageUrl: url);

  Future<void> makeover(String backgroundContext) async {
    if (state.productImageUrl == null) return;
    final token = ref.read(authNotifierProvider);
    if (token is! AuthAuthenticated) { state = state.copyWith(error: 'Not authenticated'); return; }

    try {
      state = state.copyWith(isLoading: true, error: null);
      final repo = ProductMakeoverRepository(ref.read(dioProvider), token.token);
      final result = await repo.makeover(state.productImageUrl!, backgroundContext);
      state = state.copyWith(resultUrl: result, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const ProductMakeoverState();
}

final productMakeoverNotifierProvider = NotifierProvider<ProductMakeoverNotifier, ProductMakeoverState>(() => ProductMakeoverNotifier());