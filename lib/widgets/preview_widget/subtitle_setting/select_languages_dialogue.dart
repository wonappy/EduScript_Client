import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 언어 국가 설정 다이얼로그

class SelectLanguagesDialogue extends StatefulWidget {
  final List<String> availableLanguages; // 선택 가능한 국가 리스트
  final List<String> selectedLanauges;   // 선택된 국가 리스트

  const SelectLanguagesDialogue({super.key, required this.availableLanguages, required this.selectedLanauges});

  @override
  State<SelectLanguagesDialogue> createState() =>
      _SelectLanguageSelectDialogueState();
}

class _SelectLanguageSelectDialogueState extends State<SelectLanguagesDialogue> {
  String _searchQuery = '';                 //
  late List<String> _tempSelectedLanguages; // 임시로 선택된 언어 List

  @override
  void initState() {
    super.initState();
    _tempSelectedLanguages = List.from(widget.selectedLanauges); // 임시로 선택된 언어 List
  }

  List<String> get _filteredLanguages {
    if (_searchQuery.isEmpty) {
      return widget.availableLanguages;
    }

    return widget.availableLanguages
        // 선택된 언어 -> 소문자로 변환 -> 저장된 언어와 같은지 비교
        .where((lang) => lang.toLowerCase().contains(_searchQuery.toLowerCase()),).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      backgroundColor: Colors.transparent, // 🔴 다이얼로그 배경색
      child: Container(
        color: Colors.white,
        width: 800,
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min, // 내용물만큼의 크기
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 4)
                  )
                ]
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("언어 선택", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),),
                  // 헤더
                  // Container(
                  //   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  //   decoration: const BoxDecoration(
                  //       border: Border(
                  //         bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1), // 🔴 컨테이너 색상
                  //       )
                  //   ),
                  //   child: Row(
                  //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //     children: [
                  //       const Text("파일 저장", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),),
                  //       GestureDetector(
                  //         onTap: () {
                  //           Navigator.of(context).pop();
                  //           debugPrint("");
                  //         },
                  //       )
                  //     ],
                  //   ),
                  // )
                ],
              ),

            ),

          ],
        ),
      ),
    );
  }
}
