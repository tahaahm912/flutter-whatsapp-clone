import 'package:flutter/material.dart';
import 'package:mobile/app/router/app_router.dart';
import 'theme/app_theme.dart';

class BluLinkApp  extends StatelessWidget{
  const BluLinkApp ({super.key});

  @override
  
  Widget build(BuildContext context){
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'BlueLink',
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}