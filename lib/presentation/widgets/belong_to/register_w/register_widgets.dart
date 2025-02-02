import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:instagram/core/resources/assets_manager.dart';
import 'package:instagram/core/resources/color_manager.dart';
import 'package:instagram/core/resources/strings_manager.dart';
import 'package:instagram/core/resources/styles_manager.dart';
import 'package:instagram/core/utility/constant.dart';
import 'package:instagram/presentation/pages/register/sign_up_page.dart';
import 'package:instagram/presentation/widgets/belong_to/register_w/or_text.dart';
import 'package:instagram/presentation/widgets/global/custom_widgets/custom_text_field.dart';

class RegisterWidgets extends StatefulWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController? confirmPasswordController;
  final Widget customTextButton;
  final bool isThatLogIn;
  const RegisterWidgets({
    Key? key,
    required this.emailController,
    this.isThatLogIn = true,
    required this.passwordController,
    required this.customTextButton,
     this.confirmPasswordController,
  }) : super(key: key);

  @override
  State<RegisterWidgets> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<RegisterWidgets> {
  @override
  Widget build(BuildContext context) {
    return buildScaffold(context);
  }

  Scaffold buildScaffold(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
            child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: isThatMobile ? buildColumn(context) : buildForWeb(context),
        )),
      ),
    );
  }

  SizedBox buildForWeb(BuildContext context) {
    return SizedBox(
      width: 352,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 0.2),
            ),
            child: buildColumn(context),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            height: 65,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey, width: 0.2),
            ),
            child: haveAccountRow(context),
          ),
        ],
      ),
    );
  }

  Column buildColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          IconsAssets.instagramLogo,
          color: Theme.of(context).focusColor,
          height: 50,
        ),
        const SizedBox(height: 30),
        CustomTextField(
            hint: StringsManager.phoneOrEmailOrUserName.tr(),
            controller: widget.emailController),
        SizedBox(height: isThatMobile ? 15 : 6.5),
        CustomTextField(
            hint: StringsManager.password.tr(),
            controller: widget.passwordController),
        if (!widget.isThatLogIn&&widget.confirmPasswordController!=null) ...[
          SizedBox(height: isThatMobile ? 15 : 7),
          CustomTextField(
              hint: StringsManager.confirmPassword.tr(),
              controller: widget.confirmPasswordController!),
        ],
        widget.customTextButton,
        const SizedBox(height: 15),
        if (isThatMobile) ...[
          haveAccountRow(context),
          const SizedBox(height: 8),
          const OrText(),
        ] else ...[
          const SizedBox(height: 10),
          const OrText(),
          const SizedBox(height: 10),
        ],
        TextButton(
            onPressed: () {},
            child: Text(
              StringsManager.loginWithFacebook.tr(),
              style: getNormalStyle(color: ColorManager.blue),
            ))
      ],
    );
  }

  Row haveAccountRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          widget.isThatLogIn
              ? StringsManager.noAccount.tr()
              : StringsManager.haveAccount.tr(),
          style: getNormalStyle(fontSize: 13, color: ColorManager.black),
        ),
        const SizedBox(width: 4),
        register(context),
      ],
    );
  }

  InkWell register(BuildContext context) {
    return InkWell(
        onTap: () {
          if (widget.isThatLogIn) {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (context) => const SignUpPage(),
              ),
            );
          } else {
            Navigator.pop(context);
          }
        },
        child: registerText());
  }

  Text registerText() {
    return Text(
      widget.isThatLogIn
          ? StringsManager.signUp.tr()
          : StringsManager.logIn.tr(),
      style: getBoldStyle(fontSize: 13, color: Theme.of(context).focusColor),
    );
  }
}
