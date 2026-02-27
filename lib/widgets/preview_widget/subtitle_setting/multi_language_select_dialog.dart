import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';
import '../../../core/global_core.dart';

/// # 다중 언어 선택 다이얼로그
/// -

class MultiLanguageSelectDialog extends StatefulWidget {
  final List<String> availableLanguages;
  final List<String> selectedLanguages;
  final bool isLectureMode;
  final bool isInputLanguage;

  const MultiLanguageSelectDialog({
    super.key,
    required this.availableLanguages,
    required this.selectedLanguages,
    required this.isLectureMode,
    required this.isInputLanguage,
  });

  @override
  State<MultiLanguageSelectDialog> createState() =>
      _MultiLanguageSelectDialogState();
}

class _MultiLanguageSelectDialogState extends State<MultiLanguageSelectDialog> {
  String _searchQuery = '';
  late List<String> _tempSelectedLanguages;

  @override
  void initState() {
    super.initState();
    _tempSelectedLanguages = List.from(widget.selectedLanguages);
    // 강제 리빌드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // 강제로 한 번 더 업데이트
          _tempSelectedLanguages = List.from(widget.selectedLanguages);
        });
      }
    });
  }

  @override
  void didUpdateWidget(MultiLanguageSelectDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLanguages != widget.selectedLanguages) {
      setState(() {
        _tempSelectedLanguages = List.from(widget.selectedLanguages);
      });
    }
  }

  List<String> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return widget.availableLanguages;
    }
    return widget.availableLanguages
        .where(
          (lang) => lang.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.3,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // [1] 헤더
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 5),
              child: Text(
                '언어 선택',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ), // 🔴 제목 색상
              ),
            ),
            SizedBox(height: 16),

            // [2] 언어 검색 창
            TextField(
              decoration: InputDecoration(
                hintText: '언어 검색...',
                hintStyle: TextStyle(color: Colors.grey), // 🔴 hint 텍스트 색상
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.black,
                ), // 🔴 아이콘 색상
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  // 포커스 시 테두리
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.blue,
                    width: 2,
                  ), // 🔴 포커스 테두리
                ),
                enabledBorder: OutlineInputBorder(
                  // 기본 테두리
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(
                    color: Colors.grey,
                    width: 2,
                  ), // 🔴 기본 테두리
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            SizedBox(height: 16),

            // [3] 언어 선택 리스트 + 체크박스
            Expanded(
              child: ListView.builder(
                itemCount: _filteredLanguages.length,
                itemBuilder: (context, index) {
                  final language = _filteredLanguages[index];
                  final isSelected = _tempSelectedLanguages.contains(language);
                  // [1-1] 강의 모드 + 음성 언어 설정
                  if (widget.isLectureMode && widget.isInputLanguage) {
                    return ListTile(
                      title: Text(
                        language,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing:
                          isSelected
                              ? Icon(
                                Icons.check,
                                color: AppColors.blueColor2,
                                size: 24,
                              )
                              : null, // 선택된 언어에 체크 아이콘, 선택 안되니 언어는 null
                      onTap: () {
                        // 음성 언어를 새로 선택했을 때
                        setState(() {
                          _tempSelectedLanguages.clear(); // 기존 선택 지우기
                          _tempSelectedLanguages.add(language); // 새 언어 추가하기
                        });
                      },
                    );
                  }
                  // [2-2] 강의 모드 + 출력 언어 설정
                  else if (widget.isLectureMode && !widget.isInputLanguage) {
                    return CheckboxListTile(
                      title: Text(
                        language,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _tempSelectedLanguages.contains(language),
                      // 1) 체크박스 색상 설정
                      activeColor: AppColors.blueColor2, // 체크된 상태 배경색
                      checkColor: Colors.white, // 체크 마크 색상
                      // 2) 호버/포커스 색상
                      hoverColor: AppColors.blueColor2.withOpacity(0.05),

                      // 3) 테두리 색상 (체크되지 않은 상태)
                      side: BorderSide(
                        color:
                            _tempSelectedLanguages.contains(language)
                                ? AppColors.blueColor2
                                : Colors.grey,
                        width: 2,
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _tempSelectedLanguages.add(language);
                          } else {
                            _tempSelectedLanguages.remove(language);
                          }
                        });
                      },
                    );
                  }
                  // [2] 토론 모드
                  else {
                    return CheckboxListTile(
                      title: Text(
                        language,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      value: _tempSelectedLanguages.contains(language),
                      // 1) 체크박스 색상 설정
                      activeColor: AppColors.blueColor2, // 체크된 상태 배경색
                      checkColor: Colors.white, // 체크 마크 색상
                      // 2) 호버/포커스 색상
                      hoverColor: AppColors.blueColor2.withOpacity(0.05),

                      // 3) 테두리 색상 (체크되지 않은 상태)
                      side: BorderSide(
                        color:
                            _tempSelectedLanguages.contains(language)
                                ? AppColors.blueColor2
                                : Colors.grey,
                        width: 2,
                      ),
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _tempSelectedLanguages.add(language);
                          } else {
                            _tempSelectedLanguages.remove(language);
                          }
                        });
                      },
                    );
                  }
                },
              ),
            ),
            SizedBox(height: 13),
            // [4] 취소/확인 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[200],
                  ),
                  child: Text('취소', style: TextStyle(color: Colors.black)),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pop(context, _tempSelectedLanguages),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueColor2,
                  ),
                  child: Text('확인', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
