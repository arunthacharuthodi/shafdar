//comming soon page

import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:intl/intl.dart';
import 'package:notes_app/config/color.dart';

class VoteNow extends StatefulWidget {
  const VoteNow({super.key});

  @override
  State<VoteNow> createState() => _VoteNowState();
}

class _VoteNowState extends State<VoteNow> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    // init();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorCOnfig().primary_color,
        appBar: AppBar(
          backgroundColor: ColorCOnfig().primary_color,
          title: const Text('Vote Now'),
        ),
        body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('Elections')
                .orderBy('end_date', descending: true)
                .snapshots(),
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return Text('Something went wrong');
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.all(5),
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: ColorCOnfig().secondary,
                        borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      subtitle: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Text(
                            "Start Date : ${DateFormat.yMMMMEEEEd().format(snapshot.data!.docs[index]['start_date'].toDate())}",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Text(
                            "End Date :${DateFormat.yMMMMEEEEd().format(snapshot.data!.docs[index]['end_date'].toDate())}",
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                      title: Text(
                        snapshot.data!.docs[index]['name'],
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                      trailing: BlocUnwanted(
                        isOver: DateTime.now().isAfter(
                                snapshot.data!.docs[index]['end_date'].toDate())
                            ? false
                            : true,
                        candidateId: snapshot.data!.docs[index].id,
                        index: index,
                        snapshot: snapshot,
                      ),
                      // onTap: () {
                      //   Navigator.of(context).push(MaterialPageRoute(
                      //       builder: (context) => VotingBooth(
                      //             CandidateId: snapshot.data!.docs[index].id,
                      //           )));
                      // },
                    ),
                  );
                },
              );
            }));
  }
}

class BlocUnwanted extends StatefulWidget {
  final String candidateId;
  AsyncSnapshot<QuerySnapshot<Object?>> snapshot;
  int index;
  bool isOver;

  BlocUnwanted(
      {super.key,
      required this.isOver,
      required this.candidateId,
      required this.index,
      required this.snapshot});

  @override
  State<BlocUnwanted> createState() => _BlocUnwantedState();
}

class _BlocUnwantedState extends State<BlocUnwanted> {
  bool already_done = false;
  bool is_loading = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    init();
  }

  Future init() async {
    setState(() {
      is_loading = true;
    });
    final collectionInstance = await FirebaseFirestore.instance
        .collection('Elections')
        .doc(widget.snapshot.data!.docs[widget.index].id)
        .collection('candidates')
        .where('votes', arrayContains: FirebaseAuth.instance.currentUser!.uid)
        .get();
    if (collectionInstance.docs.isNotEmpty) {
      setState(() {
        already_done = true;
      });
    }
    setState(() {
      is_loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return is_loading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          )
        : already_done
            ? Text(
                "Already Votted",
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              )
            : widget.isOver
                ? ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => VotingBooth(
                                CandidateId:
                                    widget.snapshot.data!.docs[widget.index].id,
                              )));
                    },
                    child: Text("Vote Now"))
                : Text(
                    "Election ended",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  );
  }
}

class VotingBooth extends StatefulWidget {
  final String CandidateId;

  const VotingBooth({required this.CandidateId});

  @override
  State<VotingBooth> createState() => _VotingBoothState();
}

class _VotingBoothState extends State<VotingBooth> {
  int id = 0;
  String CandidateId = "";

  @override
  Widget build(BuildContext context) {
    log(id.toString());
    return Scaffold(
        appBar: AppBar(
          title: Text('Voting Booth'),
        ),
        body: Column(
          children: [
            Expanded(
                child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('Elections')
                        .doc(widget.CandidateId)
                        .collection('candidates')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.hasError) {
                        return Text('Something went wrong');
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(),
                        );
                      }
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: id == index ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              title: Text(snapshot.data!.docs[index]['name']),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                setState(() {
                                  id = index;
                                  CandidateId = snapshot.data!.docs[index].id;
                                });
                              },
                            ),
                          );
                        },
                      );
                    })),
            Container(
              margin: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(30),
              ),
              child: ListTile(
                title: Center(child: const Text('Submit Vote')),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  setState(() {
                    try {
                      final ref = FirebaseFirestore.instance
                          .collection('Elections')
                          .doc(widget.CandidateId)
                          .collection('candidates')
                          .doc(CandidateId)
                          .set({
                        'votes': FieldValue.arrayUnion(
                            [FirebaseAuth.instance.currentUser!.uid])

                        // 'votes': FieldValue.increment(1),
                      }, SetOptions(merge: true));
                      Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => VoteNow(),
                          ),
                          (route) => false);
                    } on FirebaseAuthException catch (e) {
                      print(e.message);
                    }
                  });
                },
              ),
            ),
          ],
        ));
  }
}
