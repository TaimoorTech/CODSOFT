import 'dart:convert';
import 'dart:ffi';

import 'package:clipboard_manager/clipboard_manager.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quote_app/favScreen.dart';
import 'package:quote_app/sqlHelper.dart';
import 'package:screenshot/screenshot.dart';
import 'package:http/http.dart' as http;
import 'package:share/share.dart';
import 'package:toast/toast.dart';

class homePage extends StatefulWidget {
  const homePage({Key? key}) : super(key: key);

  @override
  State<homePage> createState() => _homePageState();
}

class _homePageState extends State<homePage> {
  List <Map<String, dynamic>> _favourites = [];
  late String quote, owner, imglink;
  bool working = false;
  final grey = Colors.blueGrey;
  late ScreenshotController screenshotController;
  late String checking;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _refreshList();
    screenshotController = ScreenshotController();
    quote = "";
    owner = "";
    imglink = "";
    checking="";
    getQuote();
    initialcheckFavourites();
  }

  void _refreshList() async {
    final data = await SQLHelper.getAllItems();
    setState(() {
      _favourites = data;
    });
  }

  Future<void> _addItem() async {
    await SQLHelper.createItem(
        quote,
        owner,
        imglink
    );
    SnackBar snackBar = SnackBar(
      content: Text("Added to Favourites..."),
      elevation: 5,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _refreshList();
    setState(() {
      checking="true";
    });
  }

  Future<void> _deleteItem() async {
    await SQLHelper.deleteItem(quote);
    SnackBar snackBar = SnackBar(
      content: Text("Remove from Favourites..."),
      elevation: 5,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _refreshList();
    setState(() {
      checking="false";
    });
  }

  getQuote() async {
    try{
      setState(() {
        working = true;
        quote=owner=imglink="";
      });
      var response = await http.post(
        Uri.encodeFull('http://api.forismatic.com/api/1.0/'),
        body: {"method": "getQuote", "format": "json", "lang": "en"}
      );
      setState(() {
        try{
          var res = jsonDecode(response.body);
          owner = res["quoteAuthor"].toString().trim();
          quote = res["quoteText"].toString().replaceAll("â", " ");
          getImg(owner);
        }catch (e) {getQuote();}
      });
      initialcheckFavourites();
    } catch (e) {offline();}
  }

  offline(){
    setState(() {
      owner="Janet Fitch";
      imglink="";
      quote="The pheonix must burn to emerge";
      working=false;
    });
  }

  copyQuote() {
    ClipboardManager.copyToClipBoard(quote + "\n-" + owner)
        .then((result) {
          Toast.show("Quote Copied", context, duration: Toast.LENGTH_SHORT);
    });
  }

  shareQuote() async {
    final directory = (await getApplicationDocumentsDirectory()).path;
    String path = '$directory/Screenshots${DateTime.now().toIso8601String()}.png';
    screenshotController.capture(path: path)
        .then((value) {
          Share.shareFiles([path], text: quote);
    }).catchError((onError){
      print(onError);
    });
  }

  getImg(String name) async {
    var image = await http.get(
        "https://en.wikipedia.org/w/api.php?action=query&generator=search&gsrlimit=1&prop=pageimages%7Cextracts&pithumbsize=400&gsrsearch=" +
            name +
            "&format=json");
    setState(() {
      try{
        var res = jsonDecode(image.body) ["query"] ["pages"];
        res = res[res.keys.first];
        imglink = res["thumbnail"] ["source"];
      }catch (e) {
        imglink = "";
      }
      working=false;

    });
  }

  Widget drawImg() {
    if(imglink.isEmpty){
      return Image.asset("img/offline.jpg", fit: BoxFit.cover);
    }else {
      return Image.network(imglink, fit: BoxFit.cover);
    }
  }

  void initialcheckFavourites() async {
    final data = await SQLHelper.searchItem(quote);
    setState(() {
      if(data.isNotEmpty){
        checking="true";
      }
      else{
        checking="false";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey,
        body: Screenshot(
          controller: screenshotController,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: <Widget> [
              drawImg(),
              Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.6, 1],
                      colors: [
                        Colors.grey.withAlpha(70),
                        Colors.grey.withAlpha(220),
                        Colors.grey.withAlpha(225),
                      ]
                  )
                ),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 150),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          text: quote != null ? '“': "",
                          style: TextStyle(
                            fontFamily: "Ic",
                            color: Colors.blue,
                            fontWeight: FontWeight.w700,
                            fontSize: 30
                          ),
                          children: [
                            TextSpan(
                              text: quote != null ? quote: "",
                              style: TextStyle(
                                  fontFamily: "Ic",
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 22
                              )),
                            TextSpan(
                                text: quote != null ? '”': "",
                                style: TextStyle(
                                    fontFamily: "Ic",
                                    color: Colors.blue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 30
                                )
                            ),
                          ]),
                    ),
                    Text(owner.isEmpty ? "" : "\n" + owner,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: "Ic",
                        color: Colors.white,
                        fontSize: 18),)
                  ])),
              AppBar(
                title: Text("Quote of the Day",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                actions: [
                  IconButton(
                      onPressed: ()=>{
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) => favScreen())).
                        then((_) {
                          setState(() {
                            initialcheckFavourites();
                          });
                        })
                      },
                      icon: Icon(Icons.favorite_sharp, color: Colors.blue))
                ],
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
              )
            ]),
        ),
        floatingActionButton: Padding(
          padding: EdgeInsets.symmetric(vertical: 50),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget> [
              InkWell(
                onTap: !working ? getQuote : null,
                child: Icon(Icons.refresh_sharp, size: 30, color: Colors.white),
              ),
              InkWell(
                onTap: quote.isNotEmpty ? copyQuote : null,
                child: Icon(Icons.copy_sharp, size: 28, color: Colors.white),
              ),
              InkWell(
                onTap: quote.isNotEmpty ? shareQuote : null,
                child: Icon(Icons.share_sharp, size: 30, color: Colors.white),
              ),
              InkWell(
                onTap: (checking=="false") ? _addItem : _deleteItem,
                child: (checking=="true") ? Icon(Icons.favorite_sharp, size: 30, color: Colors.blue)
                    : Icon(Icons.favorite_outline_rounded, size: 30, color: Colors.white),
              ),
            ],
          ),
        ),
    );
  }
}

