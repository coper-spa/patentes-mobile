import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/app_providers.dart';

Future<void> showNavigationOptions({
  required BuildContext context,
  required WidgetRef ref,
  required double latitude,
  required double longitude,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    builder: (sheetContext) {
      return SafeArea(
        child: Wrap(
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.alt_route),
              title: const Text('Abrir en Waze'),
              onTap: () async {
                Navigator.of(sheetContext).pop();
                await ref
                    .read(externalNavigationServiceProvider)
                    .openWaze(latitude, longitude);
              },
            ),
          ],
        ),
      );
    },
  );
}
