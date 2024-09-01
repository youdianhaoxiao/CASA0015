import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:recycle_app/screen/login.dart';

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          user.email!,
          style: TextStyle(fontSize: 24),
        ),
        actions: [
          GestureDetector(
            onTap: () {
              FirebaseAuth.instance.signOut().then((value) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => LogInScreen()));
              });
            },
            child: Icon(Icons.logout),
          )
        ],
      ),
      body: SafeArea( 
        child: StreamBuilder<DocumentSnapshot>(
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

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: DataTable(
                      columns: [
                        DataColumn(
                          label: Text(
                            'Field',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Value',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'Reset',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                      rows: [
                        DataRow(
                          cells: [
                            DataCell(Text(
                              'Username',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )),
                            DataCell(Text(userName)),
                            DataCell(SizedBox.shrink()), 
                          ],
                        ),
                        DataRow(
                          cells: [
                            DataCell(Text(
                              'Email',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            )),
                            DataCell(Text(email)),
                            DataCell(SizedBox.shrink()),
                          ],
                        ),
                        ...data.entries.map((entry) {
                          return DataRow(
                            cells: [
                              DataCell(Text(
                                capitalize(entry.key),  
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              )),
                              DataCell(Text('${entry.value} kg')),
                              DataCell(
                                ElevatedButton(
                                  onPressed: () => _resetField(user.uid, entry.key),
                                  child: Text('Reset'),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _resetField(String uid, String field) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).update({field: 0});
    } catch (e) {
      print("Failed to reset field: $e");
    }
  }

  
  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
}
