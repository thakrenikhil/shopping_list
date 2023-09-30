import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shopping_list/data/categories.dart';
import 'package:shopping_list/model/grocery_items.dart';
import 'package:shopping_list/widget/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});
  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadItem();
  }

  List<GroceryItem> _groceryItem = [];
  var isLoading = true;
  void loadItem() async {
    final url =
        Uri.https('shoplis-default-rtdb.firebaseio.com', 'shopping-list.json');
    final reponse = await http.get(url);
    if (reponse.body == 'null') {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(reponse.body);
    final List<GroceryItem> loadedlist = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedlist.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    setState(() {
      _groceryItem = loadedlist;
      isLoading = false;
    });
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
        MaterialPageRoute(builder: (ctx) => const NewItem()));
    if (newItem == null) {
      return;
    }
    setState(() {
      _groceryItem.add(newItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItem.indexOf(item);
    final url = Uri.https(
        'shoplis-default-rtdb.firebaseio.com', 'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    setState(() {
      _groceryItem.remove(item);
    });
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItem.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget maincontent = const Center(
      child: Text('You have an empty list'),
    );
    if (isLoading) {
      maincontent = const Center(
        child: CircularProgressIndicator(
            color: Colors.orangeAccent, backgroundColor: Colors.white),
      );
    }
    if (_groceryItem.isNotEmpty) {
      maincontent = ListView.builder(
        itemCount: _groceryItem.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItem[index]);
          },
          key: ValueKey(_groceryItem[index].id),
          child: ListTile(
            title: Text(_groceryItem[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: _groceryItem[index].category.color,
            ),
            trailing: Text(_groceryItem[index].quantity.toString()),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: maincontent,
    );
  }
}
