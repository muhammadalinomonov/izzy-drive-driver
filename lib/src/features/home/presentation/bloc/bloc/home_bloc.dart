import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/features/home/domain/repository/home_repository.dart';
import 'package:taxi_app/src/features/order_proccess/data/order_proccess_source.dart';

part 'home_event.dart';
part 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repository;
  HomeBloc(this._repository) : super(HomeState(status: HomeStatus.initial)) {
    on<GetBannersEvent>((event, emit) async {
      // Stale-while-revalidate: on silent refresh (pull-to-refresh) keep the
      // existing banners visible while we re-fetch in the background so the
      // carousel doesn't blink into a shimmer. Backend bo'sh array qaytarsa
      // ham success - uni "data yo'q" deb qaramaymiz.
      final hasData = state.status == HomeStatus.success;
      if (!(event.silent && hasData)) {
        emit(HomeState(status: HomeStatus.loading));
      }
      await OrderProccessSource().getMe();
      final result = await _repository.getBanners();
      if (result.errorText.isEmpty) {
        print('data came to bloc ${result.data}');
        emit(
          state.copyWith(
            status: HomeStatus.success,
            banners: List<Map>.from(result.data['data']),
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: HomeStatus.error,
            errorMessage: result.errorText,
          ),
        );
      }
    });
  }
}
