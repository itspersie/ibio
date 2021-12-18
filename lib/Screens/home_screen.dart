import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
// import 'package:data_connection_checker/data_connection_checker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final String _baseUrl =
      'https://api.github.com/users/JakeWharton/repos?page=1&per_page=15';

  int _page = 0;
  final int _limit = 15;
  bool _hasNextPage = true;
  bool _isFirstLoadRunning = false;
  bool _isLoadMoreRunning = false;
  List _repo = [];
  var tempRep;

  late ScrollController _controller;
  final LocalAuthentication _localAuthentication = LocalAuthentication();
  String _message = "Not Authorized";

  // late StreamSubscription<DataConnectionStatus> listener;
  // var InternetStatus = "Unknown";
  // var contentmessage = "Unknown";

  Future<bool> checkingForBioMetrics() async {
    bool canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
    print(canCheckBiometrics);
    return canCheckBiometrics;
  }

  Future<void> _authenticateMe() async {
    bool authenticated = false;
    try {
      authenticated = await _localAuthentication.authenticate(
        biometricOnly: true,
        localizedReason: "Authenticate",
        useErrorDialogs: true,
        stickyAuth: true,
      );
      setState(() {
        _message = authenticated ? "Authorized" : "Not Authorized";
      });
    } catch (e) {
      print(e);
    }
    if (!mounted) return;
  }

  void _firstLoad() async {
    setState(() {
      _isFirstLoadRunning = true;
    });
    try {
      final res =
          await http.get(Uri.parse("$_baseUrl?_page=$_page&_limit=$_limit"));
      setState(() {
        _repo = json.decode(res.body);
      });
    } catch (err) {
      print('Something went wrong');
    }

    setState(() {
      _isFirstLoadRunning = false;
    });
  }

  void _loadMore() async {
    if (_hasNextPage == true &&
        _isFirstLoadRunning == false &&
        _isLoadMoreRunning == false &&
        _controller.position.extentBefore < 8) {
     
      // tempRep = json.encode(_repo);
      // writeCounter(tempRep);

      setState(() {
        _isLoadMoreRunning = true; // Display a progress indicator at the bottom
      });
      _page += 1; // Increase _page by 1
      try {
        final res =
            await http.get(Uri.parse("$_baseUrl?_page=$_page&_limit=$_limit"));

        final List fetchedPosts = json.decode(res.body);
        if (fetchedPosts.length > 0) {
          setState(() {
            _repo.addAll(fetchedPosts);
          });
        } else {
          // This means there is no more data
          // and therefore, we will not send another GET request
          setState(() {
            _hasNextPage = false;
          });
        }
      } catch (err) {
        print('Something went wrong!');
      }

      setState(() {
        _isLoadMoreRunning = false;
      });
    }
  }

  void _showToast(String content) {
    Fluttertoast.showToast(
        msg: content,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.CENTER,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0);
  }

  // Future<String> get _localPath async {
  //   final directory = await getApplicationDocumentsDirectory();

  //   return directory.path;
  // }

  // Future<File> get _localFile async {
  //   final path = await _localPath;
  //   return File('$path/counter.txt');
  // }

  // Future<File> writeCounter(List content) async {
  //   final file = await _localFile;

  //   // Write the file
  //   return file.writeAsString('$content');
  // }

  // Future<List> readCounter() async {
  //   try {
  //     final file = await _localFile;

  //     // Read the file
  //     final contents = await file.readAsString();
  //     var temp;
  //     temp = json.decode(contents);
  //     _repo = temp;
  //     return temp;
  //   } catch (e) {
  //     // If encountering an error, return 0
  //     return [];
  //   }
  // }

  // checkConnection(BuildContext context) async {
  //   listener = DataConnectionChecker().onStatusChange.listen((status) {
  //     switch (status) {
  //       case DataConnectionStatus.connected:
  //         InternetStatus = "Connected to the Internet";
  //         contentmessage = "Connected to the Internet";

  //         break;
  //       case DataConnectionStatus.disconnected:
  //         InternetStatus = "You are disconnected to the Internet. ";
  //         contentmessage = "Please check your internet connection";
  //          _showToast(contentmessage);
  //         break;
  //     }
  //   });
  //   return await DataConnectionChecker().connectionStatus;
  // }

  @override
  void initState() {
    super.initState();

    checkingForBioMetrics();
    _authenticateMe();

    // readCounter();

    // checkConnection(context);

    _firstLoad();
    _controller = ScrollController()..addListener(_loadMore);
  }

  @override
  void dispose() {
    _controller.removeListener(_loadMore);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Jake's Git"),
      ),
      body: _isFirstLoadRunning
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _controller,
                    itemCount: _repo.length,
                    itemBuilder: (_, index) => Card(
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 10),
                      child: ListTile(
                          leading: const Icon(
                            Icons.book,
                            color: Colors.amber,
                            size: 40,
                          ),
                          title: Text(_repo[index]['name']),
                          subtitle: Column(
                            children: [
                              Text(_repo[index]['description']),
                              const SizedBox(
                                height: 5,
                              ),
                              Row(
                                children: [
                                  const Icon(Icons.arrow_back_ios_new_rounded),
                                  const Icon(Icons.arrow_forward_ios_rounded),
                                  Text(_repo[index]['language'] ?? ' '),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Icon(Icons.bug_report_rounded),
                                  Text(_repo[index]['open_issues_count']
                                      .toString()),
                                  const SizedBox(
                                    width: 8,
                                  ),
                                  const Icon(
                                      Icons.face_retouching_natural_rounded),
                                  Text(_repo[index]['watchers_count']
                                      .toString()),
                                ],
                              )
                            ],
                          )),
                    ),
                  ),
                ),

                // when the _loadMore function is running
                if (_isLoadMoreRunning == true)
                  const Padding(
                    padding: EdgeInsets.only(top: 10, bottom: 40),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),

                // When nothing else to load
                if (_hasNextPage == false)
                  Container(
                    padding: const EdgeInsets.only(top: 30, bottom: 40),
                    color: Colors.amber,
                    child: const Center(
                      child: Text(' No content'),
                    ),
                  ),
              ],
            ),
    );
  }
}
