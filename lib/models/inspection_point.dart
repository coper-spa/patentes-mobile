import 'inspection_visit.dart';

class InspectionPoint {
  const InspectionPoint({
    required this.id,
    required this.patentArrearId,
    required this.visitableType,
    required this.visitableId,
    required this.contribuyenteId,
    required this.patentId,
    required this.sequence,
    required this.businessName,
    required this.address,
    required this.visitReasonLabel,
    required this.inspectionType,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.visitHistory,
  });

  final String id;
  final String patentArrearId;
  final String visitableType;
  final String visitableId;
  final String contribuyenteId;
  final String patentId;
  final int sequence;
  final String businessName;
  final String address;
  final String visitReasonLabel;
  final String inspectionType;
  final String status;
  final double latitude;
  final double longitude;
  final List<InspectionVisit> visitHistory;

  factory InspectionPoint.fromJson(Map<String, dynamic> json) {
    final source = _unwrapDataObject(json);

    final historyRaw = source['visit_history'] ?? source['management_logs'];
    final history = _asMapList(historyRaw)
      .map(InspectionVisit.fromJson)
      .toList(growable: false);

    final patentArrear = source['patent_arrear'] is Map<String, dynamic>
        ? source['patent_arrear'] as Map<String, dynamic>
        : <String, dynamic>{};
    final patent = patentArrear['patent'] is Map<String, dynamic>
        ? patentArrear['patent'] as Map<String, dynamic>
        : <String, dynamic>{};
    final geolocation = source['geolocation'] is Map<String, dynamic>
        ? source['geolocation'] as Map<String, dynamic>
        : <String, dynamic>{};
    final patentGeolocation = patent['geolocation'] is Map<String, dynamic>
        ? patent['geolocation'] as Map<String, dynamic>
        : <String, dynamic>{};
    final patentLocation = patent['location'] is Map<String, dynamic>
        ? patent['location'] as Map<String, dynamic>
        : <String, dynamic>{};
    final contribuyente = source['contribuyente'] is Map<String, dynamic>
        ? source['contribuyente'] as Map<String, dynamic>
        : <String, dynamic>{};
    final visitable = source['visitable'] is Map<String, dynamic>
        ? source['visitable'] as Map<String, dynamic>
        : <String, dynamic>{};

    final coordinates = _extractCoordinates(
      source: source,
      geolocation: geolocation,
      patent: patent,
      patentGeolocation: patentGeolocation,
      patentLocation: patentLocation,
      patentArrear: patentArrear,
      contribuyente: contribuyente,
      visitable: visitable,
    );

    return InspectionPoint(
      id: source['id'].toString(),
      patentArrearId:
          (source['patent_arrear_id'] ?? patentArrear['id'] ?? '').toString(),
      visitableType: (source['visitable_type'] ?? '').toString(),
      visitableId: (source['visitable_id'] ?? '').toString(),
      contribuyenteId: _toText(
        source['contribuyente_id'] ??
            contribuyente['id'] ??
            ((source['visitable_type'] ?? '').toString().contains('Contribuyente')
                ? source['visitable_id']
                : null),
      ),
      patentId: _toText(
        source['patent_id'] ??
            patent['id'] ??
            ((source['visitable_type'] ?? '').toString().contains('Patent')
                ? source['visitable_id']
                : null),
      ),
      sequence: _toInt(source['sequence']) ?? _toInt(source['stop_order']) ?? 0,
      businessName: _toText(
        source['business_name'] ??
            source['patent_name'] ??
            source['name'] ??
            source['contribuyente_name'] ??
            patentArrear['patent_name'] ??
            patentArrear['debtor_name'] ??
            patent['business_name'] ??
            patent['name'] ??
            contribuyente['name'] ??
            visitable['name'],
      ),
      address: _toText(
        source['address'] ??
            source['visit_address_snapshot'] ??
            patentArrear['address'] ??
            patent['address'] ??
            contribuyente['address'] ??
            visitable['address'],
      ),
      visitReasonLabel: _toText(
        source['visit_reason_label'],
      ),
      inspectionType: _toText(
        source['inspection_type'] ??
            patentArrear['patent_type'] ??
            patent['patent_type'] ??
            patent['type_name'] ??
            patent['type'] ??
            source['visit_scope'] ??
            source['visit_source'],
      ),
      status: (source['status'] ??
            source['assignment_status'] ??
          patentArrear['current_status'] ??
          '') as String,
      latitude: coordinates.$1,
      longitude: coordinates.$2,
      visitHistory: history,
    );
  }

  static (double, double) _extractCoordinates({
    required Map<String, dynamic> source,
    required Map<String, dynamic> geolocation,
    required Map<String, dynamic> patent,
    required Map<String, dynamic> patentGeolocation,
    required Map<String, dynamic> patentLocation,
    required Map<String, dynamic> patentArrear,
    required Map<String, dynamic> contribuyente,
    required Map<String, dynamic> visitable,
  }) {
    final lat =
            _toDouble(source['visit_latitude']) ??
        _toDouble(source['latitude']) ??
        _toDouble(source['lat']) ??
        _toDouble(geolocation['lat']) ??
        _toDouble(geolocation['latitude']) ??
        _extractLatFromCoordinates(geolocation['coordinates']) ??
        _toDouble(contribuyente['latitude']) ??
        _toDouble(contribuyente['lat']) ??
        _toDouble(visitable['latitude']) ??
        _toDouble(visitable['lat']) ??
        _toDouble(patent['latitude']) ??
        _toDouble(patent['lat']) ??
        _toDouble(patentGeolocation['lat']) ??
        _toDouble(patentGeolocation['latitude']) ??
        _extractLatFromCoordinates(patentGeolocation['coordinates']) ??
        _toDouble(patentLocation['lat']) ??
        _toDouble(patentLocation['latitude']) ??
        _extractLatFromCoordinates(patentLocation['coordinates']) ??
        _toDouble(patentArrear['latitude']) ??
        0;

    final lng =
          _toDouble(source['visit_longitude']) ??
        _toDouble(source['longitude']) ??
        _toDouble(source['lng']) ??
        _toDouble(source['lon']) ??
        _toDouble(geolocation['lng']) ??
        _toDouble(geolocation['longitude']) ??
        _toDouble(geolocation['lon']) ??
        _extractLngFromCoordinates(geolocation['coordinates']) ??
        _toDouble(contribuyente['longitude']) ??
        _toDouble(contribuyente['lng']) ??
        _toDouble(contribuyente['lon']) ??
        _toDouble(visitable['longitude']) ??
        _toDouble(visitable['lng']) ??
        _toDouble(visitable['lon']) ??
        _toDouble(patent['longitude']) ??
        _toDouble(patent['lng']) ??
        _toDouble(patent['lon']) ??
        _toDouble(patentGeolocation['lng']) ??
        _toDouble(patentGeolocation['longitude']) ??
        _extractLngFromCoordinates(patentGeolocation['coordinates']) ??
        _toDouble(patentLocation['lng']) ??
        _toDouble(patentLocation['longitude']) ??
        _extractLngFromCoordinates(patentLocation['coordinates']) ??
        _toDouble(patentArrear['longitude']) ??
        0;

    return (lat, lng);
  }

  static double? _extractLatFromCoordinates(Object? value) {
    if (value is List<dynamic> && value.length >= 2) {
      return _toDouble(value[1]);
    }

    return null;
  }

  static double? _extractLngFromCoordinates(Object? value) {
    if (value is List<dynamic> && value.isNotEmpty) {
      return _toDouble(value[0]);
    }

    return null;
  }

  static String _toText(Object? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  static Map<String, dynamic> _unwrapDataObject(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    return json;
  }

  static List<Map<String, dynamic>> _asMapList(Object? value) {
    if (value is List<dynamic>) {
      return value.whereType<Map<String, dynamic>>().toList(growable: false);
    }

    if (value is Map<String, dynamic>) {
      final nested = value['data'];
      if (nested is List<dynamic>) {
        return nested
            .whereType<Map<String, dynamic>>()
            .toList(growable: false);
      }
    }

    return <Map<String, dynamic>>[];
  }

  static int? _toInt(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString());
  }

  static double? _toDouble(Object? value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is num) {
      return value.toDouble();
    }

    final asText = value.toString().trim();
    if (asText.isEmpty) {
      return null;
    }

    final normalized = asText.replaceAll(',', '.');
    return double.tryParse(normalized);
  }
}
