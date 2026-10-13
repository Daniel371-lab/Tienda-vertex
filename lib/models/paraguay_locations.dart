/// Departamentos y localidades habilitadas para envío.
class ParaguayLocations {
  const ParaguayLocations._();

  static const Map<String, List<String>> data = {
    'Alto Paraná': [
      'Cedrales',
      'Ciudad del Este',
      'Hernandarias',
      'Juan León Mallorquín',
      'Minga Guazú',
      'Presidente Franco',
      'San Alberto',
      'San Cristóbal',
      'Santa Rita',
      'Santa Rosa del Monday',
    ],
    'Amambay': [
      'Pedro Juan Caballero',
    ],
    'Asunción': [
      'Asunción',
    ],
    'Caaguazú': [
      'Caaguazú',
      'Carayaó',
      'Coronel Oviedo',
      'Doctor Juan Manuel Frutos',
    ],
    'Caazapá': [
      'Caazapá',
      'Doctor Moisés Bertoni',
      'General Higinio Morínigo',
      'Maciel',
      'San Juan Nepomuceno',
    ],
    'Canindeyú': [
      'Corpus Christi',
      'Curuguaty',
      'Katueté',
      'La Paloma',
      'Nueva Esperanza',
      'Salto del Guairá',
      'Yasy Cañy',
    ],
    'Central': [
      'Areguá',
      'Capiatá',
      'Fernando de la Mora',
      'Guarambaré',
      'Itá',
      'Itauguá',
      'J. Augusto Saldívar',
      'Lambaré',
      'Limpio',
      'Luque',
      'Mariano Roque Alonso',
      'Ñemby',
      'Nueva Italia',
      'San Antonio',
      'San Lorenzo',
      'Villa Elisa',
      'Villeta',
      'Ypacaraí',
      'Ypané',
    ],
    'Concepción': [
      'Concepción',
      'Horqueta',
    ],
    'Cordillera': [
      'Altos',
      'Arroyos y Esteros',
      'Atyrá',
      'Caacupé',
      'Caraguatay',
      'Eusebio Ayala',
      'Piribebuy',
      'San Bernardino',
      'Tobatí',
      'Valenzuela',
    ],
    'Guairá': [
      'Borja',
      'Mauricio José Troche',
      'Villarrica',
    ],
    'Itapúa': [
      'Bella Vista',
      'Cambyretá',
      'Carmen del Paraná',
      'Colonia Carlos Antonio López',
      'Coronel Bogado',
      'Encarnación',
      'Fram',
      'Hohenau',
      'Jesús',
      'José Leandro Oviedo',
      'Mayor Otaño',
      'Natalio',
      'Obligado',
      'Tomás Romero Pereira',
      'Trinidad',
    ],
    'Misiones': [
      'Ayolas',
      'San Ignacio',
      'San Juan Bautista',
      'Santa María',
      'Santa Rosa',
    ],
    'Ñeembucú': [
      'Pilar',
      'Villa Oliva',
    ],
    'Paraguarí': [
      'Carapeguá',
      'Escobar',
      'Paraguarí',
      'Pirayú',
      'Quiindy',
      'Yaguarón',
    ],
    'Presidente Hayes': [
      'Villa Hayes',
    ],
  };

  /// Ciudades que tienen Punto de Venta AEX habilitado.
  static const Set<String> citiesWithPickup = {
    'Asunción',
    'Guarambaré',
    'Lambaré',
    'Mariano Roque Alonso',
    'Villeta',
    'Ciudad del Este',
    'Hernandarias',
    'Minga Guazú',
    'Pedro Juan Caballero',
    'Caaguazú',
    'Coronel Oviedo',
    'Doctor Juan Manuel Frutos',
    'Salto del Guairá',
    'Concepción',
    'Caacupé',
    'Mauricio José Troche',
    'Encarnación',
    'Pilar',
  };

  // ── CONFIGURACIÓN DE ENVÍOS ─────────────────────────────

  /// Envío gratis a partir de este monto.
  static const int freeShippingThreshold = 500000;

  /// Mínimo de compra para envíos fuera de Asunción y Central.
  static const int minimumOrderForInterior = 300000;

  // ── MÉTODOS ──────────────────────────────────────────────

  static List<String> get departments => data.keys.toList()..sort();

  static List<String> citiesOf(String? department) {
    if (department == null) return const [];
    return data[department] ?? const [];
  }

  /// ¿La ciudad tiene punto de venta AEX?
  static bool hasPickup(String city) => citiesWithPickup.contains(city);

  /// ¿Es Asunción o Central?
  static bool _isGranAsuncion(String? department) {
    if (department == null) return false;
    return department == 'Asunción' || department == 'Central';
  }

  /// Costo de envío según zona (antes de aplicar envío gratis).
  static int shippingCostFor(String? department) {
    if (department == null) return 0;

    if (_isGranAsuncion(department)) return 20000;

    if (department == 'Cordillera' || department == 'Paraguarí') {
      return 30000;
    }

    return 35000;
  }

  /// Mínimo de compra. 0 = sin mínimo.
  static int minimumOrderFor(String? department) {
    if (department == null) return 0;
    if (_isGranAsuncion(department)) return 0;
    return minimumOrderForInterior;
  }

  /// Calcula el envío final aplicando el umbral de gratis.
  static int calculateShipping({
    required String? department,
    required int subtotal,
  }) {
    if (department == null) return 0;
    if (subtotal >= freeShippingThreshold) return 0;
    return shippingCostFor(department);
  }

  /// ¿El subtotal cumple con el mínimo de compra?
  static bool meetsMinimum({
    required String? department,
    required int subtotal,
  }) {
    if (department == null) return true;
    final min = minimumOrderFor(department);
    if (min == 0) return true;
    return subtotal >= min;
  }
}