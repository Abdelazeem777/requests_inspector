import 'package:example/posts_screen.dart';
import 'package:flutter/material.dart';
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
