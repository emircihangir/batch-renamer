import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Batch Renamer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Map<String, String> startORend = {};
  String alphabet = 'abcdefghijklmnopqrstuvwxyz';

  List<List> actionList = [];
  Map<String, String> files = {};
  Map<String, TextEditingController> controllers = {};

  void saveFileNames() async {
    if (Platform.isMacOS) {
      List<String> oldPaths = [];
      for (var i = 0; i < files.keys.length; i++) {
        String element = files.keys.toList()[i];
        List a = element.split('/');
        a.removeLast();
        a.add(files[element]);

        String newPath = a.join('/');

        try {
          await File(element).rename(newPath);
          files[newPath] = files[element]!;
          if (element != newPath) {
            oldPaths.add(element);
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }

      for (var element in oldPaths) {
        files.remove(element);
      }

      setState(() {});
    }
  }

  List<dynamic> processSpecialSyntax({String? text, int? counter}) {
    String typedText = text!;
    int endIndex() {
      List<String> a = typedText.split('');

      int r = 0;
      for (var i = 0; i < a.length; i++) {
        if (i > a.indexOf('*') && int.tryParse(a[i]) == null && a[i] != '-' && alphabet.contains(a[i].toLowerCase()) == false) {
          r = i;
          break;
        } else {
          r = i + 1;
        }
      }

      return r;
    }

    if (text.contains('*')) {
      List<String> b = text.substring(typedText.indexOf('*'), endIndex()).replaceAll('*', '').split('-');
      //* check whether it's a number or not.
      if (int.tryParse(b[0]) != null) {
        //* apply incrementing number.
        if (counter == null) {
          //* set the counter for the first time.
          counter = int.parse(b[0]);
        } else {
          //* increase the counter.
          counter += int.parse(b[1]) - int.parse(b[0]);
        }

        //* edit the name of the file.
        typedText = typedText.replaceAll(typedText.substring(typedText.indexOf('*'), endIndex()), counter.toString());
      } else {
        //* apply alphabet.
        if (counter == null) {
          //* set the counter for the first time.
          counter = 0;
        } else {
          //* increase the counter.
          counter += 1;
        }
        if (counter < alphabet.split('').length) {
          typedText = typedText.replaceAll(typedText.substring(typedText.indexOf('*'), endIndex()), b[0].toUpperCase() == b[0] ? alphabet.split('')[counter].toUpperCase() : alphabet.split('')[counter]);
        } else {
          typedText = typedText.replaceAll(typedText.substring(typedText.indexOf('*'), endIndex()), b[0].toUpperCase() == b[0] ? (alphabet.split('')[counter % alphabet.split('').length].toUpperCase() * ((counter / alphabet.split('').length).floor() + 1)) : (alphabet.split('')[counter % alphabet.split('').length] * ((counter / alphabet.split('').length).floor() + 1)));
        }
      }
    }

    return [
      typedText,
      counter
    ];
  }

  void previewActions() {
    //* if the action list is empty, revert the names to their original version.
    if (controllers.keys.isEmpty) {
      setState(() {
        for (var element in files.keys) {
          files[element] = element.split('/').last;
        }
      });
      return;
    }

    for (var element in controllers.keys) {
      if (element.startsWith('replace1')) {
        int? counter;
        for (var element2 in files.keys) {
          String originalName = '';

          if (controllers.keys.toList().indexOf(element) == 0) {
            originalName = element2.split('/').last;
          } else {
            originalName = files[element2]!;
          }

          List a = originalName.split('.');
          a.removeLast();
          originalName = a.join('.');

          String typedText = controllers[element.replaceAll('replace1', 'replace2')]!.text;
          if (originalName.contains(controllers[element]!.text)) {
            List p = processSpecialSyntax(text: controllers[element.replaceAll('replace1', 'replace2')]!.text, counter: counter);
            typedText = p[0];
            counter = p[1];
          }

          setState(() {
            files[element2] = '${originalName.replaceAll(controllers[element]!.text, typedText)}.${files[element2]!.split('.').last}';
          });
        }
      } else if (element.startsWith('prefix') || element.startsWith('suffix')) {
        int? counter;

        for (var element2 in files.keys) {
          String originalName = '';

          //* if it's a hidden file, skip it. We don't want to edit hidden files.
          if (element2.split('/').last.startsWith('.')) continue;

          if (controllers.keys.toList().indexOf(element) == 0) {
            originalName = element2.split('/').last;
          } else {
            originalName = files[element2]!;
          }

          //* remove the file extension. We don't want to edit that.
          List a = originalName.split('.');
          a.removeLast();
          originalName = a.join('.');

          List p = processSpecialSyntax(text: controllers[element.replaceAll('replace1', 'replace2')]!.text, counter: counter);
          String typedText = p[0];
          counter = p[1];
          setState(() {
            if (element.startsWith('prefix')) {
              files[element2] = '$typedText$originalName.${files[element2]!.split('.').last}';
            } else {
              files[element2] = '$originalName$typedText.${files[element2]!.split('.').last}';
            }
          });
        }
      } else if (element.startsWith('rename')) {
        int? counter;

        for (var element2 in files.keys) {
          String originalName = '';

          //* if it's a hidden file, skip it. We don't want to edit hidden files.
          if (element2.split('/').last.startsWith('.')) continue;

          if (controllers.keys.toList().indexOf(element) == 0) {
            originalName = element2.split('/').last;
          } else {
            originalName = files[element2]!;
          }

          //* remove the file extension. We don't want to edit that.
          List a = originalName.split('.');
          a.removeLast();
          originalName = a.join('.');

          List p = processSpecialSyntax(text: controllers[element.replaceAll('replace1', 'replace2')]!.text, counter: counter);
          String typedText = p[0];
          counter = p[1];

          setState(() {
            files[element2] = '$typedText.${files[element2]!.split('.').last}';
          });
        }
      } else if (element.startsWith('cutStart')) {
        for (var element2 in files.keys) {
          String originalName = '';
          if (controllers.keys.toList().indexOf(element) == 0) {
            originalName = element2.split('/').last;
          } else {
            originalName = files[element2]!;
          }

          List a = originalName.split('.');
          a.removeLast();
          originalName = a.join('.');

          setState(() {
            try {
              files[element2] = '${originalName.substring(int.parse(controllers[element]!.text))}.${files[element2]!.split('.').last}';
            } on RangeError {
              files[element2] = '.${files[element2]!.split('.').last}';
            }
          });
        }
      } else if (element.startsWith('cutEnd')) {
        for (var element2 in files.keys) {
          String originalName = '';
          if (controllers.keys.toList().indexOf(element) == 0) {
            originalName = element2.split('/').last;
          } else {
            originalName = files[element2]!;
          }

          List a = originalName.split('.');
          a.removeLast();
          originalName = a.join('.');

          setState(() {
            try {
              files[element2] = '${originalName.substring(0, originalName.length - int.parse(controllers[element]!.text))}.${files[element2]!.split('.').last}';
            } on RangeError {
              files[element2] = '.${files[element2]!.split('.').last}';
            }
          });
        }
      }
    }
  }

  List<Widget> getActionsListChildren() {
    List<Widget> arr = [];
    try {
      for (var element in actionList) {
        arr.add(element[1]);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return arr;
  }

  Widget cutEndActionWidget({required String? key}) {
    try {
      const Uuid().v4();

      controllers['cutEnd;$key'] = TextEditingController();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var e in actionList) {
                    if (e[0].contains(key)) {
                      actionList.remove(e);
                      break;
                    }
                  }
                  controllers.remove('cutEnd;$key');
                });
                try {
                  previewActions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              )),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.deepPurple,
          ),
          const Text('Cut'),
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['cutEnd;$key'],
                decoration: const InputDecoration(hintText: 'how many?', hintStyle: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const Text('characters from the end.')
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
      return const SizedBox();
    }
  }

  Widget cutStartActionWidget({required String? key}) {
    try {
      const Uuid().v4();

      controllers['cutStart;$key'] = TextEditingController();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var e in actionList) {
                    if (e[0].contains(key)) {
                      actionList.remove(e);
                      break;
                    }
                  }
                  controllers.remove('cutStart;$key');
                });

                try {
                  previewActions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              )),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.deepPurple,
          ),
          const Text('Cut'),
          Container(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['cutStart;$key'],
                decoration: const InputDecoration(hintText: 'how many?', hintStyle: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const Text('characters from the start.')
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
      return const SizedBox();
    }
  }

  Widget renameActionWidget({required String? key}) {
    try {
      const Uuid().v4();

      controllers['rename;$key'] = TextEditingController();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var e in actionList) {
                    if (e[0].contains(key)) {
                      actionList.remove(e);
                      break;
                    }
                  }
                  controllers.remove('rename;$key');
                });

                try {
                  previewActions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              )),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.deepPurple,
          ),
          const Text('Rename'),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['rename;$key'],
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );

      return const SizedBox();
    }
  }

  Widget suffixActionWidget({required String? key}) {
    try {
      const Uuid().v4();

      controllers['suffix;$key'] = TextEditingController();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var e in actionList) {
                    if (e[0].contains(key)) {
                      actionList.remove(e);
                      break;
                    }
                  }
                  controllers.remove('suffix;$key');
                });

                try {
                  previewActions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              )),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.deepPurple,
          ),
          const Text('Add suffix'),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['suffix;$key'],
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
      return const SizedBox();
    }
  }

  Widget prefixActionWidget({required String? key}) {
    try {
      controllers['prefix;$key'] = TextEditingController();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var e in actionList) {
                    if (e[0].contains(key)) {
                      actionList.remove(e);
                      break;
                    }
                  }
                  controllers.remove('prefix;$key');
                });

                try {
                  previewActions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              )),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.deepPurple,
          ),
          const Text('Add prefix'),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['prefix;$key'],
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
      return const SizedBox();
    }
  }

  Widget replaceActionWidget({required String? key}) {
    try {
      controllers['replace1;$key'] = TextEditingController();
      controllers['replace2;$key'] = TextEditingController();

      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
              onPressed: () {
                setState(() {
                  for (var e in actionList) {
                    if (e[0].contains(key)) {
                      actionList.remove(e);
                      break;
                    }
                  }
                  controllers.remove('replace1;$key');
                  controllers.remove('replace2;$key');
                });

                try {
                  previewActions();
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Error.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }

                // print(controllers);
                // print(actionList);
              },
              icon: const Icon(
                Icons.close,
                color: Colors.red,
              )),
          const Icon(
            Icons.chevron_right_rounded,
            color: Colors.deepPurple,
          ),
          const Text('Replace'),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['replace1;$key'],
                decoration: const InputDecoration(hintText: 'this text'),
              ),
            ),
          ),
          const Text('with'),
          Flexible(
            flex: 1,
            fit: FlexFit.tight,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: controllers['replace2;$key'],
                decoration: const InputDecoration(hintText: 'this text'),
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
      return const SizedBox();
    }
  }

  void addToActionList({String? action, dynamic value}) {
    try {
      setState(() {
        actionList.add([
          action,
          value
        ]);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void selectFiles() async {
    try {
      FilePickerResult? selectedFiles = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: true,
      );

      if (selectedFiles != null) {
        //* add the files from the selected directory to the list.
        if (Platform.isMacOS) {
          for (var element in selectedFiles.files) {
            files[element.path!] = element.name;
          }
          //setState(() {});
          try {
            previewActions();
          } catch (e) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Error.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {}
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<List<Widget>> returnFilesListviewChildrenForPreview() async {
    List<Widget> arr = [
      const Padding(
        padding: EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Original Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            Text(
              'Edited Name',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            )
          ],
        ),
      )
    ];

    try {
      for (var element in files.keys) {
        if (Platform.isMacOS) {
          arr.add(Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(child: SelectableText('${element.split('/').last}\t')),
                (element.split('/').last == files[element]!)
                    ? Flexible(
                        child: SelectableText(
                        files[element]!,
                        textAlign: TextAlign.end,
                      ))
                    : Flexible(
                        child: SelectableText(
                          files[element]!,
                          textAlign: TextAlign.end,
                          style: const TextStyle(backgroundColor: Color.fromARGB(255, 227, 210, 255)),
                        ),
                      )
              ],
            ),
          ));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error.'),
          backgroundColor: Colors.red,
        ),
      );
    }

    return arr;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Column(
                children: [
                  const SizedBox(
                      width: double.infinity,
                      child: Text(
                        'Actions',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      )),
                  Column(
                    children: getActionsListChildren(),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: PopupMenuButton<String>(
                      tooltip: '',
                      icon: const Row(
                        children: [
                          Icon(Icons.arrow_drop_down),
                          Text('Choose action to add')
                        ],
                      ),
                      onSelected: (String value) {},
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          onTap: () {
                            String uk = const Uuid().v4();
                            addToActionList(action: 'replace$uk', value: replaceActionWidget(key: uk));
                          },
                          value: 'replace',
                          child: const Text(
                            'Replace',
                          ),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            String uk = const Uuid().v4();
                            addToActionList(action: 'addPrefix$uk', value: prefixActionWidget(key: uk));
                          },
                          value: 'add_prefix',
                          child: const Text('Add prefix'),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            String uk = const Uuid().v4();
                            addToActionList(action: 'addSuffix$uk', value: suffixActionWidget(key: uk));
                          },
                          value: 'add_suffix',
                          child: const Text('Add suffix'),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            String uk = const Uuid().v4();
                            addToActionList(action: 'rename$uk', value: renameActionWidget(key: uk));
                          },
                          value: 'rename',
                          child: const Text('Rename'),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            String uk = const Uuid().v4();
                            addToActionList(action: 'cutStart$uk', value: cutStartActionWidget(key: uk));
                          },
                          child: const Text('Cut from the start'),
                        ),
                        PopupMenuItem<String>(
                          onTap: () {
                            String uk = const Uuid().v4();
                            addToActionList(action: 'cutEnd$uk', value: cutEndActionWidget(key: uk));
                          },
                          child: const Text('Cut from the end'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                            onPressed: () {
                              try {
                                previewActions();
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Error.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            child: const Text('Preview')),
                        FilledButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (BuildContext builder) {
                                    return AlertDialog(
                                      title: Text('Are you sure?'),
                                      actions: <Widget>[
                                        TextButton(
                                          child: Text('No'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Yes'),
                                          onPressed: () {
                                            try {
                                              saveFileNames();
                                            } catch (e) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Error.'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }

                                            Navigator.of(context).pop();
                                          },
                                        ),
                                      ],
                                    );
                                  });
                            },
                            child: const Text('Save')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              flex: 1,
              fit: FlexFit.tight,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(
                        child: Text(
                          'Files',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          (files.keys.isNotEmpty)
                              ? TextButton(
                                  onPressed: () {
                                    setState(() {
                                      files = {};
                                    });
                                  },
                                  child: const Text('Clear List'))
                              : const SizedBox(),
                          TextButton(
                            onPressed: selectFiles,
                            child: (files.keys.isEmpty) ? const Text('Select') : const Text('Add Files'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  FutureBuilder(
                    future: returnFilesListviewChildrenForPreview(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else {
                        return Expanded(
                          child: ListView(
                            scrollDirection: Axis.vertical,
                            children: snapshot.data ?? [],
                          ),
                        );
                      }
                    },
                  )
                ],
              ),
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const HelpPage()),
          );
        },
        hoverElevation: 0,
        focusElevation: 0,
        highlightElevation: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(
          Icons.help,
        ),
      ),
    );
  }
}

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Help',
          textAlign: TextAlign.start,
        ),
        centerTitle: false,
      ),
      body: const Padding(
        padding: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Special Syntax: *1-2-3    *2-4-6    *a-b-c    *A-B-C',
              textAlign: TextAlign.start,
            ),
          ],
        ),
      ),
      backgroundColor: Colors.white,
    );
  }
}
