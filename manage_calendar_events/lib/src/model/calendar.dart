part of manage_calendar_events;

class Calendar {
  String? id;
  String? name;
  String? accountName;
  String? ownerName;
  bool? isReadOnly;
  String? type;
  String? displayName;

  Calendar({
    this.id,
    this.name,
    this.accountName,
    this.ownerName,
    this.isReadOnly,
    this.type,
    this.displayName,
  });

  Calendar.fromJson(Map<String, dynamic> data) {
    this.id = data["id"];
    this.name = data["name"];
    this.accountName = data["accountName"];
    this.ownerName = data["ownerName"];
    this.isReadOnly = data["isReadOnly"];
    this.type = data["type"];
    this.displayName = data["displayName"];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = Map<String, dynamic>();
    data["id"] = this.id;
    data["name"] = this.name;
    data["accountName"] = this.accountName;
    data["ownerName"] = this.ownerName;
    data["isReadOnly"] = this.isReadOnly;
    data["type"] = this.type;
    data["displayName"] = this.displayName;
    return data;
  }

  @override
  String toString() {
    return toJson().toString();
  }
}
