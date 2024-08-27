import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_app/screen/login.dart';
import 'package:recycle_app/utils/colors.dart';

class LogOutScreen extends StatefulWidget {
  const LogOutScreen({super.key});

  @override
  State<LogOutScreen> createState() => _LogOutScreenState();
}

class _LogOutScreenState extends State<LogOutScreen> {

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;

    if (user == null) {
      return Center(child: Text("User not logged in"));
    }
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title:Text(
          user.email!,
          style: TextStyle(fontSize: 24),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LogInScreen()));});
            },
            child: Icon(Icons.logout),
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
  stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return Center(child: CircularProgressIndicator());
    }

    if (snapshot.hasError) {
      return Center(child: Text("Error loading data"));
    }

    if (!snapshot.hasData || !snapshot.data!.exists) {
      return Center(child: Text("No data available"));
    }

    Map<String, dynamic> data = snapshot.data!.data() as Map<String, dynamic>;

    String userName = data['user name'] ?? 'No username';
    String email = data['email'] ?? 'No email';

    data.remove('user name');
    data.remove('email');

    return ListView(
      children: [
        ListTile(
          title: Text('Username'),
          trailing: Text(userName),
        ),
        ListTile(
          title: Text('Email'),
          trailing: Text(email),
        ),
        ...data.entries.map((entry) {
          return ListTile(
            title: Text(entry.key),
            trailing: Text(entry.value.toString()),
          );
        }).toList(),
      ],
    );
  },
)
,
    );
  }
}