import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async{
    await database.execute(
      """CREATE TABLE items(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      title TEXT,
      dueDate Text,
      createTime TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
      finishedTime Text,
      isDone Text
      )
      """
    );
  }

  static Future<sql.Database> db() async{
    return sql.openDatabase(
      "todoDB.db",
      version: 1,
      onCreate: (sql.Database database, int version) async {
        await createTables(database);
      }
    );
  }

  static Future<int> createItem(String title, String dueDate, String finishedTime) async{
    final db = await SQLHelper.db();
    final data = {
      'title': title, 'dueDate': dueDate,
      'finishedTime': finishedTime,
      'isDone' : "false"
    };
    final id = await db.insert(
        "items",
        data,
      conflictAlgorithm: sql.ConflictAlgorithm.replace
    );
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await SQLHelper.db();
    return db.query("items", orderBy: "isDone DESC, dueDate ASC, finishedTime ASC");
  }

  static Future<List<Map<String, dynamic>>> searchItem(String title) async{
    final db = await SQLHelper.db();
    return db.query("items", where: "title LIKE ?", whereArgs: ['%$title%']);
  }

  static Future<int> updateItem(int id, String title, String dueDate, String finishedTime) async {
    final db = await SQLHelper.db();
    final data = {'id' : id, 'title': title, 'dueDate':dueDate, 'finishedTime': finishedTime};
    final result = await db.update(
        "items", data,
        where: "id = ?", whereArgs: [id]);
    return result;
  }
  
  static Future<void> deleteItem(int id) async{
    final db = await SQLHelper.db();
    try{
      await db.delete("items", where: "id = ?", whereArgs: [id]);
    }
    catch (err){

    }
  }

  static Future<int> updateStatus(int id, String status)async {
    final db = await SQLHelper.db();
    final data = {'id':id, "isDone":status};
    final result = await db.update( "items", data,
        where: "id = ?", whereArgs: [id]);
    return result;
  }

}

