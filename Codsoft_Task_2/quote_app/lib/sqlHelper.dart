import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sql;

class SQLHelper {
  static Future<void> createTables(sql.Database database) async{
    await database.execute(
        """CREATE TABLE items(
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      quote Text,
      owner Text,
      imglink Text
      )
      """
    );
  }

  static Future<sql.Database> db() async{
    return sql.openDatabase(
        "quotes.db",
        version: 1,
        onCreate: (sql.Database database, int version) async {
          await createTables(database);
        }
    );
  }

  static Future<int> createItem(String quote, String owner, String imglink) async{
    final db = await SQLHelper.db();
    final data = {
      'quote': quote, 'owner': owner,
      'imglink': imglink
    };
    final id = await db.insert(
        "items",
        data
    );
    return id;
  }

  static Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await SQLHelper.db();
    return db.query("items");
  }




  static Future<void> deleteItem(String quote) async{
    final db = await SQLHelper.db();
    try{
      await db.delete("items", where: "quote = ?", whereArgs: [quote]);
    }
    catch (err){

    }
  }

  static Future<List<Map<String, dynamic>>> searchItem(String quote) async{
    final db = await SQLHelper.db();
    return db.query("items", where: "quote = ?", whereArgs: [quote]);
  }
}

