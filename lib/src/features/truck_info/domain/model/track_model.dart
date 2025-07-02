class TruckMarkResponse {
  final bool status;
  final String message;
  final List<TruckMark> data;

  TruckMarkResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TruckMarkResponse.fromJson(Map<String, dynamic> json) {
    return TruckMarkResponse(
      status: json['status'],
      message: json['message'],
      data: List<TruckMark>.from(
        json['data'].map((x) => TruckMark.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.map((x) => x.toJson()).toList(),
  };
}

class TruckMark {
  final int id;
  final String name;

  TruckMark({required this.id, required this.name});

  factory TruckMark.fromJson(Map<String, dynamic> json) {
    return TruckMark(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}

class TruckModelResponse {
  final bool status;
  final String message;
  final TruckModelsByMark data;

  TruckModelResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory TruckModelResponse.fromJson(Map<String, dynamic> json) {
    return TruckModelResponse(
      status: json['status'],
      message: json['message'],
      data: TruckModelsByMark.fromJson(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.toJson(),
  };
}

class TruckModelsByMark {
  final int markId;
  final String markName;
  final List<TruckModel> models;

  TruckModelsByMark({
    required this.markId,
    required this.markName,
    required this.models,
  });

  factory TruckModelsByMark.fromJson(Map<String, dynamic> json) {
    return TruckModelsByMark(
      markId: json['mark_id'],
      markName: json['mark_name'],
      models: List<TruckModel>.from(
        json['models'].map((x) => TruckModel.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'mark_id': markId,
    'mark_name': markName,
    'models': models.map((x) => x.toJson()).toList(),
  };
}

class TruckModel {
  final int id;
  final String name;
  final Mark mark;

  TruckModel({required this.id, required this.name, required this.mark});

  factory TruckModel.fromJson(Map<String, dynamic> json) {
    return TruckModel(
      id: json['id'],
      name: json['name'],
      mark: Mark.fromJson(json['mark']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mark': mark.toJson(),
  };
}

class Mark {
  final int id;
  final String name;

  Mark({required this.id, required this.name});

  factory Mark.fromJson(Map<String, dynamic> json) {
    return Mark(id: json['id'], name: json['name']);
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
