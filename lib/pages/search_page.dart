import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:grp_chat_bloc/helper/helper_fuction.dart' show HelperFunctions;
import 'package:grp_chat_bloc/pages/chat_page.dart';
import 'package:grp_chat_bloc/service/database_service.dart';
import 'package:grp_chat_bloc/widgets/widgets.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController SearchController = TextEditingController();
  bool isLoading = false;
  QuerySnapshot? searchSnapshot;
  bool hasUserSearched = false;
  bool isJoined = false;
  String userName = "";
  User? user;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCurrentUserIdandName();
  }

  getCurrentUserIdandName() async {
    await HelperFunctions.getUserNameFromSF().then((value) {
      setState(() {
        userName = value!;
      });
    });
    user = FirebaseAuth.instance.currentUser;
  }

  String getName(String r) {
    return r.substring(r.indexOf("_") + 1);
  }

  String getId(String res) {
    return res.substring(0, res.indexOf("_"));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        backgroundColor: Theme.of(context).primaryColor,
        centerTitle: true,
        elevation: 0.0,
        title: const Text(
          "Search",
          style: TextStyle(
            fontSize: 27,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: SearchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search groups....",
                      hintStyle: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    initiateSearchMethod();
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: const Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).primaryColor,
                ),
              )
              : groupList(),
        ],
      ),
    );
  }

  initiateSearchMethod() async {
    if (SearchController.text.isNotEmpty) {
      setState(() {
        isLoading = true;
      });
      await DatabaseService().searchByName(SearchController.text).then((
        snapshot,
      ) {
        setState(() {
          searchSnapshot = snapshot;
          isLoading = false;
          hasUserSearched = true;
        });
      });
    }
  }

  groupList() {
    return hasUserSearched
        ? ListView.builder(
          shrinkWrap: true,
          itemCount: searchSnapshot!.docs.length,
          itemBuilder: (context, index) {
            return groupTile(
              userName,
              searchSnapshot!.docs[index]['groupId'],
              searchSnapshot!.docs[index]['groupName'],
              searchSnapshot!.docs[index]['admin'],
            );
          },
        )
        : Container();
  }

  joinedOrNot(
    String userName,
    String groupId,
    String groupName,
    String admin,
  ) async {
    await DatabaseService(
      uid: user!.uid,
    ).isUserJoined(groupName, groupId, userName).then((value) {
      setState(() {
        isJoined = value;
      });
    });
  }

  Widget groupTile(
    String userName,
    String groupId,
    String groupName,
    String admin,
  ) {
    joinedOrNot(userName, groupId, groupName, admin);
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor,
        radius: 30,
        child: Text(
          groupName.substring(0, 1).toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      title: Text(
        groupName,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        "Admin: ${getName(admin)}",
        style: const TextStyle(fontSize: 13),
      ),
      trailing: InkWell(
        onTap: () async {
          await DatabaseService(
            uid: user!.uid,
          ).toggleGroupJoin(groupId, userName, groupName);
          if (isJoined) {
            setState(() {
              isJoined = !isJoined;
            });
            showSnackBar(
              context,
              Colors.green,
              "Successfully Joined the group",
            );
            Future.delayed(Duration(seconds: 2), () {
              nextScreen(
                context,
                ChatPage(
                  userName: userName,
                  groupId: groupId,
                  groupName: groupName,
                ),
              );
            });
          } else {
            setState(() {
              isJoined = !isJoined;
            });
            showSnackBar(context, Colors.red, "Left the group $groupName");
          }
        },
        child:
            isJoined
                ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black,
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: const Text(
                    "Joined",
                    style: TextStyle(color: Colors.white),
                  ),
                )
                : Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Theme.of(context).primaryColor,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: const Text(
                    "Join Now",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
      ),
    );
  }
}
