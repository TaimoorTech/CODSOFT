import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quote_app/sqlHelper.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share/share.dart';
import 'package:toast/toast.dart';


enum _MenuValues{
  copy,
  share,
  remove
}

class favScreen extends StatefulWidget {
  const favScreen({Key? key}) : super(key: key);

  @override
  State<favScreen> createState() => _favScreenState();
}


class _favScreenState extends State<favScreen> {

  List <Map<String, dynamic>> _favourites = [];
  late ScreenshotController screenshotController;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _refreshList();
    screenshotController = ScreenshotController();
  }



  void _refreshList() async {
    final data = await SQLHelper.getAllItems();
    setState(() {
      _favourites = data;
      _favourites = _favourites.reversed.toList();
    });
  }

  Future<void> _deleteItem(String quote) async {
    await SQLHelper.deleteItem(quote);
    SnackBar snackBar = SnackBar(
      content: Text("Remove from Favourites..."),
      elevation: 5,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    setState(() {
      _refreshList();
    });
  }

  copyQuote(String quote, String owner) {
    ClipboardManager.copyToClipBoard(quote + "\n-" + owner)
        .then((result) {
      Toast.show("Quote Copied", context, duration: Toast.LENGTH_SHORT);
    });
  }

  shareQuote(String quote) async {
    final directory = (await getApplicationDocumentsDirectory()).path;
    String path = '$directory/Screenshots${DateTime.now().toIso8601String()}.png';
    screenshotController.capture(path: path)
        .then((value) {
      Share.shareFiles([path], text: quote);
    }).catchError((onError){
      print(onError);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_sharp, color: Colors.blue),
              onPressed: () => {
                Navigator.pop(context)
              },
            ),
            title: Text("Favourites", textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 20)),
            centerTitle: true,
            elevation: 0,
          ),
          body: Screenshot(
            controller: screenshotController,
            child: Container(
              margin: EdgeInsets.only(top: 30),
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 10),
                  showlist()
                ],
              ),
            ),
          ),
        )
    );
  }

  ImageProvider drawImg(String imglink) {
    if(imglink.isEmpty){
      return AssetImage("img/offline.jpg");
    }else {
      return  NetworkImage(imglink);
    }
  }



  Widget showlist(){
    return Expanded(
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: _favourites.length,
            itemBuilder: (context, index) => Card (
              elevation: 5,
              margin: EdgeInsets.only(top:30, bottom: 120),
              child: Container(
                height: 580,
                padding: EdgeInsets.all(10),
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue, width: 4),
                  image: DecorationImage(
                    opacity: 30,
                    fit: BoxFit.cover,
                    image: drawImg(_favourites[index]['imglink']),
                  ),
                ),
                child: ListTile(
                  trailing: PopupMenuButton<_MenuValues>(
                    constraints: BoxConstraints.expand(width: 170, height: 150),
                    icon: Icon(Icons.menu_sharp, color: Colors.blue,),
                    position: PopupMenuPosition.over,
                    color: Colors.white,
                    itemBuilder: (BuildContext context)=>[
                      PopupMenuItem(
                          child: RichText(
                              text: TextSpan(
                                  children: [
                                    TextSpan(text: 'Copy',
                                        style: TextStyle(color: Colors.blue, fontSize: 20,
                                            fontWeight: FontWeight.bold)),
                                    WidgetSpan(
                                      child: SizedBox(width: 70),
                                    ),
                                    WidgetSpan(
                                      child: Icon(Icons.copy_sharp, size: 20,
                                          color: Colors.blue),
                                    ),
                                  ]
                              )
                          ),
                        value: _MenuValues.copy,
                        onTap: () => {
                          copyQuote(_favourites[index]['quote'],
                              _favourites[index]['owner'])
                        },
                      ),
                      PopupMenuItem(
                        child: RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'Share',
                                      style: TextStyle(color: Colors.blue, fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  WidgetSpan(
                                    child: SizedBox(width: 65),
                                  ),
                                  WidgetSpan(
                                    child: Icon(Icons.share_sharp, size: 20,
                                        color: Colors.blue),
                                  ),
                                ]
                            )
                        ),
                        value: _MenuValues.share,
                        onTap:(){ shareQuote(_favourites[index]['quote']);}
                      ),
                      PopupMenuItem(
                        child: RichText(
                            text: TextSpan(
                                children: [
                                  TextSpan(text: 'Remove',
                                      style: TextStyle(color: Colors.blue, fontSize: 20,
                                          fontWeight: FontWeight.bold)),
                                  WidgetSpan(
                                    child: SizedBox(width: 45),
                                  ),
                                  WidgetSpan(
                                    child: Icon(Icons.delete_sharp, size: 20,
                                        color: Colors.blue),
                                  ),
                                ]
                            )
                        ),
                        value: _MenuValues.remove,
                        onTap: () => {
                          _deleteItem(_favourites[index]['quote'])
                        },
                      )
                    ],
                  ),
                  title: Text(_favourites[index]['quote'],
                      style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.bold, fontSize: 18)),
                  subtitle: Text("\n"+"~ "+_favourites[index]['owner'],
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 18)),
                ),
              ),
            )
        )
    );
  }
}
