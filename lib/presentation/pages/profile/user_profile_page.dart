import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instagram/core/resources/color_manager.dart';
import 'package:instagram/core/resources/strings_manager.dart';
import 'package:instagram/core/resources/styles_manager.dart';
import 'package:instagram/presentation/cubit/followCubit/follow_cubit.dart';
import 'package:instagram/presentation/pages/massages/chatting_page.dart';
import 'package:instagram/presentation/widgets/belong_to/profile_w/bottom_sheet.dart';
import 'package:instagram/presentation/widgets/global/custom_widgets/custom_app_bar.dart';
import 'package:instagram/presentation/widgets/global/custom_widgets/custom_circular_progress.dart';
import 'package:instagram/presentation/widgets/belong_to/profile_w/profile_page.dart';
import 'package:instagram/presentation/widgets/belong_to/profile_w/recommendation_people.dart';
import 'package:instagram/core/functions/toast_show.dart';
import '../../../core/utility/constant.dart';
import '../../../data/models/user_personal_info.dart';
import '../../cubit/firestoreUserInfoCubit/user_info_cubit.dart';

class UserProfilePage extends StatefulWidget {
  final String userId;
  final String userName;

  const UserProfilePage({Key? key, required this.userId, this.userName = ''})
      : super(key: key);

  @override
  State<UserProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<UserProfilePage> {
  bool rebuildUserInfo = false;
  @override
  Widget build(BuildContext context) {
    return scaffold();
  }

  Widget scaffold() {
    return BlocBuilder<FirestoreUserInfoCubit, FirestoreGetUserInfoState>(
      bloc: widget.userName.isNotEmpty
          ? (BlocProvider.of<FirestoreUserInfoCubit>(context)
            ..getUserFromUserName(widget.userName))
          : (BlocProvider.of<FirestoreUserInfoCubit>(context)
            ..getUserInfo(widget.userId, isThatMyPersonalId: false)),
      buildWhen: (previous, current) {
        if (previous != current && current is CubitUserLoaded) {
          return true;
        }
        if (rebuildUserInfo && current is CubitUserLoaded) {
          return true;
        }
        return false;
      },
      builder: (context, state) {
        if (state is CubitUserLoaded) {
          return Scaffold(
            appBar: CustomAppBar.menuOfUserAppBar(
                context, state.userPersonalInfo.userName, bottomSheetOfAdd),
            body: ProfilePage(
              isThatMyPersonalId: false,
              userId: widget.userId,
              userInfo: state.userPersonalInfo,
              widgetsAboveTapBars:
                  widgetsAboveTapBars(state.userPersonalInfo, state),
            ),
          );
        } else if (state is CubitGetUserInfoFailed) {
          ToastShow.toastStateError(state);
          return Text(
            StringsManager.somethingWrong.tr(),
            style: Theme.of(context).textTheme.bodyText1,
          );
        } else {
          return const ThineCircularProgress();
        }
      },
    );
  }

  Future<void> bottomSheetOfAdd() {
    return CustomBottomSheet.bottomSheet(
      context,
      headIcon: Container(),
      bodyText: buildPadding(),
    );
  }

  Padding buildPadding() {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          textOfBottomSheet(StringsManager.report.tr()),
          const SizedBox(height: 15),
          textOfBottomSheet(StringsManager.block.tr()),
          const SizedBox(height: 15),
          textOfBottomSheet(StringsManager.aboutThisAccount.tr()),
          const SizedBox(height: 15),
          textOfBottomSheet(StringsManager.restrict.tr()),
          const SizedBox(height: 15),
          textOfBottomSheet(StringsManager.hideYourStory.tr()),
          const SizedBox(height: 15),
          textOfBottomSheet(StringsManager.copyProfileURL.tr()),
          const SizedBox(height: 15),
          textOfBottomSheet(StringsManager.shareThisProfile.tr()),
          const SizedBox(height: 15),
        ],
      ),
    );
  }

  Text textOfBottomSheet(String text) {
    return Text(text,
        style:
            getNormalStyle(fontSize: 15, color: Theme.of(context).focusColor));
  }

  List<Widget> widgetsAboveTapBars(
      UserPersonalInfo userInfo, FirestoreGetUserInfoState userInfoState) {
    return [
      followButton(userInfo, userInfoState),
      const SizedBox(width: 5),
      massageButton(userInfo),
      const SizedBox(width: 5),
      const RecommendationPeople(),
      const SizedBox(width: 10),
    ];
  }

  Widget followButton(
      UserPersonalInfo userInfo, FirestoreGetUserInfoState userInfoState) {
    return BlocBuilder<FollowCubit, FollowState>(
      // buildWhen: ,
      builder: (context, stateOfFollow) {
        return Expanded(
          child: InkWell(
              onTap: () async {
                setState(() {
                  rebuildUserInfo = false;
                });
                if (userInfo.followerPeople.contains(myPersonalId)) {
                  BlocProvider.of<FollowCubit>(context).removeThisFollower(
                      followingUserId: userInfo.userId,
                      myPersonalId: myPersonalId);
                } else {
                  BlocProvider.of<FollowCubit>(context).followThisUser(
                      followingUserId: userInfo.userId,
                      myPersonalId: myPersonalId);
                }

                setState(() {
                  rebuildUserInfo = true;
                });
              },
              child: whichContainerOfText(stateOfFollow, userInfo)),
        );
      },
    );
  }

  Widget whichContainerOfText(
      FollowState stateOfFollow, UserPersonalInfo userInfo) {
    bool isFollowLoading = stateOfFollow is CubitFollowThisUserLoading;
    if (stateOfFollow is CubitFollowThisUserFailed) {
      ToastShow.toastStateError(stateOfFollow);
    }
    return !userInfo.followerPeople.contains(myPersonalId)
        ? containerOfFollowText(
            text: StringsManager.follow.tr(),
            isThatFollower: false,
            isItLoading: isFollowLoading)
        : containerOfFollowText(
            text: StringsManager.following.tr(),
            isThatFollower: true,
            isItLoading: isFollowLoading);
  }

  Expanded massageButton(UserPersonalInfo userInfo) {
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          Navigator.of(
            context,
            rootNavigator: true,
          ).push(CupertinoPageRoute(
            builder: (context) => ChattingPage(
              userInfo: userInfo,
            ),
            maintainState: false,
          ));
        },
        child: containerOfFollowText(
            text: StringsManager.massage.tr(),
            isThatFollower: true,
            isItLoading: false),
      ),
    );
  }

  Container containerOfFollowText(
      {required String text,
      required bool isThatFollower,
      required bool isItLoading}) {
    return Container(
      height: 35.0,
      decoration: BoxDecoration(
        color:
            isThatFollower ? Theme.of(context).primaryColor : ColorManager.blue,
        border: Border.all(
            color: Theme.of(context).cardColor,
            width: isThatFollower ? 1.0 : 0),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Center(
        child: isItLoading
            ? CircularProgressIndicator(
                color: isThatFollower
                    ? Theme.of(context).focusColor
                    : Theme.of(context).primaryColor,
                strokeWidth: 1,
              )
            : Text(
                text,
                style: TextStyle(
                    fontSize: 17.0,
                    color: isThatFollower
                        ? Theme.of(context).focusColor
                        : ColorManager.white,
                    fontWeight: FontWeight.w500),
              ),
      ),
    );
  }
}