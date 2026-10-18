import 'package:flutter_riverpod/flutter_riverpod.dart';

class CheckoutState {
  const CheckoutState({
    this.fullName = '',
    this.phone = '',
    this.department,
    this.city,
    this.neighborhood = '',
    this.street1 = '',
    this.street2 = '',
    this.locationType = 'Casa',
    this.reference = '',
    this.googleMapsLink = '',
    this.couponCode = '',
    this.appliedCouponCode,
    this.discountAmount = 0,
    this.couponError,
    this.holderName = '',
    this.sourceBank,
    this.isSubmitting = false,
    this.error,
  });

  final String fullName;
  final String phone;
  final String? department;
  final String? city;
  final String neighborhood;
  final String street1;
  final String street2;
  final String locationType; // "Casa" o "Trabajo"
  final String reference;
  final String googleMapsLink;
  final String couponCode;
  final String? appliedCouponCode;
  final int discountAmount;
  final String? couponError;
  final String holderName;
  final String? sourceBank;
  final bool isSubmitting;
  final String? error;

  bool get hasCoupon => appliedCouponCode != null;

  CheckoutState copyWith({
    String? fullName,
    String? phone,
    String? department,
    String? city,
    String? neighborhood,
    String? street1,
    String? street2,
    String? locationType,
    String? reference,
    String? googleMapsLink,
    String? couponCode,
    String? appliedCouponCode,
    int? discountAmount,
    String? couponError,
    String? holderName,
    String? sourceBank,
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
      neighborhood: neighborhood ?? this.neighborhood,
      street1: street1 ?? this.street1,
      street2: street2 ?? this.street2,
      locationType: locationType ?? this.locationType,
      reference: reference ?? this.reference,
      googleMapsLink: googleMapsLink ?? this.googleMapsLink,
      couponCode: couponCode ?? this.couponCode,
      appliedCouponCode:
          clearCoupon ? null : (appliedCouponCode ?? this.appliedCouponCode),
      discountAmount:
          clearCoupon ? 0 : (discountAmount ?? this.discountAmount),
      couponError:
          clearCouponError ? null : (couponError ?? this.couponError),
      holderName: holderName ?? this.holderName,
      sourceBank: sourceBank ?? this.sourceBank,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class CheckoutController extends StateNotifier<CheckoutState> {
  CheckoutController() : super(const CheckoutState());

  void setFullName(String v) => state = state.copyWith(fullName: v, clearError: true);
  void setPhone(String v) => state = state.copyWith(phone: v, clearError: true);
  void setDepartment(String? v) => state = state.copyWith(department: v, city: null, clearError: true);
  void setCity(String? v) => state = state.copyWith(city: v, clearError: true);
  
  void setNeighborhood(String v) => state = state.copyWith(neighborhood: v, clearError: true);
  void setStreet1(String v) => state = state.copyWith(street1: v, clearError: true);
  void setStreet2(String v) => state = state.copyWith(street2: v, clearError: true);
  void setLocationType(String v) => state = state.copyWith(locationType: v, clearError: true);
  void setReference(String v) => state = state.copyWith(reference: v, clearError: true);
  void setGoogleMapsLink(String v) => state = state.copyWith(googleMapsLink: v, clearError: true);

  void setHolderName(String v) => state = state.copyWith(holderName: v, clearError: true);
  void setSourceBank(String? v) => state = state.copyWith(sourceBank: v, clearError: true);
  void setCouponCode(String v) => state = state.copyWith(couponCode: v, clearCouponError: true);
  void setSubmitting(bool v) => state = state.copyWith(isSubmitting: v);
  void setError(String msg) => state = state.copyWith(error: msg, isSubmitting: false);

  void applyCoupon({required String code, required int discountAmount}) {
    state = state.copyWith(appliedCouponCode: code, discountAmount: discountAmount, clearCouponError: true);
  }

  void rejectCoupon(String message) {
    state = state.copyWith(couponError: message, appliedCouponCode: null, discountAmount: 0);
  }

  void removeCoupon() => state = state.copyWith(clearCoupon: true, couponCode: '', clearCouponError: true);
  void reset() => state = const CheckoutState();
}

final checkoutControllerProvider =
    StateNotifierProvider<CheckoutController, CheckoutState>((ref) {
  return CheckoutController();
});