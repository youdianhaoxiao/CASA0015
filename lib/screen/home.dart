import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:recycle_app/screen/logout.dart';
import 'package:recycle_app/screen/map.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:recycle_app/screen/scoreboard.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  static final List<Widget> _widgetOptions = <Widget>[
    RecyclingGrid(),
    ScoreboardPage(),
    const mapPage(),
    const LogOutScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recycling Tracker',
      home: Scaffold(
        appBar: AppBar(
          title: Text('Recycling Tracker'),
        ),
        body: _widgetOptions.elementAt(_selectedIndex),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.eco),
              label: 'Tracker',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Score Board',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.delete),
              label: 'Recycling Map',
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
  Choice(title: 'Plastic', icon: Icons.shopping_basket),
  Choice(title: 'Organics', icon: Icons.compost),
  Choice(title: 'Glass', icon: Icons.science),
  Choice(title: 'Metal', icon: Icons.construction),
  Choice(title: 'Paper', icon: Icons.book),
  Choice(title: 'Other', icon: Icons.add_circle),
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
            Expanded(
              child: Icon(
                choice.icon,
                size: 50.0,
                color: Colors.green,
              ),
            ),
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
  bool _isLoading = false;

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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(
                  widget.choice.icon,
                  size: 50.0,
                  color: Colors.white,
                ),
              ),
            ),
            SizedBox(height: 20),
            
            Text(
              _getDescription(widget.choice.title),
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20), 
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
              onPressed: _isLoading ? null : () async {
                setState(() {
                  _isLoading = true;
                });
                try {
                  await updateField(widget.choice.title.toLowerCase(), _currentValue);
                  Navigator.pop(context);
                } catch (e) {
                  print("Failed to update field: $e");
                } finally {
                  if (mounted) {
                    setState(() {
                      _isLoading = false;
                    });
                  }
                }
              },
              child: _isLoading ? CircularProgressIndicator() : Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  
  String _getDescription(String title) {
    switch (title) {
      case 'Plastic':
        return 'Plastic includes bottles, containers, bags, etc.';
      case 'Organics':
        return 'Organics include food waste, yard waste, etc.';
      case 'Glass':
        return 'Glass includes bottles, jars, and other glass products.';
      case 'Metal':
        return 'Metal includes cans, foil, and other metal items.';
      case 'Paper':
        return 'Paper includes newspapers, cardboard, etc.';
      case 'Other':
        return 'Other includes items that don\'t fit into other categories.';
      default:
        return '';
    }
  }
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

        double newValue = (snapshot.get(field) as num).toDouble() + value;
        transaction.update(docRef, {field: newValue});

        double plastic = (snapshot.get('plastic') as num).toDouble();
        double organic = (snapshot.get('organic') as num).toDouble();
        double glass = (snapshot.get('glass') as num).toDouble();
        double metal = (snapshot.get('metal') as num).toDouble();
        double paper = (snapshot.get('paper') as num).toDouble();
        double others = (snapshot.get('others') as num).toDouble();

        double totalPoints = plastic + organic + glass + metal + paper + others;
        totalPoints += newValue - (snapshot.get(field) as num).toDouble();

        transaction.update(docRef, {'totalPoints': totalPoints});
      });
    } catch (e) {
      print("Transaction failed: $e");
      rethrow;
    }
  } else {
    throw Exception("User is not logged in!");
  }
}
