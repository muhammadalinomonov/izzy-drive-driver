import '../model/worker_info_model.dart';
import '../../domain/repo/worker_info_repo.dart';

class WorkerInfoRepoImpl implements WorkerInfoRepo {
  final WorkerInfoModel _worker = WorkerInfoModel(
    name: 'Eshonov Fakhriyor',
    experience: '10 years experience',
    avatarUrl: 'https://randomuser.me/api/portraits/men/1.jpg',
    status: WorkerStatus.pending,
  );

  @override
  WorkerInfoModel getWorker() => _worker;

  @override
  void updateStatus(WorkerStatus status) {
    _worker.status = status;
  }
}
