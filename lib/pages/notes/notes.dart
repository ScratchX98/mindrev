import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;


import 'package:mindrev/models/mindrev_settings.dart';
import 'package:mindrev/models/mindrev_notes.dart';
import 'package:mindrev/services/db.dart';
import 'package:mindrev/widgets/widgets.dart';

import 'package:path_provider/path_provider.dart';

class Notes extends StatefulWidget {
  const Notes({Key? key}) : super(key: key);

  @override
  State<Notes> createState() => _NotesState();
}

class _NotesState extends State<Notes> {
  //what this file does is determine whether we want to edit with markdown or zefyrka, as
  //defined in settings, and route to correct editor
  MindrevSettings? settings;
  MindrevNotes? notes;
  Map? routeData;
  String imgDirectory = '';

  @override
  void initState() {
    super.initState();
    local
        .getSettings()
        .then((MindrevSettings settings) => setState(() => this.settings = settings));
  }

  @override
  void didChangeDependencies() {
    routeData = ModalRoute.of(context)?.settings.arguments as Map;
    local
        .getMaterialData(routeData!['material'], routeData!['topic'], routeData!['class'])
        .then(
      (value) async {
        if (!kIsWeb) {
          await getApplicationSupportDirectory().then(
                (value) =>
            //get support directory and material path to display images
            imgDirectory = value.path +
                '/data' +
                '/${routeData!['class'].name}' +
                '/${routeData!['topic'].name}' +
                '/${routeData!['material'].name}/',
          );
        }
        setState(() {
          routeData?['imgDirectory'] = imgDirectory;
          notes = value;
        });
      },
    );
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    if (settings != null && notes != null) {
      SchedulerBinding.instance!.addPostFrameCallback((_) async {
        routeData!['notes'] = notes;
        routeData!['formatBar'] = settings!.markdownEdit;
        Navigator.pushReplacementNamed(context, '/markdownEditor', arguments: routeData);
      });
    }
    return loading();
  }
}
