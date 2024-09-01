import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recycle_app/screen/home.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Score Board'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => HomePage()),
            );
          },
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getTopTenUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error loading leaderboard"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No data available"));
          }

          List<Map<String, dynamic>> topUsers = snapshot.data!;

          return ListView.builder(
            itemCount: topUsers.length,
            itemBuilder: (context, index) {
              var user = topUsers[index];
              return ListTile(
                leading: Text("#${index + 1}"),
                title: Text("User: ${user['user name'] ?? 'Unknown'}"),
                subtitle: Text("Points: ${user['totalPoints']}"),
              );
            },
          );
        },
      ),
    );
  }

  Stream<List<Map<String, dynamic>>> getTopTenUsers() {
    return FirebaseFirestore.instance
        .collection('users')
        .orderBy('totalPoints', descending: true)
        .limit(10)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }
}

