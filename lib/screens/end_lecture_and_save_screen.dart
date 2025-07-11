//강의 끝나고 나서 나오는 dialog 화면
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/end_screen/save_dialog_components.dart';
import 'package:file_picker/file_picker.dart';
import '../services/postprocessor_service.dart';
import '../services/websocket_stt_service.dart';

class SaveDialogScreen extends StatefulWidget {
  const SaveDialogScreen({super.key});

  @override
  State<SaveDialogScreen> createState() => _SaveDialogScreenState();
}

class _SaveDialogScreenState extends State<SaveDialogScreen> {
  // 상태 변수들
  bool isContentFile = false;
  bool isSummaryFile = false; //내용 파일인지 요약 파일인지
  bool isMajorFile = false; //주요 파일인지 여부
  String selectedLocation = ''; //저장 위치
  String? selectedFilePath; //선택된 파일 경로
  String fileName = ''; //파일 이름
  String fileFormat = '.txt'; //파일 형식 (기본값은 .txt)
  String emailAddress = ''; //이메일 주소
  String emailDomain = 'naver.com'; //이메일 도메인 기본값

  final PostProcessorService _llmService = PostProcessorService();
  final WebSocketSTTService _sttService = WebSocketSTTService();
  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _refinedData;

  @override
  void initState() {
    super.initState();
    debugPrint('=== SaveDialogScreen initState ===');
    debugPrint('초기 isContentFile: $isContentFile');
    debugPrint('초기 isSummaryFile: $isSummaryFile');
    debugPrint('초기 isMajorFile: $isMajorFile');

    // 자동으로 LLM 정제 실행
    _processTranscriptAutomatically();
  }

   // 자동으로 STT 내용을 LLM으로 정제
  Future<void> _processTranscriptAutomatically() async {
    if (_sttService.fullTranscriptText.trim().isEmpty) {
      setState(() {
        _statusMessage = '정제할 텍스트가 없습니다';
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusMessage = 'AI가 내용을 정제 중입니다...';
    });

    try {
      // 요약과 핵심 포인트 모두 활성화하여 정제
      final result = await _llmService.refineText(
        fullText: _sttService.fullTranscriptText,
        enableSummarize: true,
        enableKeypoints: true,
        fileFormat: fileFormat.replaceAll('.',''), // 파일 형식에서 '.' 제거
        fileName: fileName,
      );

      if (result != null) {
        setState(() {
          _refinedData = result;
          _statusMessage = 'AI 정제 완료! 저장 옵션을 선택하세요.';
          _isProcessing = false;
        });
      } else {
        setState(() {
          _statusMessage = 'AI 정제에 실패했습니다';
          _isProcessing = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'AI 정제 중 오류가 발생했습니다: $e';
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SaveDialogComponents에서 빌드한 메인 섹션
            SaveDialogComponents.buildMainSection(
              isContentFileSelected: isContentFile,
              isSummaryFileSelected: isSummaryFile,
              isMajorFileSelected: isMajorFile,
              selectedLocation: selectedLocation,
              fileName: fileName,
              fileFormat: fileFormat,
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
              onMajorFileChanged: (value) {
                setState(() {
                  isMajorFile = value;
                });
              },
              onLocationChanged: (location) {
                setState(() {
                  selectedLocation = location;
                });
              },
              onFileNameChanged: (value){
                setState(() {
                  fileName = value;
                });
              },
              onFileFormatChanged: (value){
                setState(() {
                  fileFormat = value;
                });

                // 파일 형식이 변경되면 재처리
                if (_refinedData != null) {
                  _processTranscriptAutomatically();
                }
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

  // 파일 저장 버튼 클릭 시 처리 (LLM 데이터 포함)
  Future<void> _handleFileSave() async {
    if (_refinedData == null) {
      _showErrorMessage('저장할 데이터가 준비되지 않았습니다');
      return;
    }

    if (selectedFilePath == null || selectedFilePath!.isEmpty) {
      _showErrorMessage('저장 경로를 선택해주세요');
      return;
    }

    try {
      List<String> savedFiles = [];
      
      // 선택한 파일 타입에 따라 저장
      if (isContentFile && _refinedData!.containsKey('refined_result')) {
        String filePath = await _downloadServerFile(
          _refinedData!['refined_result'], 
          '정제된내용', 
          selectedFilePath!
        );
        savedFiles.add(filePath);
      }
      
      if (isSummaryFile && _refinedData!.containsKey('summarized_result')) {
        String filePath = await _downloadServerFile(
          _refinedData!['summarized_result'], 
          '요약', 
          selectedFilePath!
        );
        savedFiles.add(filePath);
      }
      
      if (isMajorFile && _refinedData!.containsKey('keypoints_result')) {
        String filePath = await _downloadServerFile(
          _refinedData!['keypoints_result'], 
          '핵심포인트', 
          selectedFilePath!
        );
        savedFiles.add(filePath);
      }
      
      // 선택한 파일이 없으면 전체 저장
      if (!isContentFile && !isSummaryFile && !isMajorFile) {
        _showErrorMessage('저장할 파일 타입을 선택해주세요');
        return;
      }
      
      Navigator.of(context).pop();
      _showSuccessMessage('파일이 저장되었습니다\n${savedFiles.join('\n')}');
      
    } catch (e) {
      _showErrorMessage('파일 저장 중 오류가 발생했습니다: $e');
    }
  }

  // 서버 파일을 다운로드하는 헬퍼 함수
  Future<String> _downloadServerFile(Map<String, dynamic> fileData, String fileType, String basePath) async {
    // 서버 파일 정보
    //String fileName = fileData['filename']; // 서버에서 생성한 파일명
    String base64Data = fileData['data'];
    
    // Base64 디코딩
    List<int> bytes = base64Decode(base64Data);
    
    // 사용자 친화적인 파일명 생성
    DateTime now = DateTime.now();
    String timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    
    String extension = fileFormat.startsWith('.')? fileFormat : '.$fileFormat'; // 파일 형식이 '.'로 시작하지 않으면 추가
    String userFileName = '${fileName}_${fileType}_$timestamp$extension';
    
    // 사용자가 선택한 경로에 저장
    String fullPath = '$basePath/$userFileName';
    final file = File(fullPath);
    await file.writeAsBytes(bytes);
    
    debugPrint('[파일 다운로드] 서버파일: $fileName → 로컬파일: $userFileName');
    debugPrint('[파일 크기] ${fileData['file_size']} bytes');
    debugPrint('[저장 위치] $fullPath');
    
    return fullPath;
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

  // 에러 메시지 표시
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}