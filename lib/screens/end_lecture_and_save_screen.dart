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

  late final BasePostProcessorService _llmService;

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

    switch(_currentMode){
      case Mode.lecture:
        _llmService = LecturePostProcessorService();
        break;
      case Mode.conference:
        _llmService = ConferencePostProcessorService();
        break;
      default:
        _llmService = LecturePostProcessorService(); // 기본값 설정
    }

    _processTranscriptAutomatically();
    }
  }

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
        fileName : fileName,
        fileFormat: fileFormat.replaceAll('.', ''), // 확장자에서 '.' 제거       
        enableSummarize: isSummaryFile,
        enableKeypoints: isMajorFile,
        enableScript: isContentFile,
        enableNote: isSummaryFile, // 요약 파일이면 노트도 활성화
      );

      debugPrint("🔥 응답 결과: $result");
      if (result != null) {
        debugPrint("🔥 script_results 존재: ${result.containsKey('script_results')}");
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
                  isContentFileSelected: isContentFile, //첫번째 체크박스
                  isSummaryFileSelected: isSummaryFile, //두번째 체크박스
                  isMajorFileSelected: isMajorFile, //세번째 체크박스 (이 체크박스의 경우 회의모드에선 필요하지 않음)
                  showMajorFileCheckbox: _currentMode == Mode.lecture, // 강의 모드에서만 표시
                  contentLabel: _currentMode == Mode.lecture ? '정제된 발화 내용 파일' : '정제된 토론 발화 내용',
                  summaryLabel: _currentMode == Mode.lecture ? '강의 내용 요약 파일' : '토론 정리본',
                  majorLabel: _currentMode == Mode.lecture ? '주요 내용 파일 (과제 마감일 혹은 학사일정에 관련된 내용입니다.)' : '', // null이면 표시 X
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
    if (_currentMode == Mode.lecture) {
      await handleLectureFileSave();
    } else if (_currentMode == Mode.conference) {
      await handleConferenceFileSave();
    }
  }

// 강의모드에서 파일 저장 처리
Future<void> handleLectureFileSave() async {
  if (!_validateBeforeSave()) return;

  final transcriptText = widget.fullTranscript;
  _startSaving('AI가 강의 내용을 정제 중입니다...');

  try {
    final result = await _llmService.refineText(
      fullText: transcriptText,
      fileFormat: fileFormat.replaceAll('.', ''),
      fileName: fileName,
      enableSummarize: isSummaryFile,
      enableKeypoints: isMajorFile,
      enableScript: isContentFile,
      enableNote: isSummaryFile, // 요약 파일이면 노트도 활성화
    );

    if (result == null) return _failSave('파일 생성에 실패했습니다');
    _refinedData = result;

    List<String> savedFiles = [];

    // 정제된 내용 파일
    if (isContentFile) {
      await _saveResultGroup(
        singleKey: 'refined_result',
        listKey: 'refined_results',
        label: '정제된내용',
        resultList: savedFiles,
      );
    }

    // 요약 파일
    if (isSummaryFile) {
      await _saveResultGroup(
        singleKey: 'summarized_result',
        listKey: 'summarized_results',
        label: '요약',
        resultList: savedFiles,
      );
    }

    // 핵심 포인트 파일
    if (isMajorFile) {
      await _saveResultGroup(
        singleKey: 'keypoints_result',
        listKey: 'keypoints_results',
        label: '핵심포인트',
        resultList: savedFiles,
      );
    }

    _finishSave(savedFiles);
  } catch (e) {
    _failSave('강의 파일 저장 중 오류 발생: $e');
  }
}

// 회의모드에서 파일 저장 처리
Future<void> handleConferenceFileSave() async {
  if (!_validateBeforeSave()) return;

  final transcriptText = widget.fullTranscript;
  _startSaving('AI가 회의 스크립트를 정제 중입니다...');

  try {
    final result = await _llmService.refineText(
      fullText: transcriptText,
      fileName: fileName,
      fileFormat: fileFormat.replaceAll('.', ''),
      enableNote: isSummaryFile, // note
      // 회의 모드는 현재 스크립트/노트 중심이라
      // enableScript 등은 서버 설계에 맞춰 필요시 추가 가능
    );

    if (result == null) return _failSave('파일 생성에 실패했습니다');
    _refinedData = result;

    debugPrint("서버 응답 전체: ${jsonEncode(result)}");
    debugPrint("script_results runtimeType: ${result['script_results']?.runtimeType}");
    debugPrint("script_results 내용: ${result['script_results']}");

    List<String> savedFiles = [];

    // 회의 스크립트
    if (isContentFile) {
      await _saveResultGroup(
        singleKey: 'script_result',
        listKey: 'script_results',
        label: '스크립트',
        resultList: savedFiles,
      );
    }

    // 요약 노트
    if (isSummaryFile) {
      await _saveResultGroup(
        singleKey: 'note_result',
        listKey: 'note_results',
        label: '요약노트',
        resultList: savedFiles,
      );
    }

    _finishSave(savedFiles);
  } catch (e) {
    _failSave('회의 파일 저장 중 오류 발생: $e');
  }
}

// 단일 결과 / 복수 결과를 한 번만 저장하도록 도와주는 헬퍼
Future<void> _saveResultGroup({
  required String singleKey,
  required String listKey,
  required String label,
  required List<String> resultList,
}) async {
  if (_refinedData == null) return;

  // 1) 리스트 키가 있으면 우선 사용 (다국어 등 여러 개일 때)
  if (_refinedData!.containsKey(listKey) &&
      _refinedData![listKey] != null &&
      (_refinedData![listKey] as List).isNotEmpty) {
    await _saveList(listKey, label, resultList);
    return;
  }

  // 2) 리스트 키 없으면 단일 키 사용 (단일 결과일 때)
  if (_refinedData!.containsKey(singleKey) &&
      _refinedData![singleKey] != null) {
    await _saveItem(singleKey, label, resultList);
  }
}

// 유효성 검사
// 저장 전에 필요한 조건들을 확인하는 메소드
bool _validateBeforeSave() {
  if (selectedFilePath == null || selectedFilePath!.isEmpty) {
    _showErrorMessage('저장 경로를 선택해주세요');
    return false;
  }
  if (!isContentFile && !isSummaryFile && !isMajorFile) {
    _showErrorMessage('저장할 파일 타입을 선택해주세요');
    return false;
  }
  if (widget.fullTranscript.trim().isEmpty) {
    _showErrorMessage('정제할 텍스트가 없습니다');
    return false;
  }
  return true;
}

// 저장 시작 상태로 변경
// 메시지를 표시하고 상태를 업데이트
void _startSaving(String message) {
  setState(() {
    _isSaving = true;
    _savingMessage = message;
  });
}

// 저장 완료 후 처리
// 저장이 완료되면 다이얼로그를 닫고 성공 메시지를 표시
void _finishSave(List<String> paths) {
  Navigator.of(context).pop();
  _showSuccessMessage('파일이 저장되었습니다:\n${paths.join('\n')}');
  setState(() {
    _isSaving = false;
    _savingMessage = '';
  });
}

// 저장 실패 처리
// 에러 메시지를 표시하고 상태를 업데이트
void _failSave(String message) {
  _showErrorMessage(message);
  setState(() {
    _isSaving = false;
    _savingMessage = '';
  });
}

// 파일 저장 헬퍼 함수들
Future<void> _saveItem(String key, String label, List<String> resultList) async {
  if (_refinedData!.containsKey(key)) {
    _savingMessage = '$label 저장 중...';
    setState(() {});
    String path = await _downloadServerFile(_refinedData![key], label, selectedFilePath!);
    resultList.add(path);
  }
}

// 복수개의 파일을 저장하는 헬퍼 함수
Future<void> _saveList(String key, String label, List<String> resultList) async {
  if (_refinedData!.containsKey(key)) {
    for (var file in _refinedData![key]) {
      _savingMessage = '$label 저장 중...';
      setState(() {});
      String path = await _downloadServerFile(file, label, selectedFilePath!);
      resultList.add(path);
    }
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