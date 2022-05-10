import 'package:flutter/material.dart';
import 'package:giphy/views/giphy_page_detail.dart';
import 'package:share/share.dart';
import 'package:transparent_image/transparent_image.dart';

import '../constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late String _search = '';
  int _offset = 0;

  _rowTextField() {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: TextField(
        decoration: const InputDecoration(
          labelText: "Pesquise aqui...",
          labelStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(),
        ),
        style: const TextStyle(color: Colors.black, fontSize: 18.0),
        textAlign: TextAlign.center,
        onSubmitted: (text) {
          setState(() {
            _offset = 0;
            _search = text;
          });
        },
      ),
    );
  }

  _rowProgress() {
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        strokeWidth: 5.0,
      ),
    );
  }

  _rowError() {
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      child: const Text("Erro :-("),
    );
  }

  _noResults() {
    return Container(
      width: 200,
      height: 200,
      alignment: Alignment.center,
      child: const Text(""),
    );
  }

  _rowGridView(BuildContext context, AsyncSnapshot? snapshot) {
    return GridView.builder(
        padding: const EdgeInsets.all(10.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10.0, mainAxisSpacing: 10.0
        ),
        itemCount: _getCount(snapshot!.data["data"]),
        itemBuilder: (context, index) {
          if(index < snapshot.data["data"].length) {
            return GestureDetector(
              child: FadeInImage.memoryNetwork(
                placeholder: kTransparentImage,
                image: snapshot.data["data"][index]["images"]["fixed_height"]["url"],
                height: 300,
                fit: BoxFit.cover,),
              onTap: () {
                //print("clicou");

                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            GiphyPageDetail(snapshot.data["data"][index])
                    )
                );
              },
              onLongPress: () {
                Share.share(snapshot.data["data"][index]["images"]["fixed_height"]["url"]);
              },
            );
          } else {
            return TextButton(
              child: const Text("Carregar mais..."),
              onPressed: () {
                setState(() {
                  _offset += 19;
                });
              },
            );
          }
        }
    );
  }

  int _getCount(List? data) {
    if(_search.isEmpty) {
      return data!.length;
    } else {
      return data!.length + 1;
    }
  }

  _rowFutureBuilder(BuildContext context) {
    return Expanded(
        child: FutureBuilder(
          future: _fetchGifs(),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
              case ConnectionState.none:
                return _rowProgress();
              case ConnectionState.done:
              case ConnectionState.active:
              default:
                if (snapshot.hasData) {
                  return _rowGridView(context, snapshot);
                } else if (snapshot.hasError) {
                  return _rowError();
                } else {
                  return _noResults();
                }
            }
          },
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Giphy'),
      ),
      body: Column(
        children: <Widget>[
          _rowTextField(),
          _rowFutureBuilder(context)
        ],
      ),
    );
  }

  Future<Map> _fetchGifs() async {
    Map? result;

    var urlSearch = Uri.https(
        Constant.BASE_URL,
        Constant.BASE_VERSION+Constant.BASE_GIFS+Constant.BASE_SEARCH_ENDPOINT,
        {
          'api_key' : Constant.API_TOKEN,
          'q' : _search,
          'limit' : '19',
          'offset' : '$_offset',
          'rating' : 'G',
          'lang' : 'en'
        }
    );

    var urlTrending = Uri.https(
        Constant.BASE_URL,
        Constant.BASE_VERSION+Constant.BASE_GIFS+Constant.BASE_TRENDING_ENDPOINT,
        {'api_key' : Constant.API_TOKEN});

    http.Response response;
    if(_search.isEmpty) {
      response = await http.Client().get(urlTrending);
    } else {
      response = await http.Client().get(urlSearch);
    }

    try {
      result = json.decode(response.body);
    } on Exception catch (_, ex) {
      result = ex.toString() as Map;
    }

    return result!;
  }
}