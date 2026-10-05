import 'dart:convert';
import 'package:flutter/services.dart';

class MembershipPlan {
  const MembershipPlan(
      {required this.id,
      required this.name,
      required this.tagline,
      required this.monthlyPrice,
      required this.annualPrice,
      required this.available,
      required this.features});
  final String id, name, tagline;
  final int monthlyPrice;
  final int? annualPrice;
  final bool available;
  final List<String> features;
  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      monthlyPrice: json['monthlyPrice'] as int,
      annualPrice: json['annualPrice'] as int?,
      available: json['available'] as bool,
      features: List<String>.from(json['features'] as List));
}

class MembershipCatalog {
  const MembershipCatalog(this.plans, this.creatorNote);
  final List<MembershipPlan> plans;
  final String creatorNote;
  static Future<MembershipCatalog> load() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/membership-plans.json'))
            as Map<String, dynamic>;
    return MembershipCatalog(
        (json['plans'] as List)
            .map((p) => MembershipPlan.fromJson(p as Map<String, dynamic>))
            .toList(),
        json['creatorNote'] as String);
  }
}
