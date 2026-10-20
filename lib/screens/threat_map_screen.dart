import 'package:flutter/material.dart';

import '../widgets/common.dart';

/// Radware's Live Threat Map opens on Radware's own site in the browser.
/// Owner decision, 20 October 2026: link out rather than embed the map or
/// cover parts of a third party's page.
const threatMapUrl = 'https://livethreatmap.radware.com/';

Future<void> openThreatMap(BuildContext context) =>
    openResource(context, threatMapUrl);
