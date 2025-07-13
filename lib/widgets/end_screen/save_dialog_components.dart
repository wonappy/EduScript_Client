// 저장화면 컴포넌트들 - 깔끔한 폼 스타일

import 'package:flutter/material.dart';

class SaveDialogComponents {
  static Widget buildMainSection({
    required bool isContentFileSelected, // 내용 파일 선택 여부
    required bool isSummaryFileSelected, // 요약 파일 선택 여부
    required bool isMajorFileSelected, // 주요 내용 파일 선택 여부
    required String selectedLocation, // 저장 위치
    required String? selectedFilePath, // 선택된 파일 경로
    required String fileName, // 파일명 (사용자 입력)
    required String fileFormat, // 파일 형식 (.docx, .pdf, .hwpx)
    required String emailAddress, // 이메일 주소
    required String emailDomain, // 이메일 도메인
    required Function(bool) onContentFileChanged, // 내용 파일 체크박스 변경 콜백
    required Function(bool) onSummaryFileChanged, // 요약 파일 체크박스 변경 콜백
    required Function(bool) onMajorFileChanged, // 주요 파일 체크박스 변경 콜백
    required Function(String) onLocationChanged, // 저장 위치 변경 콜백
    required Function(String) onFileNameChanged, // 파일명 변경 콜백
    required Function(String) onFileFormatChanged, // 파일 형식 변경 콜백
    required Function(String) onEmailAddressChanged, // 이메일 주소 변경 콜백
    required Function(String) onEmailDomainChanged, // 이메일 도메인 변경 콜백
    required VoidCallback onSelectPath, // 경로 선택 콜백
    required VoidCallback onEmailSend, // 이메일 전송 콜백
    required VoidCallback onFileSave, // 파일 저장 콜백
    required BuildContext context, // BuildContext (X버튼 눌러서 다이얼로그 닫을 때 필요)
  }) {
    // ScrollController 생성
    final ScrollController scrollController = ScrollController();

    // 파일명 미리보기 생성 함수
    String getFileNamePreview() {
      final now = DateTime.now();
      final dateStr =
          "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
      final timeStr =
          "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}";
      final baseName = fileName.isEmpty ? '강의' : fileName;
      return "$baseName" + "_정제된내용_${dateStr}_$timeStr$fileFormat";
    }

    return Container(
      width: 720,
      height: 450,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 헤더
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '파일 저장',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF111827),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    debugPrint('저장 취소');
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Color(0xFF6B7280),
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 폼 내용
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단: 파일 유형 선택(왼쪽) + 파일명&저장위치(오른쪽)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 왼쪽: 파일 유형 선택
                      Expanded(
                        flex: 1,
                        child: _buildFormSection(
                          title: '파일 유형 선택',
                          isRequired: true,
                          child: Column(
                            children: [
                              buildCheckbox(
                                '정제된 발화 내용 파일',
                                isContentFileSelected,
                                onContentFileChanged,
                              ),
                              const SizedBox(height: 12),
                              buildCheckbox(
                                '강의 내용 요약 파일',
                                isSummaryFileSelected,
                                onSummaryFileChanged,
                              ),
                              const SizedBox(height: 12),
                              buildCheckbox(
                                '주요 내용 파일 (과제 마감일 혹은 학사일정에 관련된 내용입니다.)',
                                isMajorFileSelected,
                                onMajorFileChanged,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(width: 24),

                      // 오른쪽: 파일명 + 파일 형식
                      Expanded(
                        flex: 1,
                        child: Column(
                          children: [
                            // 파일명 입력
                            _buildFormSection(
                              title: '파일명',
                              isRequired: true,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFFD1D5DB),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: TextField(
                                      onChanged: (value) {
                                        onFileNameChanged(value);
                                        // setState 호출을 위해 부모에서 처리해야 함
                                      },
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF111827),
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 12,
                                        ),
                                        hintText: '예: 강의, 회의, 세미나',
                                        hintStyle: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // 파일명 미리보기 - 파일명 입력칸 바로 아래
                                  if (fileName.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF0F9FF),
                                        border: Border.all(
                                          color: const Color(0xFFBAE6FD),
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        getFileNamePreview(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF0F172A),
                                          fontFamily: 'monospace',
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 파일 형식 선택
                            _buildFormSection(
                              title: '파일 형식',
                              isRequired: true,
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: const Color(0xFFD1D5DB),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.white,
                                ),
                                child: DropdownButtonFormField<String>(
                                  value: fileFormat,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.keyboard_arrow_down, // 🔥 아래 화살표 아이콘
                                    color: Color(0xFF6B7280),
                                  ),
                                  isExpanded: true,
                                  items:
                                      SaveDialogComponents._buildFileFormatItems(
                                        fileFormat,
                                      ), //동적 아이템 생성
                                  onChanged:
                                      (value) =>
                                          onFileFormatChanged(value ?? '.txt'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                  dropdownColor: Colors.white,
                                  menuMaxHeight: 200, // 적절한 높이로 설정
                                  alignment:
                                      AlignmentDirectional
                                          .bottomStart, //항상 아래쪽으로 정렬
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ), // 저장화면 컴포넌트들 - 깔끔한 폼 스타일

                  const SizedBox(height: 24),

                  // 저장 위치 선택 (전체 너비)
                  _buildFormSection(
                    title: '저장 위치',
                    isRequired: true,
                    child: Row(
                      children: [
                        buildLocationButton(
                          text: '이메일',
                          location: 'email',
                          isSelected: selectedLocation == 'email',
                          onPressed: () => onLocationChanged('email'),
                        ),
                        const SizedBox(width: 12),
                        buildLocationButton(
                          text: '내 컴퓨터',
                          location: 'computer',
                          isSelected: selectedLocation == 'computer',
                          onPressed: () {
                            onLocationChanged('computer');
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              onSelectPath,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 저장 상세 설정 (하단)
                  if (selectedLocation == 'email')
                    buildEmailSection(
                      emailAddress: emailAddress,
                      emailDomain: emailDomain,
                      onEmailAddressChanged: onEmailAddressChanged,
                      onEmailDomainChanged: onEmailDomainChanged,
                      onEmailSend: onEmailSend,
                    )
                  else if (selectedLocation == 'computer')
                    buildComputerSection(
                      selectedFilePath: selectedFilePath,
                      fileName: fileName,
                      onSelectPath: onSelectPath,
                      onFileSave: onFileSave,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 파일 형식 아이템을 동적으로 생성 (선택된 것을 맨 위로)
  static List<DropdownMenuItem<String>> _buildFileFormatItems(
    String selectedFormat,
  ) {
    final Map<String, String> formatMap = {
      '.docx': 'Microsoft Word (.docx)',
      '.pdf': 'PDF 문서 (.pdf)',
      '.hwpx': '한글 문서 (.hwpx)',
      '.txt': '텍스트 파일 (.txt)',
    };

    // 선택된 항목을 맨 위로, 나머지는 그 아래에
    List<DropdownMenuItem<String>> items = [];

    // 1. 선택된 항목을 먼저 추가
    if (formatMap.containsKey(selectedFormat)) {
      items.add(
        DropdownMenuItem(
          value: selectedFormat,
          child: Text(formatMap[selectedFormat]!),
        ),
      );
    }

    // 2. 나머지 항목들을 추가
    formatMap.forEach((key, value) {
      if (key != selectedFormat) {
        items.add(DropdownMenuItem(value: key, child: Text(value)));
      }
    });

    return items;
  }

  // 폼 섹션 빌더
  static Widget _buildFormSection({
    required String title,
    bool isRequired = false,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(fontSize: 14, color: Color(0xFFEF4444)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // 체크박스 빌더
  static Widget buildCheckbox(
    String label,
    bool value,
    Function(bool) onChanged,
  ) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(
            color: value ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          color:
              value
                  ? const Color(0xFF3B82F6).withOpacity(0.05)
                  : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF3B82F6) : Colors.white,
                border: Border.all(
                  color:
                      value ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child:
                  value
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color:
                      value ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                  fontWeight: value ? FontWeight.w500 : FontWeight.w400,
                  height: 1.4,
                ),
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 위치 선택 버튼 빌더
  static Widget buildLocationButton({
    required String text,
    required String location,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
            border: Border.all(
              color:
                  isSelected
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFD1D5DB),
              width: 1.5,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  // 이메일 섹션 빌더
  static Widget buildEmailSection({
    required String emailAddress,
    required String emailDomain,
    required Function(String) onEmailAddressChanged,
    required Function(String) onEmailDomainChanged,
    required VoidCallback onEmailSend,
  }) {
    return _buildFormSection(
      title: '이메일 주소',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextField(
                    onChanged: onEmailAddressChanged,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF111827),
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      hintText: '이메일 주소',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '@',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF9FAFB),
                ),
                child: DropdownButton<String>(
                  value: emailDomain,
                  items: const [
                    DropdownMenuItem(
                      value: 'naver.com',
                      child: Text('naver.com'),
                    ),
                    DropdownMenuItem(
                      value: 'gmail.com',
                      child: Text('gmail.com'),
                    ),
                    DropdownMenuItem(
                      value: 'daum.net',
                      child: Text('daum.net'),
                    ),
                  ],
                  onChanged:
                      (value) => onEmailDomainChanged(value ?? 'naver.com'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF111827),
                  ),
                  underline: Container(),
                  isDense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: emailAddress.isNotEmpty ? onEmailSend : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '이메일 전송',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 파일 경로 선택 및 저장 섹션 빌더
  static Widget buildComputerSection({
    required String? selectedFilePath,
    required String fileName,
    required VoidCallback onSelectPath,
    required VoidCallback onFileSave,
  }) {
    return _buildFormSection(
      title: '저장 경로',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 저장 경로 입력창과 ... 버튼
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                  child: Text(
                    selectedFilePath ?? '저장 경로를 선택해주세요',
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          selectedFilePath != null
                              ? const Color(0xFF111827)
                              : const Color(0xFF9CA3AF),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              InkWell(
                onTap: onSelectPath,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 저장 버튼
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  (selectedFilePath != null && fileName.trim().isNotEmpty)
                      ? onFileSave
                      : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1F2937),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFD1D5DB),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                '파일 저장',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
