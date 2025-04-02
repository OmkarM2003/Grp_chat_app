import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grp_chat_bloc/helper/helper_fuction.dart';
import 'package:grp_chat_bloc/pages/auth/login_page.dart';
import 'package:grp_chat_bloc/pages/auth/profile_page.dart';
import 'package:grp_chat_bloc/pages/search_page.dart';
import 'package:grp_chat_bloc/service/auth_service.dart';
import 'package:grp_chat_bloc/service/database_service.dart';
import 'package:grp_chat_bloc/widgets/group_title.dart';
import 'package:grp_chat_bloc/widgets/widgets.dart';
import 'package:velocity_x/velocity_x.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();
  Stream? groups;
  bool _isLoading = false;
  final TextEditingController _groupNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  String getName(String res) {
    return res.substring(res.indexOf("_") + 1);
  }

  Future<void> gettingUserData() async {
    try {
      email = (await HelperFunctions.getUserEmailFromSF())!;
      userName = (await HelperFunctions.getUserNameFromSF())!;
      groups =
          await DatabaseService(
            uid: FirebaseAuth.instance.currentUser!.uid,
          ).getUserGroups();
      setState(() {});
    } catch (e) {
      // Handle errors here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          IconButton(
            onPressed: () {
              nextScreen(context, const SearchPage());
            },
            icon: const Icon(Icons.search, size: 28),
          ),
        ],
        elevation: 0.0,
        centerTitle: true,
        title: const Text(
          "Groups",
          style: TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
        ),
      ),
      drawer: _buildDrawer(),
      body: groupList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          popUpDialog(context);
        },
        elevation: 0.0,
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 50),
        children: <Widget>[
          Icon(Icons.account_circle, size: 150, color: Colors.grey[700]),
          const SizedBox(height: 15),
          Text(
            userName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ).centered(),
          const SizedBox(height: 30),
          const Divider(height: 2),
          _buildDrawerItem(Icons.group, "Groups", () {}),
          _buildDrawerItem(Icons.account_circle, "Profile", () {
            nextScreenReplace(
              context,
              ProfilePage(email: email, userName: userName),
            );
          }),
          _buildDrawerItem(Icons.logout, "Logout", () {
            _showLogoutDialog();
          }),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Icon(icon),
      title: Text(title, style: const TextStyle(color: Colors.black)),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to Logout?"),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
            IconButton(
              onPressed: () async {
                await authService.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
              icon: const Icon(Icons.done_outline_rounded, color: Colors.green),
            ),
          ],
        );
      },
    );
  }

  void popUpDialog(BuildContext context) {
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Create a Group", textAlign: TextAlign.left),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isLoading)
                    Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                  else
                    TextField(
                      controller: _groupNameController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: Colors.red),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Theme.of(context).primaryColor,
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final groupName = _groupNameController.text.trim();
                    if (groupName.isNotEmpty) {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        await DatabaseService(
                          uid: FirebaseAuth.instance.currentUser!.uid,
                        ).createGroup(
                          userName,
                          FirebaseAuth.instance.currentUser!.uid,
                          groupName,
                        );
                        showSnackBar(
                          context,
                          Colors.green,
                          "Group Created Successfully",
                        );
                      } catch (error) {
                        showSnackBar(
                          context,
                          Colors.red,
                          "Error Creating Group",
                        );
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                        Navigator.of(context).pop();
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  child: const Text("Create"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget groupList() {
    return StreamBuilder(
      stream: groups,
      builder: (context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          var groupData = snapshot.data['groups'];
          if (groupData != null && groupData.isNotEmpty) {
            return ListView.builder(
              itemCount: groupData.length,
              itemBuilder: (context, index) {
                final reverseIndex = groupData.length - index - 1;
                return GroupTile(
                  userName: snapshot.data['fullName'],
                  groupId: getId(groupData[reverseIndex]),
                  groupName: getName(groupData[reverseIndex]),
                );
              },
            );
          } else {
            return noGroupWidget();
          }
        } else {
          return Center(
            child: CircularProgressIndicator(
              color: Theme.of(context).primaryColor,
            ),
          );
        }
      },
    );
  }

  Widget noGroupWidget() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              popUpDialog(context);
            },
            child: Icon(Icons.add_circle, color: Colors.grey[700], size: 75),
          ),
          const SizedBox(height: 20),
          const Text(
            "You've not joined any group, tap on the add icon to create a group or you can also search from top search button.",
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
