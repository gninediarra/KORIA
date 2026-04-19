import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// ignore_for_file: avoid_dynamic_calls

// ─── User ────────────────────────────────────────────────────────────────────

enum UserRole {
  agriculteur,
  pecheur,
  autorite,
  citoyen;

  Color get color {
    switch (this) {
      case UserRole.agriculteur:
        return const Color(0xFFBC8A5F);
      case UserRole.pecheur:
        return const Color(0xFF1E88E5);
      case UserRole.autorite:
        return const Color(0xFF8E24AA);
      case UserRole.citoyen:
        return const Color(0xFF00D4FF);
    }
  }

  String get label {
    switch (this) {
      case UserRole.agriculteur:
        return 'Agriculteur';
      case UserRole.pecheur:
        return 'Pêcheur';
      case UserRole.autorite:
        return 'Autorité';
      case UserRole.citoyen:
        return 'Citoyen';
    }
  }

  String get description {
    switch (this) {
      case UserRole.agriculteur:
        return 'Gestion des terres agricoles et oasis';
      case UserRole.pecheur:
        return 'Pêche côtière dans le golfe de Gabès';
      case UserRole.autorite:
        return 'Surveillance réglementaire et alertes';
      case UserRole.citoyen:
        return 'Santé et qualité de vie';
    }
  }

  IconData get icon {
    switch (this) {
      case UserRole.agriculteur:
        return Icons.agriculture;
      case UserRole.pecheur:
        return Icons.set_meal;
      case UserRole.autorite:
        return Icons.account_balance;
      case UserRole.citoyen:
        return Icons.people;
    }
  }
}

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? quartier;
  final String? parcelle;
  final String? walletAddress;
  final int nadhafaPoints;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.quartier,
    this.parcelle,
    this.walletAddress,
    this.nadhafaPoints = 0,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        role: UserRole.values.firstWhere(
          (e) => e.name == json['role'],
          orElse: () => UserRole.citoyen,
        ),
        quartier: json['quartier'] as String?,
        parcelle: json['parcelle'] as String?,
        walletAddress: json['wallet_address'] as String?,
        nadhafaPoints: (json['nadhafa_points'] as num?)?.toInt() ?? 0,
      );
}

// ─── Zone ────────────────────────────────────────────────────────────────────

enum ZoneType { industriel, portuaire, agricole, cotier, urbain, maritime, oasis }

extension ZoneTypeExt on ZoneType {
  String get label {
    switch (this) {
      case ZoneType.industriel:
        return 'Zone Industrielle';
      case ZoneType.portuaire:
        return 'Zone Portuaire';
      case ZoneType.agricole:
        return 'Zone Agricole';
      case ZoneType.cotier:
        return 'Zone Côtière';
      case ZoneType.urbain:
        return 'Zone Urbaine';
      case ZoneType.maritime:
        return 'Zone Maritime';
      case ZoneType.oasis:
        return 'Oasis';
    }
  }
}

class SoilReadings {
  final double salinite;
  final double ph;
  final double humidite;
  final double contamination;
  final String etat;

  const SoilReadings({
    required this.salinite,
    required this.ph,
    required this.humidite,
    required this.contamination,
    required this.etat,
  });

  factory SoilReadings.fromJson(Map<String, dynamic> json) => SoilReadings(
        salinite: (json['salinite'] as num?)?.toDouble() ?? 0.0,
        ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
        humidite: (json['humidite'] as num?)?.toDouble() ?? 0.0,
        contamination: ((json['contamination'] as num?)?.toDouble() ?? 0.0) * 100,
        etat: json['etat'] as String? ?? '',
      );
}

class WaterReadings {
  final double turbidite;
  final double ph;
  final double phosphates;
  final double temperature;
  final String etat;

  const WaterReadings({
    required this.turbidite,
    required this.ph,
    required this.phosphates,
    required this.temperature,
    required this.etat,
  });

  factory WaterReadings.fromJson(Map<String, dynamic> json) => WaterReadings(
        turbidite: (json['turbidite'] as num?)?.toDouble() ?? 0.0,
        ph: (json['ph'] as num?)?.toDouble() ?? 7.0,
        phosphates: (json['phosphates'] as num?)?.toDouble() ?? 0.0,
        temperature: (json['temperature'] as num?)?.toDouble() ?? 20.0,
        etat: json['etat'] as String? ?? '',
      );
}

class AirReadings {
  final double so2;
  final double h2s;
  final double nh3;
  final double pm25;
  final int aqi;
  final String etat;

  const AirReadings({
    required this.so2,
    required this.h2s,
    required this.nh3,
    required this.pm25,
    required this.aqi,
    required this.etat,
  });

  factory AirReadings.fromJson(Map<String, dynamic> json) => AirReadings(
        so2: (json['so2'] as num?)?.toDouble() ?? 0.0,
        h2s: (json['h2s'] as num?)?.toDouble() ?? 0.0,
        nh3: (json['nh3'] as num?)?.toDouble() ?? 0.0,
        pm25: (json['pm25'] as num?)?.toDouble() ?? 0.0,
        aqi: (json['aqi'] as num?)?.toInt() ?? 0,
        etat: json['etat'] as String? ?? '',
      );
}

class Zone {
  final String id;
  final String name;
  final ZoneType type;
  final String status;
  final List<LatLng> polygon;
  final LatLng center;
  final SoilReadings soil;
  final WaterReadings water;
  final AirReadings air;
  final List<String> recommandations;
  final DateTime derniereAnalyse;

  const Zone({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.polygon,
    required this.center,
    required this.soil,
    required this.water,
    required this.air,
    required this.recommandations,
    required this.derniereAnalyse,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    final rawPolygon = json['polygon'] as List?;
    final polygon = rawPolygon
            ?.map((p) => LatLng(
                  (p['lat'] as num).toDouble(),
                  (p['lng'] as num).toDouble(),
                ))
            .toList() ??
        <LatLng>[];

    return Zone(
      id: json['id'] as String,
      name: json['name'] as String,
      type: ZoneType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ZoneType.urbain,
      ),
      status: json['status'] as String? ?? 'vert',
      center: LatLng(
        (json['center_lat'] as num).toDouble(),
        (json['center_lng'] as num).toDouble(),
      ),
      polygon: polygon,
      soil: SoilReadings.fromJson(
          json['sol'] as Map<String, dynamic>? ?? {}),
      water: WaterReadings.fromJson(
          json['water'] as Map<String, dynamic>? ?? {}),
      air: AirReadings.fromJson(
          json['air'] as Map<String, dynamic>? ?? {}),
      recommandations:
          (json['recommandations'] as List?)?.cast<String>() ?? [],
      derniereAnalyse:
          DateTime.tryParse(json['derniere_analyse'] as String? ?? '') ??
              DateTime.now(),
    );
  }

  /// Construit une Zone depuis le backend Mané (/zones + analyses séparées).
  factory Zone.fromBackend(
    Map<String, dynamic> z, {
    Map<String, dynamic>? sol,
    Map<String, dynamic>? eau,
    Map<String, dynamic>? air,
  }) {
    // Centre : {lat, lon} ou center_lat/center_lng
    LatLng center;
    if (z['center'] is Map) {
      final c = z['center'] as Map;
      center = LatLng((c['lat'] as num).toDouble(), (c['lon'] as num).toDouble());
    } else {
      center = LatLng(
        (z['center_lat'] as num? ?? 33.88).toDouble(),
        (z['center_lng'] as num? ?? 10.0).toDouble(),
      );
    }

    // Polygone depuis bbox [lon_min, lat_min, lon_max, lat_max]
    List<LatLng> polygon = [];
    if (z['bbox'] is List) {
      final b = z['bbox'] as List;
      final lonMin = (b[0] as num).toDouble();
      final latMin = (b[1] as num).toDouble();
      final lonMax = (b[2] as num).toDouble();
      final latMax = (b[3] as num).toDouble();
      polygon = [
        LatLng(latMin, lonMin),
        LatLng(latMax, lonMin),
        LatLng(latMax, lonMax),
        LatLng(latMin, lonMax),
      ];
    }

    // Status depuis sol ou air
    String status = 'vert';
    if (sol != null) status = sol['status'] as String? ?? 'vert';
    if (air != null) {
      final airStatus = air['global_alert_level'] as String? ?? 'vert';
      // Escalate si l'air est plus grave
      if (airStatus == 'rouge' || (airStatus == 'orange' && status == 'vert')) {
        status = airStatus;
      }
    }

    // SoilReadings
    final soilReadings = sol != null
        ? SoilReadings(
            salinite: (sol['indices']?['NDSI'] as num? ?? 0).toDouble() * 10,
            ph: 7.0,
            humidite: (sol['indices']?['NDWI'] as num? ?? 0).toDouble().abs() * 100,
            contamination: (sol['contamination_pct'] as num? ?? 0).toDouble(),
            etat: _solEtat(sol['status'] as String? ?? 'vert', sol['health_score']),
          )
        : const SoilReadings(salinite: 0, ph: 7, humidite: 0, contamination: 0, etat: '—');

    // WaterReadings
    final waterReadings = eau != null
        ? WaterReadings(
            turbidite: (eau['turbidite'] as num? ?? 0).toDouble(),
            ph: 7.0,
            phosphates: (eau['indices']?['NDCI'] as num? ?? 0).toDouble().abs() * 10,
            temperature: 25.0,
            etat: _eauEtat(eau['status'] as String? ?? 'vert', eau['turbidite']),
          )
        : const WaterReadings(turbidite: 0, ph: 7, phosphates: 0, temperature: 25, etat: '—');

    // AirReadings
    AirReadings airReadings;
    List<String> recommandations = [];
    DateTime derniereAnalyse = DateTime.now();
    if (air != null) {
      final aq = air['air_quality'] as Map<String, dynamic>? ?? {};
      airReadings = AirReadings(
        so2: (aq['so2'] as num? ?? 0).toDouble(),
        h2s: 0,
        nh3: 0,
        pm25: (aq['pm25'] as num? ?? 0).toDouble(),
        aqi: (aq['aqi'] as num? ?? 0).toInt(),
        etat: aq['alert_level'] as String? ?? '—',
      );
      final rawRec = air['recommendations'] as List? ?? [];
      recommandations = rawRec
          .map((r) => (r['message'] ?? r.toString()).toString())
          .toList();
      derniereAnalyse =
          DateTime.tryParse(air['timestamp'] as String? ?? '') ?? DateTime.now();
    } else {
      airReadings = const AirReadings(so2: 0, h2s: 0, nh3: 0, pm25: 0, aqi: 0, etat: '—');
    }

    return Zone(
      id: z['id'] as String,
      name: z['name'] as String,
      type: ZoneType.values.firstWhere(
        (e) => e.name == (z['type'] as String? ?? ''),
        orElse: () {
          final t = z['type'] as String? ?? '';
          if (t == 'ville') return ZoneType.urbain;
          if (t == 'mer') return ZoneType.maritime;
          return ZoneType.urbain;
        },
      ),
      status: status,
      center: center,
      polygon: polygon,
      soil: soilReadings,
      water: waterReadings,
      air: airReadings,
      recommandations: recommandations,
      derniereAnalyse: derniereAnalyse,
    );
  }

  static String _solEtat(String status, dynamic score) {
    if (status == 'rouge') return 'Contamination critique';
    if (status == 'orange') return 'Dégradation modérée';
    return 'Sol en bon état';
  }

  static String _eauEtat(String status, dynamic turbidite) {
    if (status == 'rouge') return 'Eau très polluée';
    if (status == 'orange') return 'Turbidité élevée';
    return 'Qualité acceptable';
  }
}

// ─── Alert ───────────────────────────────────────────────────────────────────

enum AlertSeverity { critique, avertissement, info }

extension AlertSeverityExt on AlertSeverity {
  String get label {
    switch (this) {
      case AlertSeverity.critique:
        return 'Critique';
      case AlertSeverity.avertissement:
        return 'Avertissement';
      case AlertSeverity.info:
        return 'Info';
    }
  }

  Color get color {
    switch (this) {
      case AlertSeverity.critique:
        return const Color(0xFFFF3D57);
      case AlertSeverity.avertissement:
        return const Color(0xFFFFAB00);
      case AlertSeverity.info:
        return const Color(0xFF00D4FF);
    }
  }

  IconData get icon {
    switch (this) {
      case AlertSeverity.critique:
        return Icons.warning_rounded;
      case AlertSeverity.avertissement:
        return Icons.info_outline_rounded;
      case AlertSeverity.info:
        return Icons.notifications_outlined;
    }
  }
}

class DroneAlert {
  final String id;
  final String titre;
  final String description;
  final AlertSeverity severite;
  final List<UserRole> rolesTarget;
  final String zone;
  final DateTime timestamp;
  final List<String> recommandations;
  final bool lue;

  const DroneAlert({
    required this.id,
    required this.titre,
    required this.description,
    required this.severite,
    required this.rolesTarget,
    required this.zone,
    required this.timestamp,
    required this.recommandations,
    this.lue = false,
  });

  factory DroneAlert.fromJson(Map<String, dynamic> json) => DroneAlert(
        id: json['id'] as String,
        titre: json['titre'] as String,
        description: json['description'] as String,
        severite: AlertSeverity.values.firstWhere(
          (e) => e.name == json['severite'],
          orElse: () => AlertSeverity.info,
        ),
        rolesTarget: (json['roles_target'] as List)
            .map((r) => UserRole.values.firstWhere(
                  (e) => e.name == r,
                  orElse: () => UserRole.citoyen,
                ))
            .toList(),
        zone: json['zone_name'] as String,
        timestamp:
            DateTime.tryParse(json['timestamp'] as String? ?? '') ??
                DateTime.now(),
        recommandations:
            (json['recommandations'] as List?)?.cast<String>() ?? [],
        lue: false,
      );

  DroneAlert copyWith({bool? lue}) => DroneAlert(
        id: id,
        titre: titre,
        description: description,
        severite: severite,
        rolesTarget: rolesTarget,
        zone: zone,
        timestamp: timestamp,
        recommandations: recommandations,
        lue: lue ?? this.lue,
      );
}

// ─── Drone ───────────────────────────────────────────────────────────────────

enum DroneStatus { enVol, pause, maintenance, deconnecte }

extension DroneStatusExt on DroneStatus {
  String get label {
    switch (this) {
      case DroneStatus.enVol:
        return 'En Vol';
      case DroneStatus.pause:
        return 'En Pause';
      case DroneStatus.maintenance:
        return 'Maintenance';
      case DroneStatus.deconnecte:
        return 'Déconnecté';
    }
  }

  Color get color {
    switch (this) {
      case DroneStatus.enVol:
        return const Color(0xFF00E676);
      case DroneStatus.pause:
        return const Color(0xFFFFAB00);
      case DroneStatus.maintenance:
        return const Color(0xFF1E88E5);
      case DroneStatus.deconnecte:
        return const Color(0xFFFF3D57);
    }
  }
}

class DroneTelemetry {
  final double batterie;
  final double altitude;
  final double vitesse;
  final double signalForce;
  final LatLng position;
  final DroneStatus status;
  final double temperature;
  final String missionActuelle;
  final double missionProgress;
  final bool multispectralActif;
  final bool thermiqueActif;
  final bool atmospheriqueActif;
  final double vent;
  final double distanceParcourue;

  const DroneTelemetry({
    required this.batterie,
    required this.altitude,
    required this.vitesse,
    required this.signalForce,
    required this.position,
    required this.status,
    required this.temperature,
    required this.missionActuelle,
    required this.missionProgress,
    required this.multispectralActif,
    required this.thermiqueActif,
    required this.atmospheriqueActif,
    required this.vent,
    required this.distanceParcourue,
  });

  DroneTelemetry copyWith({
    double? batterie,
    double? altitude,
    double? vitesse,
    double? signalForce,
    LatLng? position,
    DroneStatus? status,
    double? temperature,
    String? missionActuelle,
    double? missionProgress,
    double? vent,
    double? distanceParcourue,
  }) {
    return DroneTelemetry(
      batterie: batterie ?? this.batterie,
      altitude: altitude ?? this.altitude,
      vitesse: vitesse ?? this.vitesse,
      signalForce: signalForce ?? this.signalForce,
      position: position ?? this.position,
      status: status ?? this.status,
      temperature: temperature ?? this.temperature,
      missionActuelle: missionActuelle ?? this.missionActuelle,
      missionProgress: missionProgress ?? this.missionProgress,
      multispectralActif: multispectralActif,
      thermiqueActif: thermiqueActif,
      atmospheriqueActif: atmospheriqueActif,
      vent: vent ?? this.vent,
      distanceParcourue: distanceParcourue ?? this.distanceParcourue,
    );
  }
}

// ─── Analysis models (Mané backend) ─────────────────────────────────────────

class SolAnalysis {
  final String zoneId;
  final double healthScore;
  final double contaminationPct;
  final double anomalyPct;
  final String status;
  final Map<String, double> indices;
  final DateTime timestamp;

  const SolAnalysis({
    required this.zoneId,
    required this.healthScore,
    required this.contaminationPct,
    required this.anomalyPct,
    required this.status,
    required this.indices,
    required this.timestamp,
  });

  factory SolAnalysis.fromJson(Map<String, dynamic> j) => SolAnalysis(
        zoneId: j['zone_id'] as String? ?? '',
        healthScore: (j['health_score'] as num? ?? 0).toDouble(),
        contaminationPct: (j['contamination_pct'] as num? ?? 0).toDouble(),
        anomalyPct: (j['anomaly_pct'] as num? ?? 0).toDouble(),
        status: j['status'] as String? ?? 'vert',
        indices: {
          for (final e in (j['indices'] as Map<String, dynamic>? ?? {}).entries)
            e.key: (e.value as num? ?? 0).toDouble()
        },
        timestamp:
            DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class EauAnalysis {
  final String zoneId;
  final double turbidite;
  final double contaminationPct;
  final String status;
  final Map<String, double> indices;
  final DateTime timestamp;

  const EauAnalysis({
    required this.zoneId,
    required this.turbidite,
    required this.contaminationPct,
    required this.status,
    required this.indices,
    required this.timestamp,
  });

  factory EauAnalysis.fromJson(Map<String, dynamic> j) => EauAnalysis(
        zoneId: j['zone_id'] as String? ?? '',
        turbidite: (j['turbidite'] as num? ?? 0).toDouble(),
        contaminationPct: (j['contamination_pct'] as num? ?? 0).toDouble(),
        status: j['status'] as String? ?? 'vert',
        indices: {
          for (final e in (j['indices'] as Map<String, dynamic>? ?? {}).entries)
            e.key: (e.value as num? ?? 0).toDouble()
        },
        timestamp:
            DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
      );
}

class AirAnalysis {
  final String zoneId;
  final int aqi;
  final String alertLevel;
  final String globalAlertLevel;
  final double so2;
  final double pm25;
  final double pm10;
  final double temperature;
  final double windSpeed;
  final bool isCritical;
  final List<Map<String, dynamic>> recommendations;
  final DateTime timestamp;

  const AirAnalysis({
    required this.zoneId,
    required this.aqi,
    required this.alertLevel,
    required this.globalAlertLevel,
    required this.so2,
    required this.pm25,
    required this.pm10,
    required this.temperature,
    required this.windSpeed,
    required this.isCritical,
    required this.recommendations,
    required this.timestamp,
  });

  factory AirAnalysis.fromJson(Map<String, dynamic> j) {
    final aq = j['air_quality'] as Map<String, dynamic>? ?? {};
    final meteo = j['meteo'] as Map<String, dynamic>? ?? {};
    final ep = j['episode_prediction'] as Map<String, dynamic>? ?? {};
    return AirAnalysis(
      zoneId: j['zone_id'] as String? ?? '',
      aqi: (aq['aqi'] as num? ?? 0).toInt(),
      alertLevel: aq['alert_level'] as String? ?? '—',
      globalAlertLevel: j['global_alert_level'] as String? ?? 'vert',
      so2: (aq['so2'] as num? ?? 0).toDouble(),
      pm25: (aq['pm25'] as num? ?? 0).toDouble(),
      pm10: (aq['pm10'] as num? ?? 0).toDouble(),
      temperature: (meteo['temperature'] as num? ?? 20).toDouble(),
      windSpeed: (meteo['wind_speed'] as num? ?? 0).toDouble(),
      isCritical: ep['is_critical'] as bool? ?? false,
      recommendations: (j['recommendations'] as List? ?? [])
          .cast<Map<String, dynamic>>(),
      timestamp:
          DateTime.tryParse(j['timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class PredictionPoint {
  final String date;
  final double value;
  final double? lower;
  final double? upper;

  const PredictionPoint({
    required this.date,
    required this.value,
    this.lower,
    this.upper,
  });

  factory PredictionPoint.fromJson(Map<String, dynamic> j) => PredictionPoint(
        date: j['date'] as String? ?? j['month'] as String? ?? '',
        value: (j['value'] as num? ?? j['contamination_pct'] as num? ?? 0).toDouble(),
        lower: (j['lower'] as num?)?.toDouble(),
        upper: (j['upper'] as num?)?.toDouble(),
      );
}
