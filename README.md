# requests_inspector 🕵

A Flutter package for logging API requests and accessing it by **Shaking** your phone to get the `RequestsInspector` widget on your screen.

### First, add it at the top of your `MaterialApp` with `enabled: true`.

```dart
void main() {
  runApp(const RequestsInspector(
    enabled: true,
    child: MyApp(),
  ));
}

```

**Note:** Don't forget to `enable` it!

### Then, on your API request add a new `RequestDetails` using `RequestInspectorController` filled with the API data.

```dart
InspectorController().addNewRequest(
    RequestDetails(
        requestName: requestName,
        requestMethod: RequestMethod.GET,
        url: apiUrl,
        statusCode: responseStatusCode,
        responseBody: responseData,
        sentTime: DateTime.now(),
        ),
    );
```

### Real example

```dart
Future<List<Post>> fetchPosts() async {
  final dio = Dio();
  final response = await dio.get('https://jsonplaceholder.typicode.com/posts');

  final postsMap = response.data as List;
  final posts = postsMap.map((postMap) => Post.fromMap(postMap)).toList();

  InspectorController().addNewRequest(
    RequestDetails(
      requestName: 'Posts',
      requestMethod: RequestMethod.GET,
      url: 'https://jsonplaceholder.typicode.com/posts',
      statusCode: response.statusCode ?? 0,
      responseBody: response.data,
      sentTime: DateTime.now(),
    ),
  );

  return posts;
}

```

### Finlay, `Shake` your phone to get the `Inspector`

<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/Screenshot_20211211-004944.jpg" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/Screenshot_20211211-004949.jpg" width ="280" />

We are done 🎉️ 😁️
