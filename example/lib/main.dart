import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:graphql/client.dart';
import 'package:requests_inspector/requests_inspector.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(
    RequestsInspector(
      // Add your `navigatorKey` to enable `Stopper` feature
      navigatorKey: navigatorKey,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
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
    /*for restful apis Interceptor example use => fetchPostsUsingInterceptor() */
    // fetchPostsGraphQlUsingGraphQLFlutterInterceptor() /*for graph ql Interceptor example */;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Fetch Data Example',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: false),
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

// Fetching methods
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
      requestName: 'Posts',
      // Optional
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
  final dio = Dio(
    BaseOptions(
      validateStatus: (_) => true,
      // Headers added to bypass CloudFlare protection
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
                '(KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36',
        'Accept': 'application/json, text/plain, */*',
        'Accept-Language': 'en-US,en;q=0.9',
      },
    ),
  )..interceptors.add(RequestsInspectorInterceptor());
  final params = {'userId': 1};

  /// Unnecessary FormData, but added for TESTING
  final formData = await _getDummyFormData(dio);

  final response = await dio.get(
    'https://jsonplaceholder.typicode.com/posts',
    queryParameters: params,
    // The request does no need the body, but added for TESTING
    data: formData,
  );

  final posts = List.from(response.data).map((e) => Post.fromMap(e)).toList();

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
  }
''';

  final options = QueryOptions(
    document: gql(query),
  );
  final result = await client.query(options);
  if (result.hasException) {
    log(result.exception.toString());
  } else {
    log(result.data.toString());
  }
  var post = Post.fromMap(result.data?['post']);
  return [post];
}

Future<List<Post>>
    fetchPostsGraphQlWithVariablesUsingGraphQLFlutterInterceptor() async {
  final client = GraphQLClient(
    cache: GraphQLCache(),
    link: GraphQLInspectorLink(HttpLink('https://graphqlzero.almansi.me/api')),
  );
  const variables = {'id': 1};
  const query = r'''query GetPost($id: ID!) {
    post(id: $id) {
      id
      title
      body
    }
  }
''';

  final options = QueryOptions(
    document: gql(query),
    variables: variables,
  );
  final result = await client.query(options);
  if (result.hasException) {
    log(result.exception.toString());
  } else {
    log(result.data.toString());
  }
  var post = Post.fromMap(result.data?['post']);
  return [post];
}

/// Unnecessary FormData, but added for TESTING
Future<FormData> _getDummyFormData(final Dio dio) async {
  final formData = FormData();
  formData.fields.addAll(List.generate(4, (i) => MapEntry("test[$i]", "$i")));
  final imageBytes = await _getFlutterImageBytes(dio);
  if (imageBytes != null) {
    formData.files.add(
      MapEntry(
        'test_image',
        MultipartFile.fromBytes(
          imageBytes,
          filename: "flutter_logo.png",
          contentType: DioMediaType('image', 'png'),
        ),
      ),
    );
  }
  formData.files.add(
    MapEntry(
      'test_file',
      MultipartFile.fromString('test', filename: "test.txt"),
    ),
  );
  return formData;
}

/// Gets Flutter logo image in bytes from the server
Future<List<int>?> _getFlutterImageBytes(final Dio dio) async {
  const imageUrl =
      "https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png";
  final imgResp = await dio.get<List<int>>(
    imageUrl,
    options: Options(responseType: ResponseType.bytes),
  );

  return imgResp.data;
}

// Post model
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

  Post copyWith({int? userId, int? id, String? title, String? body}) {
    return Post(
      userId: userId ?? this.userId,
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
    );
  }

  Map<String, dynamic> toMap() {
    return {'userId': userId, 'id': id, 'title': title, 'body': body};
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

// Posts widget
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
        itemBuilder: (context, index) =>
            _PostItemBuilder(post: postsList[index]),
      ),
    );
  }
}

class _PostItemBuilder extends StatelessWidget {
  const _PostItemBuilder({required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Text(post.id.toString()),
      title: Text(post.title),
      subtitle: Text(post.body),
    );
  }
}
