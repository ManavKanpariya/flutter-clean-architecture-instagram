import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:instagram/config/routes/app_routes.dart';
import 'package:instagram/core/functions/toast_show.dart';
import 'package:instagram/core/resources/color_manager.dart';
import 'package:instagram/core/resources/strings_manager.dart';
import 'package:instagram/core/resources/styles_manager.dart';
import 'package:instagram/core/utility/constant.dart';
import 'package:instagram/data/models/post.dart';
import 'package:instagram/presentation/cubit/StoryCubit/story_cubit.dart';
import 'package:instagram/presentation/cubit/postInfoCubit/post_cubit.dart';
import 'package:instagram/presentation/cubit/postInfoCubit/specific_users_posts_cubit.dart';
import 'package:instagram/presentation/customPackages/in_view_notifier/in_view_notifier_list.dart';
import 'package:instagram/presentation/customPackages/in_view_notifier/in_view_notifier_widget.dart';
import 'package:instagram/presentation/pages/story/story_for_web.dart';
import 'package:instagram/presentation/pages/story/story_page_for_mobile.dart';
import 'package:instagram/presentation/widgets/belong_to/profile_w/custom_gallery/create_new_story.dart';
import 'package:instagram/presentation/widgets/belong_to/time_line_w/all_catch_up_icon.dart';
import 'package:instagram/presentation/widgets/belong_to/time_line_w/image_of_post_for_time_line.dart';
import 'package:instagram/presentation/widgets/global/custom_widgets/custom_app_bar.dart';
import 'package:instagram/presentation/widgets/global/custom_widgets/custom_circulars_progress.dart';
import '../../../../data/models/user_personal_info.dart';
import '../../../cubit/firestoreUserInfoCubit/user_info_cubit.dart';
import '../../../widgets/global/circle_avatar_image/circle_avatar_of_profile_image.dart';

class HomePage extends StatefulWidget {
  final String userId;
  final bool playVideo;

  const HomePage({
    Key? key,
    required this.userId,
    this.playVideo = true,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ValueNotifier<bool> isThatEndOfList = ValueNotifier(false);
  UserPersonalInfo? personalInfo;
  ValueNotifier<bool> reLoadData = ValueNotifier(false);
  Post? selectedPostInfo;
  int? centerItemIndex;
  bool rebuild = true;
  List postsIds = [];
  ValueNotifier<List<Post>> postsInfo = ValueNotifier([]);
  List<UserPersonalInfo>? storiesOwnersInfo;

  Future<void> getData(int index) async {
    storiesOwnersInfo = null;
    reLoadData.value = false;
    UserInfoCubit userCubit =
        BlocProvider.of<UserInfoCubit>(context, listen: false);
    await userCubit.getUserInfo(widget.userId);
    personalInfo = userCubit.myPersonalInfo;
    if (!mounted) return;
    List usersIds = personalInfo!.followedPeople;

    SpecificUsersPostsCubit usersPostsCubit =
        BlocProvider.of<SpecificUsersPostsCubit>(context, listen: false);

    await usersPostsCubit.getSpecificUsersPostsInfo(usersIds: usersIds);

    List usersPostsIds = usersPostsCubit.usersPostsInfo;

    postsIds = personalInfo!.posts + usersPostsIds;
    if (!mounted) return;
    PostCubit postCubit = PostCubit.get(context);
    await postCubit
        .getPostsInfo(
            postsIds: postsIds, isThatMyPosts: true, lengthOfCurrentList: index)
        .then((value) {
      reLoadData.value = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bodyHeight = mediaQuery.size.height -
        AppBar().preferredSize.height -
        mediaQuery.padding.top;
    centerItemIndex ??= ((bodyHeight / 2) / bodyHeight).floor();
    if (rebuild) {
      getData(0);
      rebuild = false;
    }

    return Scaffold(
      appBar: isThatMobile ? CustomAppBar.basicAppBar(context) : null,
      body: Center(
        child: blocBuilder(bodyHeight),
      ),
    );
  }

  ValueListenableBuilder<bool> blocBuilder(double bodyHeight) {
    return ValueListenableBuilder(
      valueListenable: reLoadData,
      builder: (context, bool value, child) =>
          BlocBuilder<PostCubit, PostState>(
        buildWhen: (previous, current) {
          if (value && current is CubitMyPersonalPostsLoaded) {
            reLoadData.value = false;
            return true;
          }
          if (value) {
            reLoadData.value = false;
            return true;
          }

          if (previous != current && current is CubitMyPersonalPostsLoaded) {
            return true;
          }
          if (previous != current && current is CubitPostFailed) {
            return true;
          }
          return false;
        },
        builder: (BuildContext context, PostState state) {
          if (state is CubitMyPersonalPostsLoaded) {
            postsInfo.value = state.postsInfo;
            return postsInfo.value.isNotEmpty
                ? inViewNotifier(bodyHeight)
                : emptyMessage();
          } else if (state is CubitPostFailed) {
            ToastShow.toastStateError(state);
            return Center(
                child: Text(
              StringsManager.noPosts.tr(),
              style: getNormalStyle(color: Theme.of(context).focusColor),
            ));
          } else {
            return circularProgress();
          }
        },
      ),
    );
  }

  Widget inViewNotifier(double bodyHeight) {
    return ValueListenableBuilder(
      valueListenable: postsInfo,
      builder: (context, List<Post> postsInfoValue, child) =>
          InViewNotifierList(
        onRefreshData: getData,
        postsIds: postsIds,
        physics: const BouncingScrollPhysics(),
        isThatEndOfList: isThatEndOfList,
        initialInViewIds: const ['0'],
        isInViewPortCondition:
            (double deltaTop, double deltaBottom, double vpHeight) {
          return deltaTop < (0.5 * vpHeight) && deltaBottom > (0.5 * vpHeight);
        },
        itemCount: postsInfoValue.length,
        builder: (BuildContext context, int index) {
          return Center(
            child: Container(
              width: isThatMobile ? double.infinity : 450,
              margin: const EdgeInsetsDirectional.only(bottom: .5, top: .5),
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  return InViewNotifierWidget(
                    id: '$index',
                    builder: (_, bool isInView, __) {
                      bool checkForPlatform = isThatMobile
                          ? isInView && widget.playVideo
                          : isInView;
                      return columnOfWidgets(
                          bodyHeight, index, checkForPlatform);
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget columnOfWidgets(double bodyHeight, int index, bool playTheVideo) {
    double storiesHeight = isThatMobile ? 672 : 500;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (index == 0) ...[
          storiesOwnersInfo != null
              ? buildUsersStories(bodyHeight, context)
              : storiesLines(storiesHeight),
          if (isThatMobile) customDivider(),
        ] else ...[
          if (isThatMobile) divider(),
        ],
        posts(index, bodyHeight, playTheVideo),
        if (isThatEndOfList.value && index == postsIds.length - 1) ...[
          if (isThatMobile) divider(),
          const AllCatchUpIcon(),
        ]
      ],
    );
  }

  Divider divider() {
    return const Divider(color: ColorManager.lightGrey, thickness: .15);
  }

  Container customDivider() => Container(
      margin: const EdgeInsetsDirectional.only(bottom: 8),
      color: ColorManager.grey,
      width: double.infinity,
      height: 0.3);

  Widget posts(int index, double bodyHeight, bool playTheVideo) {
    Widget buildPost = ValueListenableBuilder(
      valueListenable: postsInfo,
      builder: (context, List<Post> postsInfoValue, child) => PostOfTimeLine(
        postInfo: ValueNotifier(postsInfo.value[index]),
        postsInfo: postsInfo,
        playTheVideo: playTheVideo,
        indexOfPost: index,
        reLoadData: reloadTheData,
      ),
    );
    return isThatMobile
        ? buildPost
        : roundedContainer(
            child: buildPost, internalPadding: false, verticalPadding: true);
  }

  reloadTheData() => reLoadData.value = true;

  Widget circularProgress() {
    return const ThineCircularProgress();
  }

  Widget emptyMessage() {
    return Center(
        child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          StringsManager.noPosts.tr(),
          style: getNormalStyle(color: Theme.of(context).focusColor),
        ),
        Text(
          StringsManager.tryAddPost.tr(),
          style: getNormalStyle(color: Theme.of(context).focusColor),
        ),
      ],
    ));
  }

  createNewStory() async {
    Navigator.maybePop(context);
    pushToPage(context, page: const CreateNewStory());
    reLoadData.value = true;
  }

  Widget buildUsersStories(double bodyHeight, BuildContext context) {
    Widget stories = buildStories(bodyHeight, context, storiesOwnersInfo!);
    return isThatMobile
        ? stories
        : roundedContainer(child: stories, isThatStory: true);
  }

  Widget storiesLines(double bodyHeight) {
    List<dynamic> usersStoriesIds =
        personalInfo!.followedPeople + personalInfo!.followerPeople;
    return ValueListenableBuilder(
      valueListenable: reLoadData,
      builder: (context, bool value, child) =>
          BlocBuilder<StoryCubit, StoryState>(
        bloc: StoryCubit.get(context)
          ..getStoriesInfo(
              usersIds: usersStoriesIds, myPersonalInfo: personalInfo!),
        buildWhen: (previous, current) {
          if (value && current is CubitStoriesInfoLoaded) {
            reLoadData.value = false;
            return true;
          }

          if (previous != current && current is CubitStoriesInfoLoaded) {
            return true;
          }
          if (previous != current && current is CubitStoryFailed) {
            return true;
          }
          return false;
        },
        builder: (context, state) {
          if (state is CubitStoriesInfoLoaded) {
            storiesOwnersInfo = state.storiesOwnersInfo;
            return buildUsersStories(bodyHeight, context);
          } else if (state is CubitStoryFailed) {
            ToastShow.toastStateError(state);
            return Center(
                child: Text(
              StringsManager.somethingWrong.tr(),
              style: getNormalStyle(color: Theme.of(context).focusColor),
            ));
          } else {
            return Container();
          }
        },
      ),
    );
  }

  Padding roundedContainer({
    required Widget child,
    bool internalPadding = true,
    bool verticalPadding = false,
    bool isThatStory = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0),
      child: Container(
        padding: internalPadding || verticalPadding
            ? const EdgeInsets.symmetric(vertical: 15)
            : null,
        decoration: BoxDecoration(
          color: ColorManager.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: ColorManager.lowOpacityGrey, width: 1),
        ),
        child: child,
      ),
    );
  }

  ScrollController scrollController = ScrollController();
  Padding buildStories(double bodyHeight, BuildContext context,
      List<UserPersonalInfo> storiesOwnersInfo) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 10),
      child: SizedBox(
        width: double.infinity,
        height: bodyHeight * 0.155,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (personalInfo!.stories.isEmpty && isThatMobile) ...[
                myOwnStory(context, storiesOwnersInfo, bodyHeight),
                const SizedBox(width: 12),
              ],
              ListView.separated(
                scrollDirection: Axis.horizontal,
                shrinkWrap: true,
                controller: scrollController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: storiesOwnersInfo.length,
                separatorBuilder: (BuildContext context, int index) =>
                    const SizedBox(width: 12),
                itemBuilder: (BuildContext context, int index) {
                  UserPersonalInfo publisherInfo = storiesOwnersInfo[index];
                  String hashTag = isThatMobile
                      ? "${publisherInfo.userId.hashCode} for mobile"
                      : "${publisherInfo.userId.hashCode} for web";
                  return Hero(
                    tag: hashTag,
                    child: GestureDetector(
                      onTap: () {
                        Widget page;
                        if (isThatMobile) {
                          page = StoryPageForMobile(
                              user: publisherInfo,
                              hashTag: hashTag,
                              storiesOwnersInfo: storiesOwnersInfo);
                        } else {
                          page = StoryPageForWeb(
                              user: publisherInfo,
                              hashTag: hashTag,
                              storiesOwnersInfo: storiesOwnersInfo);
                        }
                        pushToPage(context,
                            page: page, withoutPageTransition: true);
                      },
                      child: CircleAvatarOfProfileImage(
                        userInfo: publisherInfo,
                        bodyHeight: bodyHeight * 1.1,
                        thisForStoriesLine: true,
                        nameOfCircle: index == 0 &&
                                publisherInfo.userId == personalInfo!.userId
                            ? StringsManager.yourStory.tr()
                            : "",
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  moveToStoryPage(
          List<UserPersonalInfo> storiesOwnersInfo, UserPersonalInfo user) =>
      pushToPage(context,
          page: StoryPageForMobile(
              user: user, storiesOwnersInfo: storiesOwnersInfo));

  Widget myOwnStory(BuildContext context,
      List<UserPersonalInfo> storiesOwnersInfo, double bodyHeight) {
    return GestureDetector(
      onTap: () async {
        pushToPage(context, page: const CreateNewStory());
        reLoadData.value = true;
      },
      child: Stack(
        children: [
          CircleAvatarOfProfileImage(
            userInfo: personalInfo!,
            bodyHeight: bodyHeight,
            moveTextMore: true,
            thisForStoriesLine: true,
            nameOfCircle: StringsManager.yourStory.tr(),
          ),
          Positioned(
            top: bodyHeight * .0525,
            left: bodyHeight * .0555,
            right: bodyHeight * .01,
            child: CircleAvatar(
              radius: 13,
              backgroundColor: Theme.of(context).primaryColor,
            ),
          ),
          Positioned(
            top: bodyHeight * .058,
            left: bodyHeight * .058,
            right: bodyHeight * .012,
            child: CircleAvatar(
              radius: 9.5,
              backgroundColor: Theme.of(context).primaryColor,
              child: const CircleAvatar(
                radius: 10,
                backgroundColor: ColorManager.blue,
                child: Icon(
                  Icons.add,
                  size: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
