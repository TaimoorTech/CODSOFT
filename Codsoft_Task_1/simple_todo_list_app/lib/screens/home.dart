import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:simple_todo_list_app/sqlite_files/sql_helper.dart';
import 'package:intl/intl.dart' as intl;


class home extends StatefulWidget {
  const home({Key? key}) : super(key: key);

  @override
  State<home> createState() => _homeState();
}

class _homeState extends State<home> {

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _finishedTimeController = TextEditingController();
  final TextEditingController _searchBarController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();

  List <Map<String, dynamic>> _listOfWorks = [];
  List <Map<String, dynamic>> _changedlist = [];
  bool _isLoading = true;
  bool isChecked = false;


  void _refreshList() async {
    final data = await SQLHelper.getAllItems();
    setState(() {
      _listOfWorks = data;
      _changedlist = data;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _refreshList();
  }


  void display_message(String message){
    Fluttertoast.showToast(
        msg: message,
        textColor: Colors.black,
        fontSize: 15,
        timeInSecForIosWeb: 2,
        backgroundColor: Colors.blue,
        gravity: ToastGravity.BOTTOM,
        toastLength: Toast.LENGTH_LONG);
  }

  Future<void> _addItem(String searchValue) async {
    await SQLHelper.createItem(
        _titleController.text.toString(),
        _dueDateController.text.toString(),
        _finishedTimeController.text.toString()
    );
    SnackBar snackBar = SnackBar(
        content: Text("Work has been listed..."),
      elevation: 5,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _refreshList();
    _runFilter(searchValue);
  }

  Future<void> _updateItem(int id, String searchValue) async {
    await SQLHelper.updateItem(
        id,  _titleController.text.toString(),
        _dueDateController.text.toString(),
        _finishedTimeController.text.toString()
    );
    SnackBar snackBar = SnackBar(
      content: Text("Work has been Updated..."),
      elevation: 5,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _refreshList();
    _runFilter(searchValue);
  }

  Future<void> _updateStatus(int id, String searchValue, String status) async{
    await SQLHelper.updateStatus(id, status);
    _refreshList();
    _runFilter(searchValue);
  }

  Future<void> _deleteItem(int id, String searchValue) async {
    await SQLHelper.deleteItem(id);
    SnackBar snackBar = SnackBar(
      content: Text("Work has been deleted..."),
      elevation: 5,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
    _refreshList();
    _runFilter(searchValue);

  }
  
  void _showForm(int? id) async {

    if(id != null){
      final existingItem = _listOfWorks
          .firstWhere((element) => element['id'] == id);
      _titleController.text = existingItem['title'];
      _dueDateController.text = existingItem['dueDate'];
      _finishedTimeController.text = existingItem['finishedTime'];

    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
          padding: EdgeInsets.only(top: 15, left: 15, right: 15,
              bottom: MediaQuery.of(context).viewInsets.bottom+85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: "Title", hintText: "Title"),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _dueDateController,
                decoration: const InputDecoration(
                  labelText: "Due Date",
                  suffixIconColor: Colors.black,
                  suffixIcon: Icon(Icons.calendar_today_rounded),
                    hintText: "Due Date"),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100)
                    );
                    if(pickedDate != null) {
                      setState(() {
                        _dueDateController.text = intl.DateFormat("dd-MM-yyyy").format(pickedDate);
                      });
                    }
                  },
              ),
              SizedBox(height: 20),
              TextField(
                controller: _finishedTimeController,
                decoration: const InputDecoration(
                  suffixIconColor: Colors.black,
                    suffixIcon: Icon(Icons.timelapse_rounded),
                    labelText: "Finished Time", hintText: "Finished Time"),
                onTap: () async {
                  TimeOfDay? pickedTime = await showTimePicker(
                      context: context, initialTime: TimeOfDay.now(),
                    builder: (BuildContext context, Widget? child) {
                      return MediaQuery(
                        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                        child: child!,
                      );
                    },
                  );
                  if(pickedTime != null){
                    final localizations = MaterialLocalizations.of(context);
                    String formattedTime = localizations.formatTimeOfDay(pickedTime, alwaysUse24HourFormat: true);
                    _finishedTimeController.text = formattedTime;
                  }
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                  onPressed: () async {
                      if (id == null) {
                        await _addItem(_searchBarController.text.trim());
                      }
                      if (id != null){
                        await _updateItem(id, _searchBarController.text.trim());
                      }
                      _titleController.text='';
                      _dueDateController.text='';
                      _finishedTimeController.text='';

                      Navigator.of(context).pop();
                  },
                  child: Text(id == null ? 'Create New' : 'Update')
              )

            ],
          ),
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
         backgroundColor: Colors.white,
          appBar: AppBar(
            elevation: 5,
            title: Text("ToDo List App"),
            centerTitle: true,
          ),
          floatingActionButton: FloatingActionButton(
              onPressed: (){
                _showForm(null);
              },
              child: Icon(
                Icons.add
              ),
          ),
          body: Container(
            margin: EdgeInsets.only(top: 30),
            padding: EdgeInsets.symmetric(horizontal: 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                searchBar(),
                SizedBox(height: 30),
                Text("All Tasks", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),),
                SizedBox(height: 30),
                showList(_listOfWorks)

              ],
            ),
          ),
      ),
    );
  }


  Widget showList( List <Map<String, dynamic>> _listOfWorks) {
    return Expanded(
      // height: MediaQuery. of(context). size. height-230,
      child: ListView.builder(
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
          itemCount: _changedlist.length,
          itemBuilder: (context, index) => Card(
            shape: StadiumBorder(side: BorderSide(color: Colors.blue, width: 2.6)),
            elevation: 15,
            color: Colors.white,
            margin: EdgeInsets.only(bottom: 40),
            child: ListTile(
              leading: Checkbox(
                  value: toBoolean(_changedlist[index]['isDone']),
                  onChanged: (val)  {
                    setState(() {
                      // _changedlist[index]['isDone'] = val!;
                      if(val==true){
                        _updateStatus(
                            _changedlist[index]['id'],
                            _searchBarController.text,
                            "true"
                        );
                        _refreshList();
                        _runFilter(_searchBarController.text.trim());
                      }
                      else{
                        _updateStatus(
                            _changedlist[index]['id'],
                            _searchBarController.text,
                            "false"
                        );
                        _refreshList();
                        _runFilter(_searchBarController.text.trim());
                      }
                    });
                  }
              ),
              title: Text(_changedlist[index]['title'],
                style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                  "Due Date : "+_changedlist[index]['dueDate']+"\n"
                      +"Finished Time : "+_changedlist[index]['finishedTime'],
                style: TextStyle(color: Colors.black),
              ),
              trailing: SizedBox(
                width: 114,
                child:  Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if(_changedlist[index]['isDone']=='true')...[
                      RichText(
                          text: TextSpan(
                              children: [
                                WidgetSpan(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                    child: Icon(Icons.check_circle_rounded, size: 15,
                                        color: Colors.green),
                                  ),
                                ),
                                TextSpan(text: 'Completed',
                                    style: TextStyle(color: Colors.green,
                                        fontWeight: FontWeight.bold)),
                              ]
                          )
                      ),
                    ]else if((_changedlist[index]['isDone']=='false')&&
                    (DateFormat('dd-MM-yyyy').parse(_changedlist[index]['dueDate']).isBefore(DateTime.now()))
                        && (DateFormat('hh:mm').parse(_changedlist[index]['finishedTime']).hour<=DateTime.now().hour
                        && DateFormat('hh:mm').parse(_changedlist[index]['finishedTime']).minute<=DateTime.now().minute)
                    )...[
                      RichText(
                          text: TextSpan(
                         children: [
                           WidgetSpan(
                             child: Padding(
                               padding: const EdgeInsets.symmetric(horizontal: 2.0),
                               child: Icon(Icons.close_rounded,
                                   color: Colors.red, size: 15),
                             ),
                           ),
                           TextSpan(text: 'Not Completed',
                               style: TextStyle(color: Colors.red,
                                   fontWeight: FontWeight.bold)),
                         ]
                      )
                      ),
                    ] else...[
                      RichText(text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                                child: Icon(Icons.circle, size: 15,
                                    color: Colors.green),
                              ),
                            ),
                            TextSpan(text: 'Active',
                                style: TextStyle(color: Colors.green,
                                    fontWeight: FontWeight.bold)),
                          ]
                      )
                      ),
                    ],
                    SizedBox(
                      height: 30,
                      child: Row(
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            color: Colors.black,
                              onPressed: () => _showForm(_changedlist[index]['id']),
                              icon: Icon(Icons.edit)
                          ),
                          IconButton(
                            color: Colors.black,
                              onPressed: () => _deleteItem(_changedlist[index]['id'], _searchBarController.text.trim()),
                              icon: Icon(Icons.delete)
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ),

            ),
          )
      ),
    );
  }

  void _runFilter(String value) async {
    List <Map<String, dynamic>> result = [];
    if(value.isEmpty){
      result = _listOfWorks;
    }
    else{
      result = await SQLHelper.searchItem(value);
    }
    setState(() {
      _changedlist = result;
    });
  }

  Widget searchBar() {
    return Container(
      height: 44,
      padding: EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(16)
      ),
      child:  TextField(//Search Bar
        style: TextStyle(color: Colors.white,
            fontSize: 19),
        controller: _searchBarController,
        onChanged: (value) => {
          _runFilter(value.trim())
        },
        onTapOutside: (event){
          FocusManager.instance.primaryFocus?.unfocus();
        },
        cursorWidth: 2,
        cursorHeight: 20,
        cursorColor: Colors.white,
        decoration: InputDecoration(
            prefixIcon: Icon(
              Icons.search_sharp,
              color: Colors.white,
              size: 19,
            ),
            border: InputBorder.none,
            hintText: "Search Task",
            hintStyle: TextStyle(
              color: Colors.white,
              fontSize: 19
            )
        ),
      ),
    );
  }

  bool toBoolean(String status) {
    if (status.toLowerCase() == "true") {
      return true;
    } else {
      return false;
    }
  }

}

