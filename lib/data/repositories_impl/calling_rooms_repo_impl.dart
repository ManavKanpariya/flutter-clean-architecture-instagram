import 'package:instagram/core/utility/constant.dart';
import 'package:instagram/data/datasourses/remote/calling_rooms/calling_rooms.dart';
import 'package:instagram/data/datasourses/remote/user/firestore_user_info.dart';
import 'package:instagram/data/models/user_personal_info.dart';
import 'package:instagram/domain/entities/calling_status.dart';
import 'package:instagram/domain/repositories/calling_rooms_repository.dart';

class CallingRoomsRepoImpl implements CallingRoomsRepository {
  @override
  Future<String> createCallingRoom(
      {required UserPersonalInfo myPersonalInfo,
      required String callToThisUserId}) async {
    try {
      String channelId = await FireStoreCallingRooms.createCallingRoom(
          myPersonalInfo: myPersonalInfo);

      bool isUserAvailable = await FirestoreUser.updateChannelId(
          userId: callToThisUserId,
          channelId: channelId,
          myPersonalId: myPersonalInfo.userId);
      if (!isUserAvailable) {
        throw Exception('Busy');
      } else {
        return channelId;
      }
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Stream<bool> getCallingStatus({required String userId}) =>
      FirestoreUser.getCallingStatus(userId: userId);
  @override
  Future<String> joinToRoom(
      {required String channelId, required UserPersonalInfo userInfo}) async {
    try {
      return await FireStoreCallingRooms.joinToRoom(
          channelId: channelId, userInfo: userInfo);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> cancelJoiningToRoom(String userId) async {
    try {
      await FirestoreUser.cancelJoiningToRoom(userId);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<List<UserInfoInCallingRoom>> getUsersInfoInThisRoom(
      {required String channelId}) async {
    try {
      return await FireStoreCallingRooms.getUsersInfoInThisRoom(
          channelId: channelId);
    } catch (e) {
      return Future.error(e.toString());
    }
  }

  @override
  Future<void> deleteTheRoom(
      {required String channelId, required String userId}) async {
    try {
      await FirestoreUser.clearChannelsIds(
          userId: userId, myPersonalId: myPersonalId);
      return await FireStoreCallingRooms.deleteTheRoom(channelId: channelId);
    } catch (e) {
      return Future.error(e.toString());
    }
  }
}
