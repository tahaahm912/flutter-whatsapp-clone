import 'package:flutter/material.dart';
class BluLinkApp  extends StatelessWidget{
  const BluLinkApp ({super.key});

  @override
  
  Widget build(BuildContext context){
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text("BluLink"),
        ),
      ),
    );
  }
}