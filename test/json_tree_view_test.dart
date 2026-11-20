import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:requests_inspector/src/json_tree_view_widget.dart';

import 'helpers/inspector_app.dart';

void main() {
  late InspectorController controller;

  setUp(() {
    controller = InspectorController(
      enabled: true,
      showInspectorOn: ShowInspectorOn.LongPress,
    );
  });

  tearDown(() => controller.dispose());

  Future<void> pumpTree(
    WidgetTester tester,
    dynamic data, {
    bool expandChildren = true,
    String searchQuery = '',
    bool isDarkMode = false,
  }) =>
      tester.pumpWidget(
        ChangeNotifierProvider<InspectorController>.value(
          value: controller,
          child: MaterialApp(
            home: Scaffold(
              body: JsonTreeView(
                data,
                isDarkMode: isDarkMode,
                expandChildren: expandChildren,
                searchQuery: searchQuery,
              ),
            ),
          ),
        ),
      );

  Color? colorOf(WidgetTester tester, String value) {
    for (final widget
        in tester.widgetList<SelectableText>(find.byType(SelectableText))) {
      Color? color;
      widget.textSpan?.visitChildren((span) {
        if (span is TextSpan && span.text == value) color = span.style?.color;
        return color == null;
      });
      if (color != null) return color;
    }
    return null;
  }

  const user = {
    'id': 1,
    'name': 'John',
    'admin': false,
    'manager': null,
    'tags': ['a', 'b'],
    'address': {'city': 'Cairo'},
    'empty': <String, dynamic>{},
    'none': [],
  };

  testWidgets('renders keys and typed values', (tester) async {
    await pumpTree(tester, user);

    expect(
      selectableTexts(tester),
      containsAll([
        '"id" : 1,',
        '"name" : "John",',
        '"admin" : false,',
        '"manager" : null,',
        '"a"',
        '"city" : "Cairo",',
        '"empty" : {},',
        '"none" : [],',
      ]),
    );
    expect(find.text('} ,'), findsNWidgets(2), reason: 'root and address');
    expect(find.text('] ,'), findsOneWidget);
    expect(colorOf(tester, '"John"'), Colors.green.shade700);
    expect(colorOf(tester, '1'), Colors.blue.shade700);
    expect(colorOf(tester, 'false'), Colors.orange.shade700);
    expect(colorOf(tester, 'null'), Colors.grey.shade600);
  });

  testWidgets('uses dark mode colors', (tester) async {
    await pumpTree(tester, user, isDarkMode: true);

    expect(colorOf(tester, '"John"'), Colors.green.shade300);
    expect(colorOf(tester, '1'), Colors.blue.shade300);
  });

  testWidgets('collapses and expands a node on tap', (tester) async {
    await pumpTree(tester, user);
    expect(selectableTexts(tester), contains('"city" : "Cairo",'));

    await tester.tap(find.textContaining('"address" : '));
    await tester.pumpAndSettle();

    expect(selectableTexts(tester), isNot(contains('"city" : "Cairo",')));
    expect(find.textContaining('"address" : {1} ,'), findsOneWidget);

    await tester.tap(find.textContaining('"address" : '));
    await tester.pumpAndSettle();
    expect(selectableTexts(tester), contains('"city" : "Cairo",'));
  });

  testWidgets('expandChildren: false only expands the root', (tester) async {
    await pumpTree(tester, user, expandChildren: false);

    expect(selectableTexts(tester), contains('"name" : "John",'));
    expect(find.textContaining('"address" : {1} ,'), findsOneWidget);
    expect(find.textContaining('"tags" : [2] ,'), findsOneWidget);
  });

  testWidgets('renders a top-level list', (tester) async {
    await pumpTree(tester, [
      {'id': 1},
      2,
    ]);

    expect(selectableTexts(tester), containsAll(['"id" : 1,', '2']));
  });

  testWidgets('renders FormData fields and files', (tester) async {
    final formData = FormData.fromMap({'name': 'John'})
      ..files.add(MapEntry(
        'avatar',
        MultipartFile.fromBytes(List.filled(2048, 0), filename: 'me.png'),
      ));

    await pumpTree(tester, formData);

    expect(
      selectableTexts(tester),
      containsAll(['"name" : "John",', '"avatar" : "(2.0 kb) - me.png",']),
    );
    await pumpTree(tester, FormData());
    expect(selectableTexts(tester), ['{}']);
  });

  testWidgets('highlights search matches', (tester) async {
    controller
      ..selectedRequest = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://api.example.com',
        responseBody: user,
      )
      ..updateSearchQuery('a');

    await pumpTree(tester, user, searchQuery: 'a');

    final highlights = highlightedSpans(tester);
    expect(highlights, isNotEmpty);
    expect(highlights.map((s) => s.text!.toLowerCase()), everyElement('a'));
  });

  testWidgets('expands a collapsed node that holds the active match',
      (tester) async {
    controller
      ..selectedRequest = RequestDetails(
        requestMethod: RequestMethod.GET,
        url: 'https://x.io',
        responseBody: {
          'address': {'city': 'Cairo'},
        },
      )
      ..updateSearchQuery('cairo');

    await pumpTree(
      tester,
      {
        'address': {'city': 'Cairo'},
      },
      expandChildren: false,
      searchQuery: 'cairo',
    );
    await tester.pumpAndSettle();

    expect(selectableTexts(tester), contains('"city" : "Cairo",'));
    expect(
        highlightedSpans(tester).single.style!.backgroundColor, Colors.orange);
  });
}
