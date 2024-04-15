import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';

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
        _responseText = "Please select an image first.";
      });
      return;
    }

    // API endpoint to upload the image
    String apiUrl = "http://10.0.2.2:5000/predict";

    // Prepare the request body
    var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
    request.files
        .add(await http.MultipartFile.fromPath('image', _imageFile!.path));

    // Send the request
    var streamedResponse = await request.send();

    // Get the response
    var response = await http.Response.fromStream(streamedResponse);

    // Handle the response
    if (response.statusCode == 200) {
      setState(() {
        _responseText = response.body;
      });
    } else {
      setState(() {
        _responseText = "Please retake the image !";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                duration: const Duration(
                    milliseconds: 800), // Duration of the animation
                opacity: _isAnimated
                    ? 1.0
                    : 0.0, // Set opacity based on animation trigger
                child: _imageFile == null
                    ? const Text('No image selected.')
                    : Image.file(_imageFile!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _getImage(ImageSource.gallery);
                },
                child: const Text('Pick Image from Gallery'),
              ),
              ElevatedButton(
                onPressed: () {
                  _getImage(ImageSource.camera);
                },
                child: const Text('Take a Picture'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: const Text('Upload Image and Send to API'),
              ),
              const SizedBox(height: 40),
              _responseText == null
                  ? Container()
                  : _responseText!.length > 50 ? Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Text(
                            'Disease Name: \n\t${jsonDecode(_responseText!)[2]['Disease Name']}\n\n'),
                        Text(
                            'Causitive Agent: \n\t${jsonDecode(_responseText!)[0]['causitive_agent']}\n\n'),
                        Text(
                            'Scientific Name: \n\t${jsonDecode(_responseText!)[0]['scientific_name']}\n\n'),
                        Text(
                            'Symptoms: \n\t${jsonDecode(_responseText!)[0]['symptoms']}\n\n'),
                        Text(
                            'Treatment: \n\t${jsonDecode(_responseText!)[0]['treatment']}\n\n'),
                        Text(
                            'Probability: \n\t${jsonDecode(_responseText!)[1]['Probability']}\n\n'),
                      ],
                    ): Text(_responseText!),
            ],
          ),
        ),
      ),
    );
  }
}
