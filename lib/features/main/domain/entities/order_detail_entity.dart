import 'package:equatable/equatable.dart';
import 'package:mechanic/features/common/data/models/generic_pagination.dart';
import 'package:mechanic/features/main/domain/entities/order_entity.dart';
import 'package:mechanic/features/main/domain/entities/proposal_entity.dart';

class OrderDetailEntity extends Equatable{
  @OrderEntityConverter()
  final OrderEntity order;
  @ProposalEntityConverter()
  final ProposalEntity yourProposal;
  @ProposalEntityConverter()
  final List<ProposalEntity> proposals;


  const OrderDetailEntity({
    this.order = const OrderEntity(),
    this.yourProposal = const ProposalEntity(),
    this.proposals = const [],
  });

  @override
  List<Object?> get props => [
        order,
        yourProposal,
        proposals,
      ];

}