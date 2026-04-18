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
  final int ecoTokens;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.quartier,
    this.parcelle,
    this.walletAddress,
    this.ecoTokens = 0,
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
        ecoTokens: (json['eco_tokens'] as num?)?.toInt() ?? 0,
      );
}

// ─── Zone ────────────────────────────────────────────────────────────────────

enum ZoneType { industriel, portuaire, agricole, cotier, urbain, maritime }

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
