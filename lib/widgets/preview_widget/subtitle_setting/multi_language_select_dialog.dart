import 'package:client/core/styles/color_core.dart';
import 'package:flutter/material.dart';
import '../../../core/global_core.dart';

/// 다중 언어 선택 다이얼로그

class MultiLanguageSelectDialog extends StatefulWidget {
  final List<String> availableLanguages;
  final List<String> selectedLanguages;

  const MultiLanguageSelectDialog({
    super.key,
    required this.availableLanguages,
    required this.selectedLanguages,
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
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black), // 🔴 제목 색상
              ),
            ),
            SizedBox(height: 16),

            // [2] 언어 검색 창
            TextField(
              decoration: InputDecoration(
                hintText: '언어 검색...',
                hintStyle: TextStyle(color: Colors.grey),               // 🔴 hint 텍스트 색상
                prefixIcon: Icon(Icons.search, color: Colors.black,),   // 🔴 아이콘 색상
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(  // 포커스 시 테두리
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.blue, width: 2),  // 🔴 포커스 테두리
                ),
                enabledBorder: OutlineInputBorder(  // 기본 테두리
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey, width: 2), // 🔴 기본 테두리
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
                  return CheckboxListTile(
                    title: Text(language, style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),),
                    value: _tempSelectedLanguages.contains(language),
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
                },
              ),
            ),

            // [4] 취소/확인 버튼
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소', style: TextStyle(color: Colors.black),),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pop(context, _tempSelectedLanguages),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blueColor2
                  ),
                  child: Text('확인', style: TextStyle(color: Colors.white),),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
