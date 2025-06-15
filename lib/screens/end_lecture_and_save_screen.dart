import 'package:flutter/material.dart';
import '../widgets/end_screen/save_dialog_components.dart';
import 'package:file_picker/file_picker.dart';

class SaveDialogScreen extends StatefulWidget {
  const SaveDialogScreen({Key? key}) : super(key: key);

  @override
  State<SaveDialogScreen> createState() => _SaveDialogScreenState();
}

class _SaveDialogScreenState extends State<SaveDialogScreen> {
  // 상태 변수들
  bool isContentFile = false;
  String selectedLocation = '';
  String? selectedFilePath;
  String emailAddress = '';
  String emailDomain = 'naver.com';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: const Color(0xFFE5E5E5),
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SaveDialogComponents에서 빌드한 메인 섹션
            SaveDialogComponents.buildMainSection(
              isContentFile: isContentFile,
              selectedLocation: selectedLocation,
              selectedFilePath: selectedFilePath,
              emailAddress: emailAddress,
              emailDomain: emailDomain,
              onContentFileChanged: (value) {
                setState(() {
                  isContentFile = value;
                });
              },
              onLocationChanged: (location) {
                setState(() {
                  selectedLocation = location;
                });
              },
              onEmailAddressChanged: (address) {
                setState(() {
                  emailAddress = address;
                });
              },
              onEmailDomainChanged: (domain) {
                setState(() {
                  emailDomain = domain;
                });
              },
              onSelectPath: _selectPath,
              onEmailSend: _handleEmailSend,
              onFileSave: _handleFileSave,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        selectedFilePath = selectedDirectory;
      });
    }
  }

  void _handleEmailSend() {
    Navigator.of(context).pop();
    _showSuccessMessage('이메일이 $emailAddress@$emailDomain로 전송되었습니다');
    //_navigateToEndScreen('이메일 전송 완료');
  }

  void _handleFileSave() {
    Navigator.of(context).pop();
    _showSuccessMessage('파일이 저장되었습니다\n$selectedFilePath');
    //_navigateToEndScreen('파일 저장 완료');
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}