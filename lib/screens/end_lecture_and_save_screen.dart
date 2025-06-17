//강의 끝나고 나서 나오는 dialog 화면

import 'package:flutter/material.dart';
import '../widgets/end_screen/save_dialog_components.dart';
import 'package:file_picker/file_picker.dart';

class SaveDialogScreen extends StatefulWidget {
  SaveDialogScreen({Key? key}) : super(key: key);

  @override
  State<SaveDialogScreen> createState() => _SaveDialogScreenState();
}

class _SaveDialogScreenState extends State<SaveDialogScreen> {
  // 상태 변수들
  bool isContentFile = false;
  bool isSummaryFile = false; //내용 파일인지 요약 파일인지
  String selectedLocation = ''; //저장 위치
  String? selectedFilePath; //선택된 파일 경로
  String emailAddress = ''; //이메일 주소
  String emailDomain = 'naver.com'; //이메일 도메인 기본값

  @override
  void initState() {
    super.initState();
    debugPrint('=== SaveDialogScreen initState ===');
    debugPrint('초기 isContentFile: $isContentFile');
    debugPrint('초기 isSummaryFile: $isSummaryFile');
  }

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
              isContentFileSelected: isContentFile,
              isSummaryFileSelected: isSummaryFile,
              selectedLocation: selectedLocation,
              selectedFilePath: selectedFilePath,
              emailAddress: emailAddress,
              emailDomain: emailDomain,
              context: context,

              // 콜백 함수들
              onContentFileChanged: (value) {
                setState(() {
                  isContentFile = value;
                });
              },
              onSummaryFileChanged: (value) {
                setState(() {
                  isSummaryFile = value;
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

  // 경로 선택 다이얼로그 표시
  Future<void> _selectPath() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      setState(() {
        selectedFilePath = selectedDirectory;
      });
    }
  }

  // 이메일 전송 버튼 클릭 시 처리
  void _handleEmailSend() {
    Navigator.of(context).pop();
    _showSuccessMessage('이메일이 $emailAddress@$emailDomain로 전송되었습니다');
    //_navigateToEndScreen('이메일 전송 완료');
  }

  // 파일 저장 버튼 클릭 시 처리
  void _handleFileSave() {
    Navigator.of(context).pop();
    _showSuccessMessage('파일이 저장되었습니다\n$selectedFilePath');
    //_navigateToEndScreen('파일 저장 완료');
  }

  // 저장 성공 메시지 표시
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}