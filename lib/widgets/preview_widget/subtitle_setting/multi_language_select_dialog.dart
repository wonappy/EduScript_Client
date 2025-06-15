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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '언어 선택',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            TextField(
              decoration: InputDecoration(
                hintText: '언어 검색...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
            SizedBox(height: 16),

            Expanded(
              child: ListView.builder(
                itemCount: _filteredLanguages.length,
                itemBuilder: (context, index) {
                  final language = _filteredLanguages[index];
                  return CheckboxListTile(
                    title: Text(language),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('취소'),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed:
                      () => Navigator.pop(context, _tempSelectedLanguages),
                  child: Text('확인'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// 드롭다운 위젯
class MultiLanguageDropdown extends StatelessWidget {
  final String title;
  final List<String> selectedLanguages;
  final List<String> availableLanguages;
  final Function(List<String>) onChanged;
  final double screenWidth;
  final double screenHeight;
  final Color? backgroundColor;

  const MultiLanguageDropdown({
    super.key,
    required this.title,
    required this.selectedLanguages,
    required this.availableLanguages,
    required this.onChanged,
    required this.screenWidth,
    required this.screenHeight,
    this.backgroundColor,
  });

  String _getDisplayText() {
    if (selectedLanguages.isEmpty) {
      return '언어를 선택하세요';
    } else if (selectedLanguages.length == 1) {
      return selectedLanguages.first;
    } else {
      return '${selectedLanguages.first} 외 ${selectedLanguages.length - 1}개';
    }
  }

  void _showLanguageDialog(BuildContext context) async {
    final result = await showDialog<List<String>>(
      context: context,
      builder:
          (context) => MultiLanguageSelectDialog(
            availableLanguages: availableLanguages,
            selectedLanguages: selectedLanguages,
          ),
    );

    if (result != null) {
      onChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: backgroundColor ?? Color(0xFFF6F6F6),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: getResponsiveFontSize(screenWidth) * 0.7,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),

          InkWell(
            onTap: () => _showLanguageDialog(context),
            borderRadius: BorderRadius.circular(5),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _getDisplayText(),
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: getResponsiveFontSize(screenWidth) * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.black,
                    size: getResponsiveFontSize(screenWidth) * 1.5,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
