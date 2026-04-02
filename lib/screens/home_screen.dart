import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../login.dart';
import 'support_screen.dart';
import 'crisis_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  final List<Widget> pages = [
    const HomeContent(),
    const SupportScreen(),
    const CrisisScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SickleCare"),
        backgroundColor: Colors.redAccent,
      ),

      // 🔥 DRAWER MENU
      drawer: const AppDrawer(),

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.redAccent,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.support), label: "Support"),
          BottomNavigationBarItem(icon: Icon(Icons.warning), label: "Crisis"),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// HOME CONTENT
////////////////////////////////////////////////////////////

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? "User";

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [

          // 🔴 WELCOME CARD
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.redAccent, Colors.orangeAccent],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              "Welcome, $name ❤️\nStay strong & take care.",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 25),

          const Text("Quick Access",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 15),

          Row(
            children: [
              _card(context, Icons.chat, "AI Chat"),
              _card(context, Icons.cloud, "Weather"),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              _card(context, Icons.menu_book, "Education"),
              _card(context, Icons.health_and_safety, "Health Tips"),
            ],
          ),

          const SizedBox(height: 25),

          const Text("Daily Advice",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              "Stay hydrated, avoid stress, and take your medication regularly.",
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(BuildContext context, IconData icon, String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title coming soon")),
          );
        },
        child: Container(
          margin: const EdgeInsets.all(6),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, size: 30, color: Colors.blue),
              const SizedBox(height: 10),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// DRAWER MENU (VERY IMPORTANT)
////////////////////////////////////////////////////////////

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        children: [

          // 🔹 USER HEADER
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Colors.redAccent),
            accountName: Text(user?.displayName ?? "User"),
            accountEmail: Text(user?.email ?? ""),
            currentAccountPicture: const CircleAvatar(
              child: Icon(Icons.person),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Profile"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.support),
            title: const Text("Support"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.warning),
            title: const Text("Crisis Help"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CrisisScreen()),
              );
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Logout"),
            onTap: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),

          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text("Delete Account"),
            onTap: () async {
              try {
                await FirebaseAuth.instance.currentUser!.delete();

                if (!context.mounted) return;

                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text("Re-login required before deleting")),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

////////////////////////////////////////////////////////////
/// PROFILE SCREEN
////////////////////////////////////////////////////////////

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Profile")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, child: Icon(Icons.person)),

            const SizedBox(height: 15),

            Text(user?.displayName ?? "No Name",
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            Text(user?.email ?? ""),

            const SizedBox(height: 20),

            const Text("More profile features coming soon..."),
          ],
        ),
      ),
    );
  }
}