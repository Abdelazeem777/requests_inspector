import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:requests_inspector/requests_inspector.dart';
import 'package:graphql/client.dart';

Future<List<Post>> fetchPosts() async {
  final dio = Dio(BaseOptions(validateStatus: (_) => true));
  final params = {'userId': 1};
  final response = await dio.get(
    'https://jsonplaceholder.typicode.com/posts',
    queryParameters: params,
  );

  final postsMap = response.data as List;
  final posts = postsMap.map((postMap) => Post.fromMap(postMap)).toList();

  InspectorController().addNewRequest(
    RequestDetails(
      requestName: 'Posts', //Optional
      requestMethod: RequestMethod.GET,
      url: 'https://jsonplaceholder.typicode.com/posts',
      queryParameters: params,
      statusCode: response.statusCode ?? 0,
      responseBody: response.data,
      headers: {'language': 'en'},
    ),
  );

  return posts;
}

Future<List<Post>> fetchPostsUsingInterceptor() async {
  final dio = Dio(BaseOptions(validateStatus: (_) => true))
    ..interceptors.add(RequestsInspectorInterceptor());
  final params = {'userId': 1};
  final response = await dio.get(
    'https://jsonplaceholder.typicode.com/posts',
    queryParameters: params,
  );

  final postsMap = response.data as List;
  final posts = postsMap.map((postMap) => Post.fromMap(postMap)).toList();

  return posts;
}

Future<List<Post>> fetchPostsGraphQlUsingGraphQLFlutterInterceptor() async {
  final client = GraphQLClient(
    cache: GraphQLCache(),
    link: GraphQLInspectorLink(HttpLink('https://graphqlzero.almansi.me/api')),
  );
  const query = r'''query {
    post(id: 1) {
      id
      title
      body
    }
    }''';

  final options = QueryOptions(document: gql(query));
  final result = await client.query(options);
  if (result.hasException) {
    log(result.exception.toString());
  } else {
    log(result.data.toString());
  }
  var post = Post.fromMap(result.data?['post']);
  return [post];
}

class Post {
  final int userId;
  final int id;
  final String title;
  final String body;
  Post({
    required this.userId,
    required this.id,
    required this.title,
    required this.body,
  });

  Post copyWith({
    int? userId,
    int? id,
    String? title,
    String? body,
  }) {
    return Post(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'id': id,
      'title': title,
      'body': body,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      userId: map['userId']?.toInt() ?? 0,
      id: int.tryParse(map['id'].toString()) ?? 0,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory Post.fromJson(String source) => Post.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Post(userId: $userId, id: $id, title: $title, body: $body)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Post &&
        other.userId == userId &&
        other.id == id &&
        other.title == title &&
        other.body == body;
  }

  @override
  int get hashCode {
    return userId.hashCode ^ id.hashCode ^ title.hashCode ^ body.hashCode;
  }
}

final navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(
      RequestsInspector(
        // Add your `navigatorKey` to enable `Stopper` feature
        navigatorKey: navigatorKey,
        child: const MyApp(),
      ),
    );

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Post> posts = [];
  bool isLoading = true;

  @override
  void initState() {
    fetchPostsUsingInterceptor().then(
      (value) => setState(() {
        posts = value;
        isLoading = false;
      }),
    );
    /*for restful apis Interceptor example use => fetchPostsUsingInterceptor() */;
    // fetchPostsGraphQlUsingGraphQLFlutterInterceptor() /*for graph ql Interceptor example */;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Fetch Data Example',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: false,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Fetch Data Example'),
          leading: InkWell(
            child: const Padding(
              padding: EdgeInsets.all(8.0),
              child: Icon(Icons.refresh),
            ),
            onTap: () {
              setState(() => isLoading = true);
              fetchPostsUsingInterceptor().then(
                (value) => setState(() {
                  posts = value;
                  isLoading = false;
                }),
              );
            },
          ),
        ),
        body: Center(
          child: () {
            if (isLoading) return const CircularProgressIndicator();

            if (posts.isNotEmpty) {
              return PostsListWidget(
                postsList: posts,
                onRefresh: () => fetchPostsUsingInterceptor().then(
                  (value) => setState(() => posts = value),
                ),
              );
            }

            return const Text('Empty list (error)');

            // By default, show a loading spinner.
          }(),
        ),
      ),
    );
  }
}

class PostsListWidget extends StatelessWidget {
  const PostsListWidget({
    Key? key,
    required this.postsList,
    required this.onRefresh,
  }) : super(key: key);

  final RefreshCallback onRefresh;

  final List<Post> postsList;
  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView.builder(
        shrinkWrap: true,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: postsList.length,
        itemBuilder: _buildPostItem,
      ),
    );
  }

  Widget _buildPostItem(BuildContext context, int index) {
    final post = postsList[index];
    return ListTile(
      leading: Text(post.id.toString()),
      title: Text(post.title),
      subtitle: Text(post.body),
    );
  }
}
