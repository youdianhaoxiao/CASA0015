import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_app/screen/login.dart';
import 'package:recycle_app/utils/colors.dart';
import 'package:recycle_app/widgets/reusable.dart';

class signUpScreen extends StatefulWidget {
  const signUpScreen({Key? key}) : super(key: key);

  @override
  State<signUpScreen> createState() => _LogInScreenState();
}

class _LogInScreenState extends State<signUpScreen> {
  TextEditingController _passwordText = TextEditingController();
  TextEditingController _emailText = TextEditingController();
  TextEditingController _userNameText = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // extendBodyBehindAppBar: true,
      // appBar: AppBar(
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   title: const Text(
      //     "Sign Up",
      //     style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      //   ),
      // ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
          hexStringToColor("fcfcfc"),
          hexStringToColor("2ed180"),
          hexStringToColor("57d993")
        ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 120, 20, 0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    'Welcome!',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 52),
                  ),
                  SizedBox(
                    height: 30,
                  ),
                  Text(
                    'Register with your details',
                    style: TextStyle(fontSize: 22),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  reusableTextField("Enter User Name", Icons.person_outline,
                      false, _userNameText),
                  SizedBox(
                    height: 30,
                  ),
                  reusableTextField("Enter Email address", Icons.person_outline,
                      false, _emailText),
                  const SizedBox(
                    height: 20,
                  ),
                  reusableTextField("Enter Password", Icons.lock_outline, true,
                      _passwordText),
                  const SizedBox(
                    height: 50,
                  ),
                  signInsignUpButton(context, false, () {
                    FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                            email: _emailText.text,
                            password: _passwordText.text)
                        .then((value) {
                      addUserData(
                          value.user!.uid, 
                          _userNameText.text.trim(), 
                          _emailText.text.trim()
                      );
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LogInScreen()));
                    }).onError((error, stackTrace) {
                      print("${error.toString()}");
                    });
                  }),
                ]),
          ),
        ),
      ),
    );
  }

  Future addUserData(String uid, String userName, String email) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'user name': userName,
      'email': email,
      'plastic': 0,
      'organic': 0,
      'glass': 0,
      'metal': 0,
      'paper': 0,
      'others': 0,
    });
  }
}
