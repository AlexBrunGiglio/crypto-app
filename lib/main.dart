import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'dart:core';
import 'package:http/http.dart' as http;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Price List',
      theme: new ThemeData(
          primaryColor: Colors.orange,
          appBarTheme: new AppBarTheme(backgroundColor: Colors.black)),
      home: CryptoList(),
    );
  }
}

class CryptoList extends StatefulWidget {
  @override
  CryptoListState createState() => CryptoListState();
}

class CryptoListState extends State {
  List _cryptoList = [];
  final _saved = Set();
  final _boldStyle = new TextStyle(fontWeight: FontWeight.bold);
  bool _loading = false;
  final List _colors = [
    //to show different colors for different cryptos
    Colors.blue,
    Colors.indigo,
    Colors.lime,
    Colors.teal,
    Colors.cyan
  ];

  Future getCryptoPrices() async {
    print('getting crypto prices');
    Uri _apiURL = Uri.https(
        "pro-api.coinmarketcap.com", "v1/cryptocurrency/listings/latest");
    Map<String, String> userHeader = {
      "Content-type": "application/json",
      "Accept": "application/json",
      "X-CMC_PRO_API_KEY": "3427df36-b57c-41ba-864e-eaa223003403"
    };
    setState(() {
      this._loading = true; //before calling the api, set the loading to true
    });
    http.Response response = await http.get(_apiURL, headers: userHeader);
    setState(() {
      try {
        Map<String, dynamic> map = json.decode(response.body);
        List<dynamic> data = map["data"];
        this._cryptoList = data;
        print(_cryptoList);
        this._loading = false;
      } catch (e) {
        print(e);
      }
    });
    return;
  }

  CircleAvatar _getLeadingWidget(String name, MaterialColor color) {
    return new CircleAvatar(
      backgroundColor: color,
      child: new Text(name[0]),
    );
  }

  _getMainBody() {
    if (_loading) {
      return new Center(
        child: new CircularProgressIndicator(),
      );
    } else {
      return new RefreshIndicator(
        child: _buildCryptoList(),
        onRefresh: getCryptoPrices,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    getCryptoPrices();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('CryptoList'),
          actions: [
            new IconButton(icon: const Icon(Icons.list), onPressed: _pushSaved),
          ],
        ),
        body: _getMainBody());
  }

  void _pushSaved() {
    Navigator.of(context).push(
      //get the current navigator
      new MaterialPageRoute(
        //A modal route that replaces the entire screen with a platform-adaptive transition.
        builder: (BuildContext context) {
          final Iterable<Widget> tiles = _saved.map(
            //iterate through our saved cryptocurrencies sequentially
            (crypto) {
              return new ListTile(
                //same list tile as what we have shown in the previous page
                leading: _getLeadingWidget(crypto['name'], Colors.blue),
                title: Text(crypto['name']),
                subtitle: Text(
                  crypto["quote"]["USD"]["price"].toString(),
                  style: _boldStyle,
                ),
              );
            },
          );
          final List<Widget> divided = ListTile.divideTiles(
            //divided tiles allows to insert the dividers for visually pleasing outcome
            context: context,
            tiles: tiles,
          ).toList();
          return new Scaffold(
            //return a new scaffold with a new appbar and listview as a body
            appBar: new AppBar(
              title: const Text('Saved Cryptos'),
            ),
            body: new ListView(children: divided),
          );
        },
      ),
    );
  }

  Widget _buildCryptoList() {
    return ListView.builder(
        itemCount: _cryptoList
            .length, //set the item count so that index won't be out of range
        padding:
            const EdgeInsets.all(16.0), //add some padding to make it look good
        itemBuilder: (context, i) {
          //item builder returns a row for each index i=0,1,2,3,4
          // if (i.isOdd) return Divider(); //if index = 1,3,5 ... return a divider to make it visually appealing

          // final index = i ~/ 2; //get the actual index excluding dividers.
          final index = i;
          print(index);
          final MaterialColor color = _colors[index %
              _colors.length]; //iterate through indexes and get the next colour
          return _buildRow(_cryptoList[index], color); //build the row widget
        });
  }

  Widget _buildRow(Map crypto, MaterialColor color) {
    // if _saved contains our crypto, return true
    final bool favourited = _saved.contains(crypto);

    // function to handle when heart icon is tapped
    void _fav() {
      setState(() {
        if (favourited) {
          //if it is favourited previously, remove it from the list
          _saved.remove(crypto);
        } else {
          _saved.add(crypto); //else add it to the array
        }
      });
    }

    String price = crypto["quote"]["USD"]["price"].toString() + '\$';
    return ListTile(
      leading: _getLeadingWidget(crypto['name'],
          color), // get the first letter of each crypto with the color
      title: Text(crypto['name']), //title to be name of the crypto
      subtitle: Text(
        //subtitle is below title, get the price in 2 decimal places and set style to bold
        price,
        style: _boldStyle,
      ),
      trailing: new IconButton(
        //at the end of the row, add an icon button
        // Add the lines from here...
        icon: Icon(favourited
            ? Icons.favorite
            : Icons
                .favorite_border), // if button is favourited, show favourite icon
        color:
            favourited ? Colors.red : null, // if button is favourited, show red
        onPressed: _fav, //when pressed, let _fav function handle
      ),
    );
  }
}
