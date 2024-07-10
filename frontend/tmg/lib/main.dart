import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';

enum PlantCategory { grapes, mango, tomato }

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload and API Example',
      // home: ImageUploadPage(),
      debugShowCheckedModeBanner: false,
      home: FlutterSplashScreen.gif(
        backgroundColor: const Color.fromARGB(95, 255, 255, 255),
        gifPath: 'assets/8l85ot.gif',
        gifWidth: 600,
        gifHeight: 600,
        nextScreen: const ImageUploadPage(),
        duration: const Duration(milliseconds: 3515),
        onInit: () async {
          debugPrint("onInit");
        },
        onEnd: () async {
          debugPrint("onEnd 1");
        },
      ),
    );
  }
}

class ImageUploadPage extends StatefulWidget {
  const ImageUploadPage({super.key});

  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _imageFile;
  String? _responseText;
  PlantCategory? _plant = PlantCategory.grapes;
  var fontColor = Colors.purple[900];

  final ImagePicker _picker = ImagePicker();
  bool _isAnimated = false;

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    setState(() {
      _imageFile = File(pickedFile!.path);
      _isAnimated = true; // Set to true to trigger the animation
    });
  }

  Future<void> _uploadImage() async {
    if (_imageFile == null) {
      setState(() {
        _responseText = '{"message": "Please select an image first."}';
      });
      return;
    }

    String apiUrl = 'http://localhost:5000/predict';
    if (Platform.isAndroid || Platform.isIOS) {
      apiUrl = 'http://10.0.2.2:5000/predict';
    }

    // Prepare the request body
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files
        .add(await http.MultipartFile.fromPath('image', _imageFile!.path));
    request.fields['category'] = _plant!.index.toString();

    // Send the request
    var streamedResponse = await request.send();

    // Get the response
    var response = await http.Response.fromStream(streamedResponse);

    // Handle the response
    if (response.statusCode == 200) {
      setState(() {
        _responseText = response.body;
      });
    } else if (response.statusCode == 500) {
      setState(() {
        _responseText = '{"message": "Server error !"}';
      });
    } else {
      setState(() {
        _responseText = '{"message": "Please retake the image !"}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var infoColor = Colors.white;
    const fontSize = 20.0;
    const fontWeight = FontWeight.bold;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 26, 26, 26),
      appBar: AppBar(
        title: const Text('TMG Plant Disease Predictor'),
        backgroundColor: const Color.fromARGB(255, 3, 180, 95),
        foregroundColor: const Color.fromARGB(255, 255, 255, 197),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                duration: const Duration(milliseconds: 800),
                opacity: _isAnimated ? 1.0 : 0.0,
                child: _imageFile == null
                    ? const Text('No image selected.')
                    : Image.file(
                        _imageFile!,
                        width: 400,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
              ),
              ListTile(
                title: Text(
                  'Grapes',
                  style: TextStyle(color: Colors.purple[400]),
                ),
                leading: Radio<PlantCategory>(
                  value: PlantCategory.grapes,
                  groupValue: _plant,
                  onChanged: (PlantCategory? value) {
                    setState(() {
                      _plant = value;
                      fontColor = Colors.purple[400];
                      _responseText = null;
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  'Mango',
                  style: TextStyle(color: Colors.yellow[400]),
                ),
                leading: Radio<PlantCategory>(
                  value: PlantCategory.mango,
                  groupValue: _plant,
                  onChanged: (PlantCategory? value) {
                    setState(() {
                      _plant = value;
                      fontColor = Colors.yellow[400];
                      _responseText = null;
                    });
                  },
                ),
              ),
              ListTile(
                title: Text(
                  'Tomato',
                  style: TextStyle(color: Colors.red[400]),
                ),
                leading: Radio<PlantCategory>(
                  value: PlantCategory.tomato,
                  groupValue: _plant,
                  onChanged: (PlantCategory? value) {
                    setState(() {
                      _plant = value;
                      fontColor = Colors.red[400];
                      _responseText = null;
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                onPressed: () {
                  _getImage(ImageSource.gallery);
                  setState(() {
                    _responseText = null;
                  });
                },
                child: const Text('Pick Image from Gallery'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                onPressed: () {
                  _getImage(ImageSource.camera);
                  setState(() {
                    _responseText = null;
                  });
                },
                child: const Text('Take a Picture'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.black),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                ),
                onPressed: _uploadImage,
                child: const Text('Predict the Disease'),
              ),
              const SizedBox(height: 40),
              _responseText == null
                  ? Container()
                  : _responseText!.length > 100
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Disease Name:',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: fontWeight,
                                fontSize: fontSize,
                              ),
                            ),
                            Text(
                              '\t${jsonDecode(_responseText!)['Disease Name']}\n\n',
                              style: TextStyle(
                                color: infoColor,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'Causitive Agent:',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: fontWeight,
                                fontSize: fontSize,
                              ),
                            ),
                            Text(
                              '\t${jsonDecode(_responseText!)['causitive_agent']}\n\n',
                              style: TextStyle(
                                color: infoColor,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'Symptoms:',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: fontWeight,
                                fontSize: fontSize,
                              ),
                            ),
                            Text(
                              '\t${jsonDecode(_responseText!)['symptoms']}\n\n',
                              style: TextStyle(
                                color: infoColor,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'Treatment:',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: fontWeight,
                                fontSize: fontSize,
                              ),
                            ),
                            Text(
                              '\t${jsonDecode(_responseText!)['treatment']}\n\n',
                              style: TextStyle(
                                color: infoColor,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            Text(
                              'Probability:',
                              style: TextStyle(
                                color: fontColor,
                                fontWeight: fontWeight,
                                fontSize: fontSize,
                              ),
                            ),
                            Text(
                              '\t${(double.parse(jsonDecode(_responseText!)['Probability']) * 100).toStringAsFixed(2)} %\n\n',
                              style: TextStyle(
                                color: infoColor,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          ],
                        )
                      : Text(
                          jsonDecode(_responseText!)['message'] + "😁😁😁",
                          style: TextStyle(
                            color: infoColor,
                            fontWeight: fontWeight,
                            fontSize: fontSize,
                          ),
                        ),
            ],
          ),
        ),
      ),
    );
  }
}
