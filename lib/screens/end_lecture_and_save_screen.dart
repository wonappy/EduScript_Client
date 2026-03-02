import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/end_screen/save_dialog_components.dart';
import 'package:file_picker/file_picker.dart';
import '../services/postprocessor_service.dart';
import '../core/enum_core.dart';

/// 파일 저장 관련 화면
class SaveDialogScreen extends StatefulWidget {
  final List<String> transcriptHistory;
  final List<Map<String, String>> translationHistory;
  final String fullTranscript;
  final Mode mode;

  const SaveDialogScreen({
    super.key,
    required this.transcriptHistory,
    required this.translationHistory,
    required this.fullTranscript,
    required this.mode,
  });

  @override
  State<SaveDialogScreen> createState() => _SaveDialogScreenState();
}

class _SaveDialogScreenState extends State<SaveDialogScreen> {
  
  final PostProcessorService _postProcessorService = PostProcessorService();

  // 상태 변수
  bool isContentFile = false;       // 정제된 발화 내용 파일 여부
  bool isSummaryFile = false;       // 요약 파일인지 여부
  bool isMajorFile = false;         // 키포인트 파일인지 여부
  String selectedLocation = '';     //저장 위치
  String? selectedFilePath;         // 선택된 파일 경로
  String fileName = '';             // 파일명
  String fileFormat = '.txt';       // 파일 형식 (기본 .txt)
  String emailAddress = '';         //이메일 주소
  String emailDomain = 'naver.com'; //이메일 도메인 기본값
  bool _isSaving = false;
  String _savingMessage = '';
  Map<String, dynamic>? _refinedData;
  late final Mode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.mode;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 800,
        padding: const EdgeInsets.all(25),
        child:
            _isSaving
                ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text(_savingMessage, style: TextStyle(fontSize: 16)),
                  ],
                )
                : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SaveDialogComponents.buildMainSection(
                      isContentFileSelected: isContentFile,
                      isSummaryFileSelected: isSummaryFile,
                      isMajorFileSelected: isMajorFile,
                      showMajorFileCheckbox: _currentMode == Mode.lecture, // 강의 모드에서만 표시
                      contentLabel: _currentMode == Mode.lecture
                              ? '정제된 발화 내용 파일'
                              : '정제된 토론 발화 내용',
                      summaryLabel:
                          _currentMode == Mode.lecture
                              ? '강의 내용 요약 파일'
                              : '토론 정리본',
                      majorLabel:
                          _currentMode == Mode.lecture
                              ? '주요 내용 파일 (과제 마감일 혹은 학사 일정에 관련된 내용입니다.)'
                              : '', // null이면 표시 X
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
                      onFileNameChanged: (value) {
                        setState(() {
                          fileName = value;
                        });
                      },
                      onFileFormatChanged: (value) {
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
  }

  // 2. 통합된 파일 저장 핸들러
  Future<void> _handleFileSave() async {
    if (!_validateBeforeSave()) return;

    final transcriptText = widget.fullTranscript;
    final bool isConf = _currentMode == Mode.conference;
    
    _startSaving('AI가 내용을 정제 중입니다...');

    try {
      // 서비스의 통합 메소드 호출
      final result = await _postProcessorService.refineText(
        mode: _currentMode!,
        fullText: transcriptText,
        fileName: fileName,
        fileFormat: fileFormat.replaceAll('.', ''),
        enableSummarize: isSummaryFile,
        enableKeypoints: isMajorFile,
        enableScript: isContentFile,
        enableNote: isSummaryFile, // 회의에선 요약 선택 시 노트 활성화
      );

      if (result == null) return _failSave('파일 생성에 실패했습니다');
      _refinedData = result;

      List<String> savedFiles = [];

      // 3. 모드별 데이터 키(Key) 매핑 설정
      // [체크박스여부, 단일키, 리스트키, 라벨]
      final List<Map<String, dynamic>> saveConfigs = [
        {
          'selected': isContentFile,
          'single': isConf ? 'script_result' : 'refined_result',
          'list': isConf ? 'script_results' : 'refined_results',
          'label': isConf ? '스크립트' : '정제된내용'
        },
        {
          'selected': isSummaryFile,
          'single': isConf ? 'note_result' : 'summarized_result',
          'list': isConf ? 'note_results' : 'summarized_results',
          'label': isConf ? '요약노트' : '요약'
        },
        if (!isConf) // 강의 모드일 때만 핵심 포인트 추가
          {
            'selected': isMajorFile,
            'single': 'keypoints_result',
            'list': 'keypoints_results',
            'label': '핵심포인트'
          },
      ];

      // 4. 매핑된 설정대로 순회하며 저장
      for (var config in saveConfigs) {
        if (config['selected'] == true) {
          await _saveResultGroup(
            singleKey: config['single'],
            listKey: config['list'],
            label: config['label'],
            resultList: savedFiles,
          );
        }
      }

      _finishSave(savedFiles);
    } catch (e) {
      _failSave('파일 저장 중 오류 발생: $e');
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
  Future<void> _saveItem(
    String key,
    String label,
    List<String> resultList,
  ) async {
    if (_refinedData!.containsKey(key)) {
      _savingMessage = '$label 저장 중...';
      setState(() {});
      String path = await _downloadServerFile(
        _refinedData![key],
        label,
        selectedFilePath!,
      );
      resultList.add(path);
    }
  }

  // 복수개의 파일을 저장하는 헬퍼 함수
  Future<void> _saveList(
    String key,
    String label,
    List<String> resultList,
  ) async {
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
  Future<String> _downloadServerFile(
    Map<String, dynamic> fileData,
    String fileType,
    String basePath,
  ) async {
    String base64Data = fileData['data'];
    List<int> bytes = base64Decode(base64Data);

    // 서버에서 전달한 원래 파일명 예: hello_ko_정제된내용.txt
    String serverFileName = fileData['filename'];

    // 언어코드 추출 (예: hello_ko_정제된내용 → ko)
    String langCode = 'unknown';
    try {
      List<String> parts = serverFileName.split('_');
      if (parts.length >= 2) {
        langCode = parts[parts.length - 2];
      }
    } catch (_) {}

    DateTime now = DateTime.now();
    String timestamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';

    String extension = fileFormat.startsWith('.') ? fileFormat : '.$fileFormat';
    String userFileName = '${fileName}_${fileType}_${langCode}_$timestamp$extension';
    String fullPath = '$basePath/$userFileName';

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
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  // 에러 메시지 표시
  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
