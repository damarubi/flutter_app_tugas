import '../../domain/repositories/home_repository.dart' as repositories;
import '../../domain/entities/dashboard.dart' as entities;
import '../datasources/home_remote_datasource.dart' as datasources;

class HomeRepositoryImpl implements repositories.HomeRepository {
  final datasources.HomeRemoteDataSource remoteDataSource;

  HomeRepositoryImpl({required this.remoteDataSource});

  @override
  Future<entities.Dashboard> getDashboardData() async {
    return await remoteDataSource.getDashboardData();
  }
}
