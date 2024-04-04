import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart';
import 'package:permission_handler/permission_handler.dart';

class Preview extends StatefulWidget {
  const Preview({super.key});

  @override
  State<Preview> createState() => _PreviewState();
}

class _PreviewState extends State<Preview> {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  var textController = TextEditingController();

  @override
  void initState() {
    _requestLocationPermission();
    initializeCamera();
    super.initState();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  Future<void> _requestLocationPermission() async {
    var status = await Permission.location.status;
    if (status.isDenied || status.isPermanentlyDenied) {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.location,
      ].request();
      print(statuses[Permission.location]);
    }
  }

  void initializeCamera() async {
    cameras = await availableCameras();
    cameraController = CameraController(
      cameras[0],
      ResolutionPreset.high,
    );
    await cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((error) => print(error));
  }

  void cameraTakePicture() async {
    if (textController.text.isNotEmpty) {
      try {
        final image = await cameraController.takePicture();
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        var request = MultipartRequest(
          'POST',
          Uri.parse('https://flutter-sandbox.free.beeceptor.com/upload_photo/'),
        );
        request.fields['comment'] = textController.text;
        request.fields['latitude'] = position.latitude.toString();
        request.fields['longitude'] = position.longitude.toString();
        request.files.add(await MultipartFile.fromPath('photo', image.path));
        var response = await request.send();
        if (response.statusCode == 200) print('data has been sent');
        textController.clear();
      } catch (error) {
        print(error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        body: Stack(
          children: [
            Container(
                constraints: BoxConstraints.expand(),
                child: CameraPreview(cameraController)),
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                          hintText: 'Comment here', filled: true),
                      controller: textController,
                    ),
                    const SizedBox(height: 15),
                    FloatingActionButton(
                      shape: const CircleBorder(),
                      onPressed: cameraTakePicture,
                      child: const Icon(Icons.camera_alt_rounded),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    } catch (e) {
      return Container();
    }
  }
}
