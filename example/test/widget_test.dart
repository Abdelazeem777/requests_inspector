import 'package:example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Post.fromMap reads the dummyjson fields', () {
    final post = Post.fromMap({'id': '3', 'title': 'Hello', 'body': 'World'});

    expect(post, Post(id: 3, title: 'Hello', body: 'World'));
    expect(Post.fromJson(post.toJson()), post);
  });

  testWidgets('PostsListWidget shows every post', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: PostsListWidget(
          postsList: [
            Post(id: 1, title: 'First', body: 'First body'),
            Post(id: 2, title: 'Second', body: 'Second body'),
          ],
          onRefresh: () async {},
        ),
      ),
    ));

    expect(find.byType(ListTile), findsNWidgets(2));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second body'), findsOneWidget);
  });
}
