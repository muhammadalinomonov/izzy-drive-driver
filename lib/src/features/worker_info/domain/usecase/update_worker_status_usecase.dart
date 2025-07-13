import '../repo/worker_info_repo.dart';
import '../../data/model/worker_info_model.dart';

class UpdateWorkerStatusUseCase {
  final WorkerInfoRepo repo;
  UpdateWorkerStatusUseCase(this.repo);

  void call(WorkerStatus status) {
    repo.updateStatus(status);
  }
}
