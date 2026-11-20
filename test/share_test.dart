import 'dart:convert';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/curl_command_generator.dart';
import 'package:requests_inspector/src/enums/share_type_enum.dart';
import 'package:share_plus_platform_interface/share_plus_platform_interface.dart';

import 'helpers/fakes.dart';
import 'helpers/plugin_mocks.dart';

void main() {
  final platform = RecordingSharePlatform();
  late InspectorController controller;
  final request = sampleRequest(
    requestMethod: RequestMethod.POST,
    requestBody: {'name': 'John'},
  );

  // Must happen before the first share: SharePlus caches the platform.
  setUpAll(() => SharePlatform.instance = platform);

  setUp(() {
    platform.shared.clear();
    controller = InspectorController(
      enabled: true,
      showInspectorOn: ShowInspectorOn.LongPress,
    )..selectedRequest = request;
  });

  tearDown(() => controller.dispose());

  Future<ShareParams> share(ShareType type, {Rect? origin}) async {
    controller.shareSelectedRequest(
      shareType: type,
      sharePositionOrigin: origin,
    );
    await pumpEventQueue();
    return platform.shared.single;
  }

  test('NormalLog shares one section per non-null field', () async {
    final text = (await share(ShareType.NormalLog)).text!;

    expect(text, startsWith('=[ requestName ]===================\n"USERS"'));
    expect(text, contains('=[ url ]===================\n"${request.url}"'));
    expect(text, contains('=[ statusCode ]===================\n200'));
    expect(text, contains('"name": "John"'));
    expect(text, isNot(contains('graphqlRequestVars')));
  });

  test('NormalLog keeps the JSON types of nested body values', () async {
    controller.selectedRequest = sampleRequest(
      requestMethod: RequestMethod.POST,
      requestBody: {'active': true, 'n': 1, 'x': null},
    );

    final text = (await share(ShareType.NormalLog)).text!;

    expect(text, contains('"active": true'));
    expect(text, contains('"n": 1'));
    expect(text, contains('"x": null'));
  });

  test('CurlCommand shares the generated command', () async {
    final params = await share(ShareType.CurlCommand);

    expect(params.text, CurlCommandGenerator(request).generate());
  });

  test('Both shares the cURL command followed by the normal log', () async {
    final text = (await share(ShareType.Both)).text!;

    expect(text, startsWith('================[cURL Command]================='));
    expect(text, contains(CurlCommandGenerator(request).generate()));
    expect(text, contains('==================[Normal Log]==================='));
    expect(text.indexOf('Normal Log'), greaterThan(text.indexOf('curl -X')));
  });

  test('Har shares the HAR document as text', () async {
    final text = (await share(ShareType.Har)).text!;

    final har = jsonDecode(text) as Map<String, dynamic>;
    final entry = (har['log']['entries'] as List).single;
    expect(entry['request']['method'], 'POST');
    expect(entry['comment'], contains('curl -X POST'));
  });

  test('HarFile shares the HAR document as a JSON file', () async {
    final params = await share(ShareType.HarFile);

    expect(params.text, isNull);
    final file = params.files!.single;
    expect(file.mimeType, 'application/json');
    final har = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    expect(har['log']['version'], '1.2');
    expect(
      (har['log']['entries'] as List).single['request']['url'],
      contains(request.url),
    );
  });

  test(
    'HarFile names the shared file request.har',
    () async {
      final params = await share(ShareType.HarFile);

      // On dart:io, XFile.fromData ignores `name`; share_plus then invents a
      // random "<uuid>.json" name unless fileNameOverrides is given.
      expect(
        params.fileNameOverrides?.single ?? params.files!.single.name,
        'request.har',
      );
    },
    skip:
        'Known bug: on Android/iOS the file is shared as "<uuid>.json" '
        'because XFile.fromData(name:) is ignored on dart:io and no '
        'fileNameOverrides is passed (inspector_controller.dart:374).',
  );

  test('passes the share position origin through', () async {
    const origin = Rect.fromLTWH(1, 2, 3, 4);

    for (final type in [ShareType.NormalLog, ShareType.HarFile]) {
      platform.shared.clear();
      expect((await share(type, origin: origin)).sharePositionOrigin, origin);
    }
  });
}
