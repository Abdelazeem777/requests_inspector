# requests_inspector 🕵

A Flutter package for logging restful & graph ql APIS requests and accessing it by **Shaking** your phone to get the `RequestsInspector` widget on your screen.

### First, add it at the top of your `MaterialApp` with `enabled: true`.

```dart
void main() {
  runApp(const RequestsInspector(
    enabled: true,
    child: MyApp(),
  ));
}
```
### 1. Restful: 

**Note:** Don't forget to `enable` it!

### Then, on your API request add a new `RequestDetails` using `RequestInspectorController` filled with the API data.

```dart
InspectorController().addNewRequest(
    RequestDetails(
        requestName: requestName,
        requestMethod: RequestMethod.GET,
        url: apiUrl,
        queryParameters: params,
        statusCode: responseStatusCode,
        responseBody: responseData,
        ),
    );
```

### OR, if you are using `Dio`, then you can just pass `RequestsInspectorInterceptor()` to `Dio.interceptors` and we are good to go 🎉️🎉️.

```dart
final dio = Dio()..interceptors.add(RequestsInspectorInterceptor());

```

### Real Restful example

a. Normal `InspectorController().addNewRequest`.

```dart
Future<List<Post>> fetchPosts() async {
  final dio = Dio();
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
      requestMethod: RequestMethod.GET,
      url: 'https://jsonplaceholder.typicode.com/posts',
      queryParameters: params,
      statusCode: response.statusCode ?? 0,
      responseBody: response.data,
    ),
  );

  return posts;
}
```

b. Using `RequestsInspectorInterceptor`.

```dart
Future<List<Post>> fetchPosts() async {
  final dio = Dio()..interceptors.add(RequestsInspectorInterceptor());
  final response = await dio.get('https://jsonplaceholder.typicode.com/posts');

  final postsMap = response.data as List;
  final posts = postsMap.map((postMap) => Post.fromMap(postMap)).toList();

  return posts;
}
```
### Finlay, `Shake` your phone to get the `Inspector`

<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/mobile_list.jpg" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/mobile_request.jpg" width ="280" />

### 2. Graph Ql:
### You can use `HassuraConnect` library to use the graph ql requests, then you can just pass `HasuraGraphQLInterceptor()` to `HassuraConnect.interceptors` and we are good to go 🎉️🎉️.

```dart
 Future<List<Post>> fetchPostsGraphQlUsingHasuraInterceptor() async {
  final response = await HasuraConnect(
    'https://graphqlzero.almansi.me/api',
    interceptors: [HasuraGraphQLInterceptor()],
  ).query('''query {
    post(id: 1) {
      id
      title
      body
    }
    }''');
  print(response);
  var post = Post.fromMap(response['data']['post']);
  print(post.toMap());

  return [post];
}
```
### Finlay, `Shake` your phone to get the `Inspector`

<img src = "https://user-images.githubusercontent.com/13955306/221519994-ebe40514-60d0-4aec-a14e-7684d6d2d832.png" width ="280" /> <img src = "https://user-images.githubusercontent.com/13955306/221518947-9b8fada5-7648-45af-a52d-f09e95b91e51.png" width ="280" /> 



### For Web, Windows, MacOS and Linux

Obviously, The shaking won't be good enough for those platforms 😅

So you can specify `showInspectorOn` with `ShowInspectorOn.LongPress`.

```dart
void main() {
  runApp(const RequestsInspector(
    enabled: true,
    showInspectorOn: ShowInspectorOn.LongPress
    child: MyApp(),
  ));
}
```

OR, you can just pass `ShowInspectorOn.Both` to open the `Inspector` with `Shaking` or with `LongPress`.

```dart
void main() {
  runApp(const RequestsInspector(
    enabled: true,
    showInspectorOn: ShowInspectorOn.Both
    child: MyApp(),
  ));
}
```

## Some screenshots

<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/web_list.png" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/web_request.png" width ="280" />
<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/mac_list.png" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/mac_request.png" width ="280" />
<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/linux_list.png" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/linux_request.png" width ="280" />