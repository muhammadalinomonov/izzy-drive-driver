import '../../data/model/worker_info_model.dart';

abstract class WorkerInfoRepo {
  WorkerInfoModel getWorker();
  void updateStatus(WorkerStatus status);
}
