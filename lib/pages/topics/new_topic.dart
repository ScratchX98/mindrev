import 'package:flutter/material.dart';
import 'package:mindrev/models/mindrev_topic.dart';

import 'package:mindrev/services/text.dart';
import 'package:mindrev/services/text_color.dart';
import 'package:mindrev/widgets/widgets.dart';
import 'package:mindrev/extra/theme.dart';

import 'package:hexcolor/hexcolor.dart';
import 'package:hive_flutter/hive_flutter.dart';

class NewTopic extends StatefulWidget {
  const NewTopic({Key? key}) : super(key: key);

  @override
  State<NewTopic> createState() => _NewTopicState();
}

class _NewTopicState extends State<NewTopic> {
  //futures that will be awaited by FutureBuilder
  Map routeData = {};
  Future futureText = readText('newTopic');

  //variables for form
  final _formKey = GlobalKey<FormState>();
  String? newTopicName;

  //function to create a new topic
  Future<bool> newTopic(String name, String className) async {
    var box = Hive.lazyBox('mindrev');

    //retrieve topics in right class
    List classes = await box.get('classes');
    List topics = await classes.firstWhere((element) => element.name == className).topics;

    //check if the topic already exists
    for (MindrevTopic i in topics) {
      if (i.name == name) return false;
    }

    //write the information
    MindrevTopic newTopic = MindrevTopic(name);
    topics.add(newTopic);
    classes[classes.indexWhere((element) => element.name == className)].topics = topics;
    await box.put('classes', classes);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    //route data to get class information
    routeData = routeData.isNotEmpty ? routeData : ModalRoute.of(context)?.settings.arguments as Map;
    Color contrastColor = textColor(routeData['color']);

    return FutureBuilder(
      future: futureText,
      builder: (BuildContext ctx, AsyncSnapshot<dynamic> snapshot) {
        //only show page when data is loaded
        if (snapshot.hasData) {
          //data loaded with FutureBuilder
          Map text = snapshot.data;

          return Scaffold(
            backgroundColor: theme.primary,
            //appbar
            appBar: AppBar(
              foregroundColor: contrastColor,
              title: Text(text['title']),
              elevation: 10,
              centerTitle: true,
              backgroundColor: HexColor(routeData['color']),
            ),

            //body with everything else
            body: SingleChildScrollView(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      children: <Widget>[
                        Form(
                          key: _formKey,
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                cursorColor: HexColor(routeData['color']),
                                style: defaultPrimaryTextStyle,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return text['errorNoText'];
                                  }
                                  return null;
                                },
                                onSaved: (value) {
                                  setState(() {
                                    newTopicName = value;
                                  });
                                },
                                decoration: defaultPrimaryInputDecoration(text['label']),
                              ),
                              const SizedBox(height: 30),
                              coloredButton(
                                text['submit'],
                                (() async {
                                  if (_formKey.currentState!.validate()) {
                                    _formKey.currentState?.save();
                                    if (newTopicName != null) {
                                      await newTopic('$newTopicName', routeData['selection']);
                                      Navigator.pop(context);
                                      Navigator.pushReplacementNamed(context, '/topics', arguments: routeData);
                                    }
                                  }
                                }),
                                HexColor(routeData['color']),
                                contrastColor,
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        } else {
          return Scaffold(
            //loading screen to be shown until Future is found
            body: loading,
          );
        }
      },
    );
  }
}
