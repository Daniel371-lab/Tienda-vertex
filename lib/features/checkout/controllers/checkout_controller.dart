import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado del formulario de checkout.
class CheckoutState {
  const CheckoutState({
    this.fullName = '',
    this.phone = '',
    this.department,
    this.city,
    this.address = '',
    this.couponCode = '',
    this.appliedCouponCode,
    this.discountAmount = 0,
    this.couponError,
    this.isSubmitting = false,
    this.error,
  });

  final String fullName;
  final String phone;
  final String? department;
  final String? city;
  final String address;
  final String couponCode;
  final String? appliedCouponCode;
  final int discountAmount;
  final String? couponError;
  final bool isSubmitting;
  final String? error;

  bool get hasCoupon => appliedCouponCode != null;

  CheckoutState copyWith({
    String? fullName,
    String? phone,
    String? department,
    String? city,
    String? address,
    String? couponCode,
    String? appliedCouponCode,
    int? discountAmount,
    String? couponError,
    bool? isSubmitting,
    String? error,
    bool clearCoupon = false,
    bool clearCouponError = false,
    bool clearError = false,
  }) {
    return CheckoutState(
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      department: department ?? this.department,
      city: city ?? this.city,
      address: address ?? this.address,
      couponCode: couponCode ?? this.couponCode,
      appliedCouponCode: clearCoupon
          ? null
          : (appliedCouponCode ?? this.appliedCouponCode),
      discountAmount:
          clearCoupon ? 0 : (discountAmount ?? this.discountAmount),
      couponError:
          clearCouponError ? null : (couponError ?? this.couponError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController() : super(const CheckoutState());

  void setFullName(String v) =>
      state = state.copyWith(fullName: v, clearError: true);

  void setPhone(String v) =>
      state = state.copyWith(phone: v, clearError: true);

  void setDepartment(String? v) {
    state = state.copyWith(
      department: v,
      city: null,
      clearError: true,
    );
  }

  void setCity(String? v) =>
      state = state.copyWith(city: v, clearError: true);

  void setAddress(String v) =>
      state = state.copyWith(address: v, clearError: true);

  void setCouponCode(String v) => state = state.copyWith(
        couponCode: v,
        clearCouponError: true,
      );

  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);

  void setError(String msg) =>
      state = state.copyWith(error: msg, isSubmitting: false);

  void applyCoupon({
    required String code,
    required int discountAmount,
  }) {
    state = state.copyWith(
      appliedCouponCode: code,
      discountAmount: discountAmount,
      clearCouponError: true,
    );
  }

  void rejectCoupon(String message) {
    state = state.copyWith(
      couponError: message,
      appliedCouponCode: null,
      discountAmount: 0,
    );
  }

  void removeCoupon() => state = state.copyWith(
        clearCoupon: true,
        couponCode: '',
        clearCouponError: true,
      );

  void reset() => state = const CheckoutState();
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController();
});