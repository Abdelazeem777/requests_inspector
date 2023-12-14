[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)

# requests_inspector 🕵

A Flutter package for **logging** API requests (**RESTful API** & **GraphQL**) requests and accessing it by **Shaking** your phone to get the `RequestsInspector` widget on your screen.

Also you can share the request details as (**Log** or **cURL** command) with your team to help them debug the API requests.

**Note:**
You can use `cURL` command to send the request again from your terminal or [Postman](https://www.postman.com/) 💪💪

<img src="https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/screenshots/curl_share_request.gif" width="600"/>

### First, add it at the top of your `MaterialApp` with `enabled: true`.

```dart
void main() {
  runApp(const RequestsInspector(
    enabled: true,
    child: MyApp(),
  ));
}
```

### 1. RESTful API:

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

### 2. GraphQl:

To use `requests_inspector` with [graphql_flutter]('https://pub.dev/packages/graphql_flutter') library.
you jus need to wrap your normal `HttpLink` with our `GraphQLInspectorLink` and we are done.

**Example:**

```dart
 Future<List<Post>> fetchPostsGraphQlUsingGraphQLFlutterInterceptor() async {
 Future<List<Post>> fetchPostsGraphQlUsingGraphQLFlutterInterceptor() async {
  final client = GraphQLClient(
    cache: GraphQLCache(),
    link: Link.split(
      (request) => request.isSubscription,
      GraphQLInspectorLink(WebSocketLink('ws://graphqlzero.almansi.me/api')),
      GraphQLInspectorLink(HttpLink('https://graphqlzero.almansi.me/api')),
    ),
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

```

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

## Future plans

- [x] Add support for `GraphQL`.
- [ ] Enhance the `GraphQL` request and response displaying structure.
- [ ] Improve the request tab UI and add expand/collapse for each data block.
- [ ] Add search inside the request details page.

## 📃 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
