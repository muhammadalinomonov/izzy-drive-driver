enum WorkerStatus { pending, accepted }

class WorkerInfoModel {
  final String name;
  final String experience;
  final String avatarUrl;
  WorkerStatus status;

  WorkerInfoModel({
    required this.name,
    required this.experience,
    required this.avatarUrl,
    this.status = WorkerStatus.pending,
  });
}
