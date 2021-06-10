import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dataStore.dart' as dataStore;

class JsonReqRes extends StatefulWidget {
  @override
  _JsonReqRes createState() => _JsonReqRes();
}

class _JsonReqRes extends State<JsonReqRes> {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 350,
      height: 650,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text("Request"),
                IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        dataStore.jsonReqStack = "";
                      });

                      //Clipboard.setData(ClipboardData(text: dataStore.jsonReq));
                    })
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                constraints: BoxConstraints(
                  minHeight: 150,
                  minWidth: 250,
                ),
                color: Colors.white,
                child: SelectableText(
                  dataStore.jsonReqStack,
                  style: new TextStyle(
                    fontSize: 16.0,
                    color: Colors.black,
                  ),
                ),
              ),
            ),
          ),
          Spacer(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text("Response"),
                IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        dataStore.jsonResStack = "";
                      });
                    })
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Container(
                color: Colors.white,
                child: Container(
                  constraints: BoxConstraints(
                    minHeight: 150,
                    minWidth: 250,
                  ),
                  child: SelectableText(
                    dataStore.jsonResStack,
                    style: new TextStyle(
                      fontSize: 16.0,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
