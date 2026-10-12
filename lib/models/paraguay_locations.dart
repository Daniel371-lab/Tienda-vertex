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
      'Hohenau',
      'Jesús',
      'José Leandro Oviedo',
      'Mayor Otaño',
      'Natalio',
      'Obligado',
    ],
    'Misiones': [
      'Ayolas',
      'San Ignacio',
      'San Juan Bautista',
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
      'Quiindy',
      'Yaguarón',
    ],
    'Presidente Hayes': [
      'Villa Hayes',
    ],
  };

  /// Ciudades que tienen Punto de Venta AEX habilitado.
  static const Set<String> citiesWithPickup = {
    // Asunción
    'Asunción',
    // Central
    'Guarambaré',
    'Lambaré',
    'Mariano Roque Alonso',
    'Villeta',
    // Alto Paraná
    'Ciudad del Este',
    'Hernandarias',
    'Minga Guazú',
    // Amambay
    'Pedro Juan Caballero',
    // Caaguazú
    'Caaguazú',
    'Coronel Oviedo',
    'Doctor Juan Manuel Frutos',
    // Canindeyú
    'Salto del Guairá',
    // Concepción
    'Concepción',
    // Cordillera
    'Caacupé',
    // Guairá
    'Mauricio José Troche',
    // Itapúa
    'Encarnación',
    // Ñeembucú
    'Pilar',
  };

  static List<String> get departments => data.keys.toList()..sort();

  static List<String> citiesOf(String? department) {
    if (department == null) return const [];
    return data[department] ?? const [];
  }

  /// ¿La ciudad tiene punto de venta AEX?
  static bool hasPickup(String city) => citiesWithPickup.contains(city);
}