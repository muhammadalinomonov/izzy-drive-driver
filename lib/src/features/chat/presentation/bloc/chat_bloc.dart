import 'dart:ui';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:taxi_app/src/core/network/network_response.dart';
import 'package:taxi_app/src/features/chat/data/model/question_model.dart';
import 'package:taxi_app/src/features/chat/domain/repo/chat_repo.dart';
import 'package:meta/meta.dart';

part 'chat_event.dart';
part 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepo chatRepo;

  ChatBloc({required this.chatRepo}) : super(ChatInitial()) {
    on<FetchQuestionsEvent>((event, emit) async {
      emit(ChatLoading());
      final response = await chatRepo.fetchQuestions();
      if (response.errorText.isEmpty && response.data is QuestionTemplate) {
        event.onSuccess();
        emit(ChatSuccess(questionTemplate: response.data));
      } else {
        event.onError();
        emit(ChatFailure(errorMessage: response.errorText));
      }
    });
  }
}