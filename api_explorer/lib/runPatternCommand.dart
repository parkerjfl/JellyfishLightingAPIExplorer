import 'dart:convert';

RunPatternCommand runPatternCommandFromJson(String str) =>
    RunPatternCommand.fromJson(json.decode(str));

String runPatternCommandToJson(RunPatternCommand data) =>
    json.encode(data.toJson());

class RunPatternCommand {
  RunPatternCommand({
    this.cmd,
    this.runPattern,
  });

  String cmd;
  RunPattern runPattern;

  factory RunPatternCommand.fromJson(Map<String, dynamic> json) =>
      RunPatternCommand(
        cmd: json["cmd"],
        runPattern: RunPattern.fromJson(json["runPattern"]),
      );

  Map<String, dynamic> toJson() => {
        "cmd": cmd,
        "runPattern": runPattern.toJson(),
      };
}

class RunPattern {
  RunPattern({
    this.file,
    this.data,
    this.id,
    this.state,
    this.zoneName,
  });

  String file;
  String data;
  String id;
  int state;
  List<String> zoneName;

  void setData(String data) {
    this.data = data;
  }

  factory RunPattern.fromJson(Map<String, dynamic> json) => RunPattern(
        file: json["file"],
        data: json["data"],
        id: json["id"],
        state: json["state"],
        zoneName: List<String>.from(json["zoneName"].map((x) => x)),
      );

  Map<String, dynamic> toJson() => {
        "file": file,
        "data": data,
        "id": id,
        "state": state,
        "zoneName": List<dynamic>.from(zoneName.map((x) => x)),
      };
}
