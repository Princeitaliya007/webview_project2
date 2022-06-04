import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebLoad extends StatefulWidget {
  const WebLoad({Key? key}) : super(key: key);

  @override
  State<WebLoad> createState() => _WebLoadState();
}

class _WebLoadState extends State<WebLoad> {
  final GlobalKey webViewKey = GlobalKey();

  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;
  TextEditingController textEditingController = TextEditingController();

  double progress = 0;
  bool isreload = true;

  List bookmarks = [];

  InAppWebViewGroupOptions options = InAppWebViewGroupOptions(
    crossPlatform: InAppWebViewOptions(
      useShouldOverrideUrlLoading: true,
      mediaPlaybackRequiresUserGesture: false,
    ),
    android: AndroidInAppWebViewOptions(
      useHybridComposition: true,
    ),
    ios: IOSInAppWebViewOptions(
      allowsInlineMediaPlayback: true,
    ),
  );

  onwebrefresh() async {
    pullToRefreshController = PullToRefreshController(
        options: PullToRefreshOptions(
          color: Colors.blue,
        ),
        onRefresh: () async {
          if (Platform.isAndroid) {
            webViewController!.reload();
          } else if (Platform.isIOS) {
            webViewController!.loadUrl(
                urlRequest: URLRequest(url: await webViewController!.getUrl()));
          }
        });
  }

  @override
  void initState() {
    super.initState();
    onwebrefresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff54759e),
        title: const Text("WebView"),
        actions: [
          IconButton(
            onPressed: () async {
              await webViewController!.goBack();
            },
            icon: const Icon(Icons.arrow_back),
          ),
          IconButton(
            onPressed: () async {
              await webViewController!.reload();
            },
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              await webViewController!.goForward();
            },
            icon: const Icon(Icons.arrow_forward),
          ),
          (isreload)
              ? IconButton(
                  onPressed: () async {
                    setState(() {
                      pullToRefreshController!.endRefreshing();
                    });
                  },
                  icon: const Icon(Icons.close),
                )
              : Container(),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Container(
              width: 370,
              height: 70,
              child: TextField(
                controller: textEditingController,
                decoration: InputDecoration(
                  hintText: "Search Website",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        textEditingController.clear();
                      });
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
                onSubmitted: (value) {
                  var url = Uri.parse(value);
                  if (url.scheme.isEmpty) {
                    url = Uri.parse("https://www.google.com/search?q=" + value);
                  }
                  webViewController?.loadUrl(
                    urlRequest: URLRequest(url: url),
                  );

                  print(url);
                },
              ),
            ),
          ),
          (progress < 1)
              ? LinearProgressIndicator(
                  value: progress,
                )
              : Container(),
          Expanded(
            flex: 9,
            child: InAppWebView(
              key: webViewKey,
              initialUrlRequest: URLRequest(
                  url: Uri.parse(
                      "https://google.co.in/" + textEditingController.text)),
              initialOptions: options,
              pullToRefreshController: pullToRefreshController,
              onWebViewCreated: (controller) {
                webViewController = controller;
              },
              onLoadStart: (controller, url) {
                setState(() {
                  textEditingController.text =
                      url!.scheme.toString() + "://" + url.host + url.path;
                });
              },
              onLoadStop: (controller, url) {
                pullToRefreshController!.endRefreshing();
                setState(() {
                  textEditingController.text =
                      url!.scheme.toString() + "://" + url.host + url.path;
                });
              },
              androidOnPermissionRequest:
                  (controller, origin, resources) async {
                return PermissionRequestResponse(
                    resources: resources,
                    action: PermissionRequestResponseAction.GRANT);
              },
              onProgressChanged: (controller, val) {
                if (val == 100) {
                  pullToRefreshController!.endRefreshing();
                }
                setState(() {
                  progress = val / 100;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: const Icon(Icons.bookmark),
            onPressed: () async {
              Uri? uri = await webViewController!.getUrl();

              String myurl =
                  uri!.scheme.toString() + "://" + uri.host + uri.path;

              setState(() {
                bookmarks.add(myurl);
              });

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Successfully Bookmarked..."),
                ),
              );
            },
          ),
          const SizedBox(
            width: 5,
          ),
          FloatingActionButton(
            child: const Icon(Icons.more_vert),
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text("Bookmarked links"),
                      content: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: bookmarks
                            .map((e) => Padding(
                                  padding: EdgeInsets.all(10),
                                  child: GestureDetector(
                                    onTap: () async {
                                      await webViewController!.loadUrl(
                                        urlRequest: URLRequest(
                                          url: Uri.parse(e),
                                        ),
                                      );
                                      Navigator.of(context).pop();
                                    },
                                    child: Text(e),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  });
            },
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
    );
  }
}
