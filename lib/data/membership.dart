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
      required this.features,
      this.status,
      this.badge,
      this.quarterlyPrice,
      this.chargeMonthly,
      this.chargeAnnual,
      this.detailMonthly,
      this.detailAnnual,
      this.renewMonthly,
      this.renewAnnual});
  final String id, name, tagline;
  final int monthlyPrice;
  final int? annualPrice;
  final bool available;
  final List<String> features;
  // Optional copy shared with the website's membership section.
  final String? status, badge, chargeMonthly, chargeAnnual;
  final String? detailMonthly, detailAnnual, renewMonthly, renewAnnual;
  final int? quarterlyPrice;
  factory MembershipPlan.fromJson(Map<String, dynamic> json) => MembershipPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String,
      monthlyPrice: json['monthlyPrice'] as int,
      annualPrice: json['annualPrice'] as int?,
      available: json['available'] as bool,
      features: List<String>.from(json['features'] as List),
      status: json['status'] as String?,
      badge: json['badge'] as String?,
      quarterlyPrice: json['quarterlyPrice'] as int?,
      chargeMonthly: json['chargeMonthly'] as String?,
      chargeAnnual: json['chargeAnnual'] as String?,
      detailMonthly: (json['detailMonthly'] ?? json['detail']) as String?,
      detailAnnual: (json['detailAnnual'] ?? json['detailMonthly'] ?? json['detail']) as String?,
      renewMonthly: json['renewMonthly'] as String?,
      renewAnnual: (json['renewAnnual'] ?? json['renewMonthly']) as String?);
}

class MembershipCatalog {
  const MembershipCatalog(this.plans, this.creatorNote, [this.billingNote]);
  final List<MembershipPlan> plans;
  final String creatorNote;
  final String? billingNote;
  static Future<MembershipCatalog> load() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/membership-plans.json'))
            as Map<String, dynamic>;
    return MembershipCatalog(
        (json['plans'] as List)
            .map((p) => MembershipPlan.fromJson(p as Map<String, dynamic>))
            .toList(),
        json['creatorNote'] as String,
        json['billingNote'] as String?);
  }
}
