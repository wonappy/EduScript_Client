//강의 끝나고 나서 나오는 dialog 화면
import 'dart:io';
import 'dart:convert';
import 'package:client/services/websocket_multiple_speech_service.dart';
import 'package:flutter/material.dart';
import '../widgets/end_screen/save_dialog_components.dart';
import 'package:file_picker/file_picker.dart';
import '../services/postprocessor_service.dart';
import '../services/websocket_stt_service.dart';
import 'package:provider/provider.dart';
import '../providers/mode_provider.dart';
import '../core/enum_core.dart';

class SaveDialogScreen extends StatefulWidget {
  final List<String> transcriptHistory;
  final List<Map<String, String>> translationHistory;
  final String fullTranscript;
  
  const SaveDialogScreen({super.key, required this.transcriptHistory, required this.translationHistory, required this.fullTranscript});

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
  bool _isSaving = false;
  String _savingMessage = '';

  final PostProcessorService _llmService = PostProcessorService();
  
  // WebSocketSTTService? _sttService;
  // WebSocketMultipleSTTService? _multipleSTTService;

  bool _isProcessing = false;
  String _statusMessage = '';
  Map<String, dynamic>? _refinedData;
  Mode? _currentMode;

  @override
  void initState() {
    super.initState();
    debugPrint('=== SaveDialogScreen initState ===');
    debugPrint('초기 isContentFile: $isContentFile');
    debugPrint('초기 isSummaryFile: $isSummaryFile');
    debugPrint('초기 isMajorFile: $isMajorFile');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 모드 설정 (한 번만)
    if (_currentMode == null) {
      _currentMode = Provider.of<ModeProvider>(context, listen: false).currentMode;
      debugPrint("🔥 현재 모드: ${_currentMode.toString()}");
      
      // // 모드에 따라 적절한 STT 서비스 선택
      // if (_currentMode == Mode.conference) {
      //   _multipleSTTService  = Provider.of<WebSocketMultipleSTTService>(context, listen: false);
      //   debugPrint("🔥 Multiple STT 서비스 사용");
      // } else {
      //   _sttService = Provider.of<WebSocketSTTService>(context, listen: false);
      //   debugPrint("🔥 Single STT 서비스 사용");
      // }
      
      // 자동으로 LLM 정제 실행
    }
  }

  // // 현재 STT 서비스의 텍스트 가져오기
  // String get _currentTranscriptText {
  //   if (_currentMode == Mode.conference && _multipleSTTService != null) {
  //     return _multipleSTTService!.fullTranscriptText;
  //   } else if (_sttService != null) {
  //     return _sttService!.fullTranscriptText;
  //   }
  //   return '';
  // }

   // 자동으로 STT 내용을 LLM으로 정제
  Future<void> _processTranscriptAutomatically() async {
    final transcriptText = widget.fullTranscript;
    
    debugPrint('🔍 STT 텍스트 확인:');
    debugPrint('  - 모드: ${_currentMode.toString()}');
    debugPrint('  - 텍스트 길이: ${transcriptText.length}');
    debugPrint('  - 텍스트 내용: "$transcriptText"');
    
    if (transcriptText.trim().isEmpty) {
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
      final apiMode = _currentMode!.apiValue;
      debugPrint("🔥 API 모드: $apiMode");

      // 요약과 핵심 포인트 모두 활성화하여 정제
      final result = await _llmService.refineText(
        fullText: transcriptText,
        enableSummarize: true,
        enableKeypoints: true,
        fileFormat: fileFormat.replaceAll('.',''),
        fileName: fileName,
        processingMode: apiMode,
      );

      debugPrint("🔥 응답 결과: $result");
      if (result != null) {
        debugPrint("🔥 refined_result 존재: ${result.containsKey('refined_result')}");
        debugPrint("🔥 total_files: ${result['total_files']}");
      }

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
        child: _isSaving
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 20),
                Text(
                  '저장중 ...',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
  debugPrint('=== 저장 버튼 클릭 디버그 ===');

  if (selectedFilePath == null || selectedFilePath!.isEmpty) {
    _showErrorMessage('저장 경로를 선택해주세요');
    return;
  }

  if (!isContentFile && !isSummaryFile && !isMajorFile) {
    _showErrorMessage('저장할 파일 타입을 선택해주세요');
    return;
  }

  setState(() {
    _isSaving = true;
    _savingMessage = 'AI가 파일 생성 중입니다...';
  });

  try {
    final apiMode = _currentMode!.apiValue;
    final transcriptText = widget.fullTranscript;

    // ✅ LLM 호출 (서버에서 파일 포맷 생성)
    final result = await _llmService.refineText(
      fullText: transcriptText,
      enableSummarize: isSummaryFile,
      enableKeypoints: isMajorFile,
      fileFormat: fileFormat.replaceAll('.', ''),
      fileName: fileName,
      processingMode: apiMode,
    );

    if (result == null) {
      _showErrorMessage('파일 생성에 실패했습니다');
      setState(() => _isSaving = false);
      return;
    }

    _refinedData = result;
    List<String> savedFiles = [];

    /// 공통 저장 함수
    Future<void> saveItem(String key, String label) async {
      if (_refinedData!.containsKey(key)) {
        _savingMessage = '$label 저장 중...';
        setState(() {});
        String filePath = await _downloadServerFile(
          _refinedData![key],
          label,
          selectedFilePath!
        );
        savedFiles.add(filePath);
      }
    }

    /// 다중 저장 함수
    Future<void> saveList(String key, String label) async {
      if (_refinedData!.containsKey(key)) {
        for (var file in _refinedData![key]) {
          _savingMessage = '$label 저장 중...';
          setState(() {});
          String filePath = await _downloadServerFile(
            file,
            label,
            selectedFilePath!
          );
          savedFiles.add(filePath);
        }
      }
    }

    // ✅ 저장 실행
    if (isContentFile) {
      await saveItem('refined_result', '정제된내용');
      await saveList('refined_results', '정제된내용');
    }

    if (isSummaryFile) {
      await saveItem('summarized_result', '요약');
      await saveList('summarized_results', '요약');
    }

    if (isMajorFile) {
      await saveItem('keypoints_result', '핵심포인트');
      await saveList('keypoints_results', '핵심포인트');
    }

    Navigator.of(context).pop();
    _showSuccessMessage('파일이 저장되었습니다:\n${savedFiles.join('\n')}');
  } catch (e) {
    _showErrorMessage('파일 저장 중 오류 발생: $e');
  } finally {
    setState(() {
      _isSaving = false;
      _savingMessage = '';
    });
  }
}



  // 서버 파일을 다운로드하는 헬퍼 함수
  Future<String> _downloadServerFile(Map<String, dynamic> fileData, String fileType, String basePath) async {
    // 서버 파일 정보
    //String fileName = fileData['filename']; // 서버에서 생성한 파일명
    String base64Data = fileData['data'];
    
    // Base64 디코딩
    List<int> bytes = base64Decode(base64Data);

    // 서버에서 전달한 원래 파일명 예: hello_ko_정제된내용.txt
  String serverFileName = fileData['filename'];
  
  // 언어코드 추출 (예: hello_ko_정제된내용 → ko)
  // 파일명이 예측 가능하다는 전제 하에
  String langCode = 'unknown';
  try {
    List<String> parts = serverFileName.split('_');
    if (parts.length >= 2) {
      langCode = parts[parts.length - 2]; // 마지막에서 두 번째 부분이 언어코드일 확률 높음
    }
  } catch (_) {}

  // 타임스탬프
  DateTime now = DateTime.now();
  String timestamp = '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

  // 확장자 처리
  String extension = fileFormat.startsWith('.') ? fileFormat : '.$fileFormat';

  // 사용자 친화적이고 유니크한 파일명 구성
  String userFileName = '${fileName}_${fileType}_${langCode}_$timestamp$extension';

  // 전체 경로
  String fullPath = '$basePath/$userFileName';

  // 파일 저장
  final file = File(fullPath);
  await file.writeAsBytes(bytes);

  debugPrint('[파일 다운로드] 서버파일: $serverFileName → 로컬파일: $userFileName');
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