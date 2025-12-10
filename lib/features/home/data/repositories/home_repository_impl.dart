import '../../domain/repositories/home_repository.dart' as repositories;
import '../../domain/entities/dashboard.dart' as entities;
import '../datasources/home_remote_datasource.dart' as datasources;

import '../../../../core/services/session_service.dart';

class HomeRepositoryImpl implements repositories.HomeRepository {
  final datasources.HomeRemoteDataSource remoteDataSource;
  final SessionService sessionService;

  HomeRepositoryImpl({
    required this.remoteDataSource,
    required this.sessionService,
  });

  @override
  Future<entities.Dashboard> getDashboardData() async {
    final user = await sessionService.getSession();
    if (user == null) {
      throw Exception('User session not found');
    }
    return await remoteDataSource.getDashboardData(uid: user.uid);
  }
}
