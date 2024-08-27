import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:recycle_app/screen/logout.dart';
import 'package:recycle_app/screen/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    RecyclingGrid(),
    Text('Notifications Page'),
    Text('Recycling Page'),
    Text('Profile Page'),
  ];

  void _onItemTapped(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const mapPage()),
      );
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LogOutScreen()),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recycling Guide',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Recycling Guide'),
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.eco),
              label: 'Eco',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.recycling),
              label: 'Recycle',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.language),
              label: 'Map',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Colors.green,
          unselectedItemColor: const Color.fromARGB(255, 219, 218, 218),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}

class RecyclingGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: EdgeInsets.all(16),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: List.generate(choices.length, (index) {
        return Center(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => SliderPage(choice: choices[index])),
              );
            },
            child: SelectCard(choice: choices[index]),
          ),
        );
      }),
    );
  }
}

class Choice {
  const Choice({required this.title, required this.icon});
  final String title;
  final IconData icon;
}

const List<Choice> choices = <Choice>[
  Choice(title: 'Plastic', icon: Icons.recycling),
  Choice(title: 'Organics', icon: Icons.eco),
  Choice(title: 'Glass', icon: Icons.bubble_chart),
  Choice(title: 'Metal', icon: Icons.construction),
  Choice(title: 'Paper', icon: Icons.book),
  Choice(title: 'Other', icon: Icons.more_horiz),
];

class SelectCard extends StatelessWidget {
  const SelectCard({Key? key, required this.choice}) : super(key: key);
  final Choice choice;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(child: Icon(choice.icon, size: 50.0)),
            Text(choice.title, style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class SliderPage extends StatefulWidget {
  final Choice choice;

  const SliderPage({Key? key, required this.choice}) : super(key: key);

  @override
  _SliderPageState createState() => _SliderPageState();
}

class _SliderPageState extends State<SliderPage> {
  double _currentValue = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.choice.title),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${_currentValue.toStringAsFixed(2)} kg',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _currentValue,
              min: -10,
              max: 10,
              divisions: 40,
              label: _currentValue.toStringAsFixed(2),
              onChanged: (value) {
                setState(() {
                  _currentValue = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                try {
                  await updateField(widget.choice.title.toLowerCase(), _currentValue);
                  Navigator.pop(context);
                } catch (e) {
                  print("Failed to update field: $e");
                  // Optionally show a Snackbar or dialog with the error message
                }
              },
              child: Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> updateField(String field, double value) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final docRef = FirebaseFirestore.instance.collection('users').doc(user.uid);
      try {
        await FirebaseFirestore.instance.runTransaction((transaction) async {
          final snapshot = await transaction.get(docRef);
          if (!snapshot.exists) {
            throw Exception("User document does not exist!");
          }
          // Ensure that the field exists and is a double
          double newValue = (snapshot.get(field) as num).toDouble() + value;
          transaction.update(docRef, {field: newValue});
        });
      } catch (e) {
        print("Transaction failed: $e");
        rethrow; // rethrow the error so it can be handled by the caller
      }
    } else {
      throw Exception("User is not logged in!");
    }
  }
}


