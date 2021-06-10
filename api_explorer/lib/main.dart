import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:api_explorer/runPatternCommand.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter/material.dart';
import "dataStore.dart" as dataStore;

import 'jsonReqRes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Jellyfish Lighting API Explorer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Jellyfish Lighting API Explorer'),
    );
  }
}

class Pattern {
  Pattern({
    this.categoryName,
    this.name,
    this.readOnly,
    this.jsonData,
  });

  String categoryName;
  String name;
  bool readOnly;
  Map<String, dynamic> jsonData;

  factory Pattern.fromJson(Map<String, dynamic> json) => Pattern(
      categoryName: json["folders"],
      name: json["name"],
      readOnly: json["readOnly"],
      jsonData: json['jsonData']);
}

class PatternListCommandResponse {
  PatternListCommandResponse({
    this.cmd,
    this.patternList,
  });

  String cmd;
  List<Pattern> patternList;

  factory PatternListCommandResponse.fromJson(Map<String, dynamic> json) =>
      PatternListCommandResponse(
        cmd: json["cmd"],
        patternList: List<Pattern>.from(
            json["patternFileList"].map((x) => Pattern.fromJson(x))),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  IOWebSocketChannel channel;
  var _webSocketURL = "";

  String _jsonResponse = "";
  String _jsonRequest = "";

  var jsonRequest = "";
  var jsonResponse = "";

  final myController = TextEditingController(text: ""); //"192.168.1.77");

  var buttonsDisabled = true;

  var isBrightnessDecrementButtonDisabled = true;
  var isBrightnessIncrementButtonDisabled = true;
  var isSpeedIncrementButtonDisabled = true;
  var isSpeedDecrementButtonDisabled = true;
  var brightnessLevel = 75;
  var speed = 10;

  bool isOn = false;
  List<String> zoneList = [];
  List<String> selectedZones = [];
  Map<String, dynamic> zones = Map();
  Map<String, dynamic> _commandResponse = Map();
  Map<String, dynamic> commandResponse2 = Map();

  Map<String, List<String>> commResMap = Map();
  List<String> categoriesList = [];

  PatternListCommandResponse commRes = PatternListCommandResponse();

  Pattern cachedPattern = Pattern();

//Helper Methods//

  Future sendCommand2(String command, Function cbHandler) async {
    WebSocket ws;
    try {
      ws = await WebSocket.connect(_webSocketURL);
      channel = IOWebSocketChannel(ws);
      channel.sink.add(command);
      channel.stream.listen((message) {
        setState(() {
          jsonResponse = message.toString();
          jsonRequest = command;
          dataStore.jsonReq = command;
          dataStore.jsonReqStack += "\n" + "\n" + command;
          dataStore.jsonRes = message;
          dataStore.jsonResStack += "\n" + "\n" + message;

          commandResponse2 = jsonDecode(message);

          if (cbHandler != null) {
            cbHandler(jsonDecode(message));
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> getPatternJsonData(String category, String fileName) async {
    String command = '{"cmd":"toCtlrGet", "get":[["patternFileData", "' +
        category +
        "\", \"" +
        fileName +
        "\"]] }";
    sendCommand2(command, (commandResponse) {
      setState(() {
        cachedPattern.jsonData = commandResponse["patternFileData"];
      });
    });
  }

  String generateRunPatternCommand(
      String category, String pattern, List<String> zonesParam, bool turnOn) {
    String runPatternCommand =
        "{\"cmd\":\"toCtlrSet\",\"runPattern\":{\"file\":\"" +
            category +
            "/" +
            pattern;
    if (turnOn) {
      runPatternCommand +=
          "\",\"data\":\"\",\"id\":\"\",\"state\":1,\"zoneName\":[";
    } else {
      runPatternCommand +=
          "\",\"data\":\"\",\"id\":\"\",\"state\":0,\"zoneName\":[";
    }

    if ((selectedZones != null) && (selectedZones.length != 0)) {
      for (int i = 0; i < selectedZones.length; i++) {
        if (i == selectedZones.length - 1) {
          runPatternCommand += "\"" + selectedZones[i] + "\"";
        } else {
          runPatternCommand += "\"" + selectedZones[i] + "\", ";
        }
      }
    } else {
      zones.keys.forEach((element) {
        if (element == zones.keys.last) {
          runPatternCommand += '\"' + element + '\"';
        } else {
          runPatternCommand += '\"' + element + '\", ';
        }
      });
    }
    runPatternCommand += "]}}";
    return runPatternCommand;
  }

  Future<dynamic> getZones() {
    String command = generateCommand("toCtlrGet", "zones");
    sendCommand2(command, (_commandResponse) {
      setState(() {
        zones = _commandResponse['zones'];
        zoneList = zones.keys.toList();
        selectedZones = [...zoneList];
      });
    });
  }

  String adjustmentCommand(int brightnessVal, int speed) {
    Map<String, dynamic> temp = cachedPattern.jsonData;

    var jsonData = jsonDecode(temp["jsonData"]);

    var runData = jsonData["runData"];
    runData["brightness"] = brightnessVal;
    runData["speed"] = speed;
    jsonData['runData'] = runData;
    String comm = configAdjustString(jsonData);
    sendCommand2(comm, null);

    return comm;
  }

  void sendCommand(String command) async {
    WebSocket ws;
    try {
      ws = await WebSocket.connect(_webSocketURL);
      channel = IOWebSocketChannel(ws);
      channel.sink.add(command);

      channel.stream.listen((message) {
        if (message == null) {
          channel.stream.listen((message) {});
        }

        setState(() {
          _jsonResponse = message.toString();
          _jsonRequest = command;
          _commandResponse = jsonDecode(message);
          dataStore.jsonReq = command;
          dataStore.jsonReqStack += "\n" + "\n" + command;
          dataStore.jsonRes = message;
          dataStore.jsonResStack += "\n" + "\n" + message;
        });
      });
      return;
    } catch (e) {
      print(e);
    }
  }

  Future<dynamic> func(String command) async {
    WebSocket ws;
    try {
      ws = await WebSocket.connect(_webSocketURL);
      channel = IOWebSocketChannel(ws);
      channel.sink.add(command);

      channel.stream.listen((message) {
        setState(() {
          _jsonResponse = message.toString();
          _jsonRequest = command;
          dataStore.jsonReq = command;
          dataStore.jsonReqStack += "\n" + "\n" + command;
          dataStore.jsonRes = message;
          dataStore.jsonResStack += "\n" + "\n" + message;
          var json = jsonDecode(message);
          (json["patternFileList"] != null)
              ? commRes = PatternListCommandResponse.fromJson(json)
              : commRes = commRes;
          if (commRes != null) {
            populateCommResMap();
          }
          if (command.contains("runPattern")) {
            getPatternJsonData(cachedPattern.categoryName, cachedPattern.name);
          }
        });
      });
    } catch (e) {
      print(e);
      return;
    }
  }

  void populateCommResMap() {
    commRes.patternList.forEach((element) {
      if (element.name == "") {
        List<String> patternStringList = [];
        commResMap.putIfAbsent(element.categoryName, () => patternStringList);
        commResMap[element.categoryName].clear();
      } else {
        commResMap[element.categoryName].add(element.name);
      }
    });

    categoriesList.clear();
    commResMap.keys.forEach((element) {
      categoriesList.add(element);
    });
  }

  String generateCommand(String cmd, String requestedResource) {
    String controllerCommand = "{\"cmd\": \"" + cmd + "\", \"";
    if (cmd == "toCtlrGet") {
      controllerCommand =
          controllerCommand + "get\": [[\"" + requestedResource + "\"]]}";
    } else if (cmd == "toCtlrSet") {}
    return controllerCommand;
  }

  String configAdjustString(Map<String, dynamic> jsonData) {
    RunPatternCommand command = RunPatternCommand();
    command.cmd = "toCtlrSet";
    command.runPattern = RunPattern();
    command.runPattern.file = "";
    command.runPattern.id = "";
    command.runPattern.data = json.encode(jsonData);
    command.runPattern.state = 1;
    command.runPattern.zoneName = selectedZones;

    String runPatternString = runPatternCommandToJson(command);
    return runPatternString;
  }

//---- UI WIDGETS ----//

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Patterns"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: buttonsDisabled
                              ? null
                              : () {
                                  func(generateCommand(
                                      "toCtlrGet", "patternFileList"));
                                },
                          child: Text("Get Pattern List"),
                        ),
                      ),
                      Expanded(
                        flex: 10,
                        child: SizedBox(
                          height: 500,
                          width: 300,
                          child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: false,
                              itemCount: categoriesList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return Container(
                                  height: 100,
                                  color: Colors.white,
                                  child: Center(
                                      child: Column(
                                    children: [
                                      Text('${categoriesList[index]}'),
                                      DropdownButton<String>(
                                          items:
                                              commResMap[categoriesList[index]]
                                                  .map((String value) {
                                            return DropdownMenuItem<String>(
                                              value: value,
                                              child: Text(value),
                                            );
                                          }).toList(),
                                          onChanged: (strValue) {
                                            commRes.patternList
                                                .forEach((element) {
                                              if (element.name == strValue) {
                                                cachedPattern = element;
                                              }
                                            });
                                            func(generateRunPatternCommand(
                                                cachedPattern.categoryName,
                                                cachedPattern.name,
                                                null,
                                                true));
                                            setState(() {
                                              isOn = true;
                                            });
                                          }),
                                    ],
                                  )),
                                );
                              }),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Zones"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ElevatedButton(
                          onPressed: buttonsDisabled
                              ? null
                              : () {
                                  getZones();
                                },
                          child: Text("Get Zones"),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Container(
                          height: 100,
                          width: 200,
                          child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: false,
                              itemCount: zoneList.length,
                              itemBuilder: (BuildContext context, int index) {
                                return CheckboxListTile(
                                    tileColor: Colors.white,
                                    title: Text(zoneList[index]),
                                    value:
                                        selectedZones.contains(zoneList[index]),
                                    onChanged: (value) {
                                      setState(() {
                                        if (selectedZones
                                            .contains(zoneList[index])) {
                                          selectedZones.remove(zoneList[index]);
                                        } else {
                                          selectedZones.add(zoneList[index]);
                                        }
                                      });
                                    });
                              }),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Adjustments"),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Brightness: "),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                onPressed: isBrightnessDecrementButtonDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          brightnessLevel = brightnessLevel - 1;
                                          if (brightnessLevel <= 0) {
                                            isBrightnessDecrementButtonDisabled =
                                                true;
                                            isBrightnessIncrementButtonDisabled =
                                                false;
                                          } else {
                                            isBrightnessDecrementButtonDisabled =
                                                false;
                                            isBrightnessIncrementButtonDisabled =
                                                false;
                                          }
                                          sendCommand2(
                                              adjustmentCommand(
                                                  brightnessLevel, speed),
                                              null);
                                        });
                                      },
                                onLongPress: isBrightnessDecrementButtonDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          brightnessLevel =
                                              brightnessLevel - 10;
                                          if (brightnessLevel == 0) {
                                            isBrightnessDecrementButtonDisabled =
                                                true;
                                            isBrightnessIncrementButtonDisabled =
                                                false;
                                          } else {
                                            isBrightnessDecrementButtonDisabled =
                                                false;
                                            isBrightnessIncrementButtonDisabled =
                                                false;
                                          }
                                          sendCommand2(
                                              adjustmentCommand(
                                                  brightnessLevel, speed),
                                              null);
                                        });
                                      },
                                child: const Icon(Icons.remove),
                              ),
                            ),
                            Text("$brightnessLevel"),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: ElevatedButton(
                                onPressed: isBrightnessIncrementButtonDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          brightnessLevel = brightnessLevel + 1;
                                          if (brightnessLevel == 100) {
                                            isBrightnessIncrementButtonDisabled =
                                                true;
                                            isBrightnessDecrementButtonDisabled =
                                                false;
                                          } else {
                                            isBrightnessIncrementButtonDisabled =
                                                false;
                                            isBrightnessDecrementButtonDisabled =
                                                false;
                                          }
                                          sendCommand2(
                                              adjustmentCommand(
                                                  brightnessLevel, speed),
                                              null);
                                        });
                                      },
                                onLongPress: isBrightnessIncrementButtonDisabled
                                    ? null
                                    : () {
                                        setState(() {
                                          brightnessLevel =
                                              brightnessLevel + 10;
                                          if (brightnessLevel >= 100) {
                                            brightnessLevel = 100;
                                            isBrightnessIncrementButtonDisabled =
                                                true;
                                            isBrightnessDecrementButtonDisabled =
                                                false;
                                          } else {
                                            isBrightnessIncrementButtonDisabled =
                                                false;
                                            isBrightnessDecrementButtonDisabled =
                                                false;
                                          }
                                          sendCommand2(
                                              adjustmentCommand(
                                                  brightnessLevel, speed),
                                              null);
                                        });
                                      },
                                child: const Icon(Icons.add),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Speed: "),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ElevatedButton(
                              onPressed: isSpeedDecrementButtonDisabled
                                  ? null
                                  : () {
                                      setState(() {
                                        speed = speed - 1;
                                        if (speed <= 0) {
                                          speed = 0;
                                          isSpeedDecrementButtonDisabled = true;
                                          isSpeedIncrementButtonDisabled =
                                              false;
                                        } else {
                                          isSpeedDecrementButtonDisabled =
                                              false;
                                          isSpeedIncrementButtonDisabled =
                                              false;
                                        }
                                        sendCommand2(
                                            adjustmentCommand(
                                                brightnessLevel, speed),
                                            null);
                                      });
                                    },
                              onLongPress: isSpeedDecrementButtonDisabled
                                  ? null
                                  : () {
                                      setState(() {
                                        speed = speed - 10;
                                        if (speed <= 0) {
                                          speed = 0;
                                          isSpeedDecrementButtonDisabled = true;
                                          isSpeedIncrementButtonDisabled =
                                              false;
                                        } else {
                                          isSpeedDecrementButtonDisabled =
                                              false;
                                          isSpeedIncrementButtonDisabled =
                                              false;
                                        }
                                        sendCommand2(
                                            adjustmentCommand(
                                                brightnessLevel, speed),
                                            null);
                                      });
                                    },
                              child: const Icon(Icons.remove),
                            ),
                          ),
                          Text("$speed"),
                          Padding(
                            padding: const EdgeInsets.all(10.0),
                            child: ElevatedButton(
                              onPressed: isSpeedIncrementButtonDisabled
                                  ? null
                                  : () {
                                      setState(() {
                                        speed = speed + 1;
                                        if (speed >= 100) {
                                          speed = 100;
                                          isSpeedIncrementButtonDisabled = true;
                                          isSpeedDecrementButtonDisabled =
                                              false;
                                        } else {
                                          isSpeedIncrementButtonDisabled =
                                              false;
                                          isSpeedDecrementButtonDisabled =
                                              false;
                                        }
                                        sendCommand2(
                                            adjustmentCommand(
                                                brightnessLevel, speed),
                                            null);
                                      });
                                    },
                              onLongPress: isSpeedIncrementButtonDisabled
                                  ? null
                                  : () {
                                      setState(() {
                                        speed = speed + 10;
                                        if (speed >= 100) {
                                          speed = 100;
                                          isSpeedDecrementButtonDisabled =
                                              false;
                                          isSpeedIncrementButtonDisabled = true;
                                        } else {
                                          isSpeedDecrementButtonDisabled =
                                              false;
                                          isSpeedIncrementButtonDisabled =
                                              false;
                                        }
                                        sendCommand2(
                                            adjustmentCommand(
                                                brightnessLevel, speed),
                                            null);
                                      });
                                    },
                              child: const Icon(Icons.add),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Column(
                            children: [
                              Text("Off / On"),
                              Switch(
                                value: isOn,
                                onChanged: (value) => {
                                  func(generateRunPatternCommand(
                                      cachedPattern.categoryName,
                                      cachedPattern.name,
                                      null,
                                      value)),
                                  setState(() {
                                    isOn = value;
                                  })
                                },
                              ),
                            ],
                          )),
                      Spacer(),
                    ],
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text("Requests and Responses"),
                      ),
                      JsonReqRes(),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.1,
                        child: Form(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              TextFormField(
                                controller: myController,
                                decoration: const InputDecoration(
                                  fillColor: Colors.white,
                                  hintText:
                                      'enter IP Address of Controller to Coninue',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _webSocketURL =
                                  "ws://" + myController.text + ":9000/ws";
                              setState(() {
                                buttonsDisabled = false;
                                isBrightnessDecrementButtonDisabled = false;
                                isBrightnessIncrementButtonDisabled = false;
                                isSpeedIncrementButtonDisabled = false;
                                isSpeedDecrementButtonDisabled = false;
                              });
                            });
                          },
                          child: const Text('Connect'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
