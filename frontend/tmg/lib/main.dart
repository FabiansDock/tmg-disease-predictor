import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:another_flutter_splash_screen/another_flutter_splash_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Image Upload and API Example',
      // home: ImageUploadPage(),
      debugShowCheckedModeBanner: false,
      home: FlutterSplashScreen.gif(
          gifPath: 'assets/8l85ot.gif',
          gifWidth: 269,
          gifHeight: 474,
          nextScreen: ImageUploadPage(),
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
    request.files.add(await http.MultipartFile.fromPath('image', _imageFile!.path));

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
        _responseText = "Failed to upload image. Status code: ${response.statusCode}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('TMG Plant Disease Predictor'),
        backgroundColor: Color.fromARGB(255, 3, 180, 95),
        foregroundColor: Color.fromARGB(255, 255, 255, 197),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedOpacity(
                duration: Duration(milliseconds: 800), // Duration of the animation
                opacity: _isAnimated ? 1.0 : 0.0, // Set opacity based on animation trigger
                child: _imageFile == null
                    ? Text('No image selected.')
                    : Image.file(_imageFile!),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  _getImage(ImageSource.gallery);
                },
                child: Text('Pick Image from Gallery'),
              ),
              ElevatedButton(
                onPressed: () {
                  _getImage(ImageSource.camera);
                },
                child: Text('Take a Picture'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadImage,
                child: Text('Upload Image and Send to API'),
              ),
              SizedBox(height: 20),
              _responseText == null
                  ? Container()
                  : Text(_responseText!),
            ],
          ),
        ),
      ),
    );
  }
}
