
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:requests_inspector/requests_inspector.dart';

import 'main.dart'
    show
        fetchPostsGraphQlUsingGraphQLFlutterInterceptor,
        fetchPostsGraphQlWithVariablesUsingGraphQLFlutterInterceptor,
        Post;

// Run with `flutter run -t lib/playground_main.dart`.
//
// The Maestro flows in .maestro/ drive this page. It sends a request with
// every client the example offers (Dio, FormData, GraphQL, a manual
// `addNewRequest`) and shows what the app really got back. The POST requests
// go to https://postman-echo.com, which answers with the request it received,
// so a flow can check what the request stopper sent and what the response
// stopper handed to the app (including the JSON type of every value).

final _navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    RequestsInspector(
      // Add your `navigatorKey` to enable `Stopper` feature
      navigatorKey: _navigatorKey,
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'Playground',
        theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
        home: const PlaygroundPage(),
      ),
    ),
  );
}

const _echoUrl = 'https://postman-echo.com';

/// The JSON body of "Dio POST JSON". `note` has both quote characters, so a
/// shared cURL command must escape it.
const _postBody = {
  'name': 'original',
  'count': 1,
  'active': true,
  'note': 'it\'s "quoted"',
  'profile': {'age': 30, 'verified': false},
};

class PlaygroundPage extends StatefulWidget {
  const PlaygroundPage({Key? key}) : super(key: key);

  @override
  State<PlaygroundPage> createState() => _PlaygroundPageState();
}

class _PlaygroundPageState extends State<PlaygroundPage> {
  final _dio = Dio(BaseOptions(validateStatus: (_) => true))
    ..interceptors.add(RequestsInspectorInterceptor());

  var _lines = const ['Tap a button to send a request'];

  Future<void> _run(String name, Future<List<String>> Function() action) async {
    setState(() => _lines = ['$name: waiting']);
    List<String> lines;
    try {
      lines = ['$name: done', ...await action()];
    } catch (e) {
      lines = ['$name: failed', '$e'];
    }
    if (mounted) setState(() => _lines = lines);
  }

  Future<List<String>> _dioGet() async {
    final response = await _dio.get(
      '$_echoUrl/get',
      queryParameters: {'source': 'playground', 'page': 1},
    );
    return [
      'status: ${response.statusCode}',
      'echo query: ${jsonEncode(response.data['args'])}',
    ];
  }

  Future<List<String>> _dioPostJson() async {
    final response = await _dio.post(
      '$_echoUrl/post',
      queryParameters: {'step': 'original'},
      data: _postBody,
      options: Options(headers: {'x-e2e': 'original'}),
    );
    final data = response.data;
    if (data is! Map) {
      return ['status: ${response.statusCode}', 'body: ${jsonEncode(data)}'];
    }
    final headers = data['headers'];
    return [
      'status: ${response.statusCode}',
      'echo json: ${jsonEncode(data['json'])}',
      'echo types: ${_describeTypes(data['json'])}',
      'echo header x-e2e: ${headers is Map ? headers['x-e2e'] : null}',
      'echo query: ${jsonEncode(data['args'])}',
    ];
  }

  Future<List<String>> _dioFormData() async {
    final formData = await _getFormData();
    final response = await _dio.post('$_echoUrl/post', data: formData);
    final data = response.data;
    final files = data is Map ? data['files'] : null;
    return [
      'status: ${response.statusCode}',
      'echo form: ${jsonEncode(data is Map ? data['form'] : data)}',
      'echo files: ${files is Map ? files.keys.join(', ') : files}',
    ];
  }

  /// Fields, a text file and an image (the package logo, downloaded without
  /// the inspector, so only the upload shows).
  Future<FormData> _getFormData() async {
    final logo = await Dio().get<List<int>>(
      'https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/logo_with_text_right.png',
      options: Options(responseType: ResponseType.bytes),
    );
    return FormData()
      ..fields.addAll(List.generate(4, (i) => MapEntry('test[$i]', '$i')))
      ..files.addAll([
        if (logo.data != null)
          MapEntry(
            'test_image',
            MultipartFile.fromBytes(
              logo.data!,
              filename: 'flutter_logo.png',
              contentType: DioMediaType('image', 'png'),
            ),
          ),
        MapEntry(
          'test_file',
          MultipartFile.fromString('test', filename: 'test.txt'),
        ),
      ]);
  }

  /// A small JSON response (numbers and a bool) for the response stopper.
  Future<List<String>> _dioGetTodo() async {
    final response = await _dio.get('https://dummyjson.com/todos/1');
    return [
      'status: ${response.statusCode}',
      'body: ${jsonEncode(response.data)}',
      'types: ${_describeTypes(response.data)}',
    ];
  }

  Future<List<String>> _dioHead() async {
    final response = await _dio.head('$_echoUrl/get');
    return ['status: ${response.statusCode}'];
  }

  Future<List<String>> _dio404() async {
    final response = await _dio.get('$_echoUrl/status/404');
    return ['status: ${response.statusCode}'];
  }

  Future<List<String>> _graphQl(Future<List<Post>> Function() fetch) async {
    final post = (await fetch()).first;
    return ['post: ${post.id} ${post.title}'];
  }

  /// The README's way without Dio's interceptor: send the request, then log
  /// it with `InspectorController().addNewRequest` (like `fetchPosts`).
  Future<List<String>> _manualLog() async {
    final params = {'manual': 'yes'};
    final response = await Dio(
      BaseOptions(validateStatus: (_) => true),
    ).get('$_echoUrl/get', queryParameters: params);
    InspectorController().addNewRequest(
      RequestDetails(
        requestName: 'Manual',
        requestMethod: RequestMethod.GET,
        url: '$_echoUrl/get',
        queryParameters: params,
        statusCode: response.statusCode ?? 0,
        responseBody: response.data,
        headers: {'language': 'en'},
      ),
    );
    return ['status: ${response.statusCode}'];
  }

  /// Shows (and saves, for checks on the host) what the inspector's share
  /// sheet or copy buttons put on the clipboard.
  Future<List<String>> _readClipboard() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text ?? '';
    final kind = _clipboardKind(text);
    final file = File('${Directory.systemTemp.path}/e2e_clipboard_$kind.txt');
    await file.writeAsString(text);
    return [
      'clipboard kind: $kind',
      if (kind == 'har') 'clipboard har: ${_describeHar(text)}',
      'clipboard saved: ${file.path}',
      'clipboard text: $text',
    ];
  }

  @override
  Widget build(BuildContext context) {
    final actions = <String, Future<List<String>> Function()>{
      'Dio GET': _dioGet,
      'Dio POST JSON': _dioPostJson,
      'Dio FormData': _dioFormData,
      'Dio GET todo': _dioGetTodo,
      'Dio HEAD': _dioHead,
      'Dio 404': _dio404,
      'GraphQL query': () =>
          _graphQl(fetchPostsGraphQlUsingGraphQLFlutterInterceptor),
      'GraphQL vars': () => _graphQl(
        fetchPostsGraphQlWithVariablesUsingGraphQLFlutterInterceptor,
      ),
      'Manual log': _manualLog,
      'Read clipboard': _readClipboard,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Playground')),
      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: [
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: [
              for (final entry in actions.entries)
                ElevatedButton(
                  onPressed: () => _run(entry.key, entry.value),
                  child: Text(entry.key),
                ),
            ],
          ),
          const Divider(),
          for (final line in _lines)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Text(line),
            ),
        ],
      ),
    );
  }
}

/// `name=String count=int profile.age=int ...` for every value in [value].
String _describeTypes(Object? value, [String path = '']) {
  if (value is Map) {
    return value.entries
        .map(
          (e) => _describeTypes(
            e.value,
            path.isEmpty ? '${e.key}' : '$path.${e.key}',
          ),
        )
        .join(' ');
  }
  final type = switch (value) {
    null => 'null',
    bool() => 'bool',
    int() => 'int',
    double() => 'double',
    String() => 'String',
    List() => 'List',
    _ => value.runtimeType.toString(),
  };
  return path.isEmpty ? type : '$path=$type';
}

String _clipboardKind(String text) {
  if (text.isEmpty) return 'empty';
  if (text.startsWith('curl ')) return 'curl';
  if (text.startsWith('================[cURL Command]')) return 'both';
  if (text.startsWith('=[ ')) return 'log';
  try {
    final json = jsonDecode(text);
    if (json is Map && json['log'] is Map) return 'har';
    return 'json';
  } on FormatException {
    return 'text';
  }
}

/// The parts of a HAR log the flows check (it is valid JSON if this works).
String _describeHar(String text) {
  final log = (jsonDecode(text) as Map)['log'] as Map;
  final entries = log['entries'] as List;
  final entry = entries.first as Map;
  final request = entry['request'] as Map;
  final response = entry['response'] as Map;
  final creator = log['creator'] as Map;
  return 'version=${log['version']} '
      'creator=${creator['name']}/${creator['version']} entries=${entries.length} '
      'method=${request['method']} url=${request['url']} '
      'status=${response['status']} '
      'postData=${jsonEncode(request['postData'])}';
}
