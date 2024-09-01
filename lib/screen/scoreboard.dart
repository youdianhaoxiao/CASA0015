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

          return LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Rank')),
                        DataColumn(label: Text('User')),
                        DataColumn(label: Text('Points')),
                      ],
                      rows: List<DataRow>.generate(
                        topUsers.length,
                        (index) {
                          var user = topUsers[index];
                          return DataRow(
                            cells: [
                              DataCell(
                                Row(
                                  children: [
                                    Text("#${index + 1}"),
                                    SizedBox(width: 8),
                                    if (index == 0) Icon(Icons.emoji_events, color: Colors.yellow), 
                                    if (index == 1) Icon(Icons.emoji_events, color: Colors.grey),  
                                    if (index == 2) Icon(Icons.emoji_events, color: Colors.brown), 
                                  ],
                                ),
                              ),
                              DataCell(Text(user['user name'] ?? 'Unknown')),
                              DataCell(Text("${user['totalPoints']}")),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
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


