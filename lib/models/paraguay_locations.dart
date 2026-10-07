/// Departamentos y ciudades de Paraguay para el checkout.
/// Cada departamento trae su lista de ciudades/distritos principales.
class ParaguayLocations {
  const ParaguayLocations._();

  static const Map<String, List<String>> data = {
    'Asunción': [
      'Asunción',
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
    'Alto Paraná': [
      'Ciudad del Este',
      'Hernandarias',
      'Minga Guazú',
      'Presidente Franco',
      'Santa Rita',
      'Doctor Juan León Mallorquín',
      'Naranjal',
    ],
    'Itapúa': [
      'Encarnación',
      'Cambyretá',
      'Capitán Miranda',
      'Hohenau',
      'Obligado',
      'Trinidad',
      'Bella Vista',
      'General Delgado',
    ],
    'Caaguazú': [
      'Coronel Oviedo',
      'Caaguazú',
      'Doctor Juan Manuel Frutos',
      'Repatriación',
      'Santa Rosa del Mbutuy',
    ],
    'Amambay': [
      'Pedro Juan Caballero',
      'Bella Vista',
      'Capitán Bado',
      'Karapaí',
    ],
    'Canindeyú': [
      'Salto del Guairá',
      'Curuguaty',
      'Villa Ygatimí',
      'La Paloma',
    ],
    'Concepción': [
      'Concepción',
      'Horqueta',
      'Yby Yaú',
      'Loreto',
      'San Carlos',
    ],
    'San Pedro': [
      'San Pedro del Ycuamandiyú',
      'Santa Rosa del Aguaray',
      'Choré',
      'Lima',
      'Nueva Germania',
    ],
    'Cordillera': [
      'Caacupé',
      'San Bernardino',
      'Atyrá',
      'Tobatí',
      'Paraguarí',
      'Piribebuy',
    ],
    'Paraguarí': [
      'Paraguarí',
      'Carapeguá',
      'Yaguarón',
      'Quiindy',
      'Acahay',
    ],
    'Misiones': [
      'San Juan Bautista',
      'Ayolas',
      'Santa Rosa',
      'Santiago',
      'San Ignacio',
    ],
    'Guairá': [
      'Villarrica',
      'Coronel Oviedo',
      'Mauricio José Troche',
      'Independencia',
    ],
    'Caazapá': [
      'Caazapá',
      'San Juan Nepomuceno',
      'Abaí',
      'Yuty',
    ],
    'Ñeembucú': [
      'Pilar',
      'Alberdi',
      'Villa Oliva',
      'Laureles',
    ],
    'Presidente Hayes': [
      'Villa Hayes',
      'Benjamín Aceval',
      'Nanawa',
      'Puerto Pinasco',
    ],
    'Boquerón': [
      'Filadelfia',
      'Loma Plata',
      'Mariscal Estigarribia',
    ],
    'Alto Paraguay': [
      'Fuerte Olimpo',
      'Puerto Casado',
      'Bahía Negra',
    ],
  };

  /// Lista de departamentos ordenada alfabéticamente.
  static List<String> get departments =>
      data.keys.toList()..sort();

  /// Ciudades de un departamento (o lista vacía si no existe).
  static List<String> citiesOf(String? department) {
    if (department == null) return const [];
    return data[department] ?? const [];
  }
}