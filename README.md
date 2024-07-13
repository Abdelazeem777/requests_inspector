[![Stand With Palestine](https://raw.githubusercontent.com/TheBSD/StandWithPalestine/main/banner-no-action.svg)](https://thebsd.github.io/StandWithPalestine)

<div align="center" bgcolor="white">
<img src="https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/logo_with_text_right.png" height= "350">
</div>

# requests_inspector 🕵

[![pub package](https://img.shields.io/pub/v/requests_inspector.svg)](https://pub.dev/packages/requests_inspector)

A Flutter package for **logging** API requests (**Http Requests** & **GraphQL**) requests.

### Main Features:

1. Log your `Http request`, `GraphQL` and `WebSockets`.
2. Intercept your requests and responses for testing.
3. Share request details as json or as `cURL` to re-run it again (ex. `Postman`).

And more and more

##### To get the `RequestsInspector` widget on your screen:

1. 📱💃 : **Shake** your phone.

2. 📱👈 : **Long-Press** on any free space on the screen.

<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/mobile_list.jpg" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/mobile_request.jpg" width ="280" />

Also you can share the request details as (**Log** or **cURL** command) with your team to help them debug the API requests.

**From Inspector to Postman 🧡 🎉️**
Now you can extract `cURL` command from the **inspector** to send the request again from your terminal or [Postman](https://www.postman.com/) 💪💪

<img src="https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/curl_share_request.gif" width="600"/>

## `Setup`

First, add it at the top of your `MaterialApp` with `enabled: true`.

```dart
void main() {
  runApp(const RequestsInspector(
    child: MyApp(),
  ));
}
```

### 1. RESTful API:

#### Using `Dio`, pass by `RequestsInspectorInterceptor()` to `Dio.interceptors` and we are good to go 🎉️🎉️.

```dart
final dio = Dio()..interceptors.add(RequestsInspectorInterceptor());

```

### If you don't use `Dio` then don't worry

In your API request just add a new `RequestDetails` using `RequestInspectorController` filled with the API data.

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

<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/mobile_list.jpg" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/mobile_request.jpg" width ="280" />

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

### Stopper (Requests & Responses)

`requests_inspector` **(Stopper)** enables your to stop and edit requests (before sending it to server) and responses (before receiving it inside the app).

- First, you need to add navigatorKey to your `MaterialApp` then pass it to `RequestsInspector` to show Stopper dialogs.

```dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() => runApp(
  RequestsInspector(
    // Add your `navigatorKey` to enable `Stopper` feature
    navigatorKey: navigatorKey,
    child: const MyApp(),
  ),
);

...

@override
Widget build(BuildContext context) {
  return MaterialApp(
    navigatorKey: navigatorKey, // <== Here!
    ...

```

- Second, just enable it from Inspector and it will stop all your requests and responses.

<img src="https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/stopper_feature.gif" width="280"/>

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

## Some images

<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/web_list.png" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/web_request.png" width ="280" />
<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/mac_list.png" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/mac_request.png" width ="280" />
<img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/linux_list.png" width ="280" /> <img src = "https://raw.githubusercontent.com/Abdelazeem777/requests_inspector/main/images/linux_request.png" width ="280" />

## Future plans:

- [x] Add support for `GraphQL`.
- [x] Enhance the `GraphQL` request and response displaying structure.
- [x] Improve the request tab UI and add expand/collapse for each data block.
- [ ] Support Dark/Light Modes.
- [ ] Add search inside the request details page.
- [ ] Add Http Interceptor.

## 📃 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
