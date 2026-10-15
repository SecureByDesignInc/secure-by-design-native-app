import 'dart:convert';
import 'package:flutter/services.dart';

/// Membership copy. `assets/membership-plans.json` is an identical copy of the
/// website's `content/membership-plans.json`; update both together.
///
/// Owner request, 13 October 2026: no membership specifics are public — no
/// plan names, prices, features or billing. Everything sits under one
/// "Coming soon" statement. The earlier plan copy is archived, unpublished, in
/// the website repository (`archive/membership-drafts-2026-10-13.json`).
class MembershipCatalog {
  const MembershipCatalog(
      {required this.creatorNote,
      required this.comingSoon,
      required this.comingSoonDetail});
  final String creatorNote, comingSoon, comingSoonDetail;
  static Future<MembershipCatalog> load() async {
    final json =
        jsonDecode(await rootBundle.loadString('assets/membership-plans.json'))
            as Map<String, dynamic>;
    return MembershipCatalog(
        creatorNote: json['creatorNote'] as String,
        comingSoon: json['comingSoon'] as String,
        comingSoonDetail: json['comingSoonDetail'] as String);
  }
}
