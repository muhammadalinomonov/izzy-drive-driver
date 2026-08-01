part of 'inivites_bloc.dart';

@immutable
sealed class InivitesState {}

final class InivitesInitial extends InivitesState {}

final class InivitesLoading extends InivitesState {}

final class InivitesLoaded extends InivitesState {
final OrderResponse orderResponse;

InivitesLoaded(this.orderResponse);
}

final class InivitesError extends InivitesState {
final String message;

InivitesError(this.message);
}

/// Emitted after the driver successfully cancels the pending order.
/// The page listens for this and navigates back to the main screen.
final class InivitesCancelled extends InivitesState {}
