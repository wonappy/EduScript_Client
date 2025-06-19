// 저장화면 컴포넌트들 - 깔끔한 폼 스타일

import 'package:flutter/material.dart';

class SaveDialogComponents {
  
  static Widget buildMainSection({
    required bool isContentFileSelected,  // 내용 파일 선택 여부
    required bool isSummaryFileSelected,  // 요약 파일 선택 여부
    required bool isMajorFileSelected, // 주요 내용 파일 선택 여부
    required String selectedLocation, // 저장 위치
    required String? selectedFilePath, // 선택된 파일 경로
    required String emailAddress, // 이메일 주소
    required String emailDomain, // 이메일 도메인
    required Function(bool) onContentFileChanged, // 내용 파일 체크박스 변경 콜백
    required Function(bool) onSummaryFileChanged, // 요약 파일 체크박스 변경 콜백
    required Function(bool) onMajorFileChanged, // 주요 파일 체크박스 변경 콜백
    required Function(String) onLocationChanged, // 저장 위치 변경 콜백
    required Function(String) onEmailAddressChanged, // 이메일 주소 변경 콜백
    required Function(String) onEmailDomainChanged, // 이메일 도메인 변경 콜백
    required VoidCallback onSelectPath, // 경로 선택 콜백
    required VoidCallback onEmailSend, // 이메일 전송 콜백
    required VoidCallback onFileSave, // 파일 저장 콜백
    required BuildContext context, // BuildContext (X버튼 눌러서 다이얼로그 닫을 때 필요)
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 파일 유형 선택
                _buildFormSection(
                  title: '파일 유형 선택',
                  isRequired: true,
                  child: Column(
                    children: [
                      buildCheckbox('정제된 발화 내용 파일', isContentFileSelected, onContentFileChanged),
                      const SizedBox(height: 12),
                      buildCheckbox('강의 내용 요약 파일', isSummaryFileSelected, onSummaryFileChanged),
                      const SizedBox(height: 12),
                      buildCheckbox('주요 내용 파일 (과제 마감일 혹은 학사일정에 관련된 내용입니다.)', isMajorFileSelected, onMajorFileChanged),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // 저장 위치 선택
                _buildFormSection(
                  title: '저장 위치 선택',
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
                          Future.delayed(const Duration(milliseconds: 100), onSelectPath);
                        },
                      ),
                    ],
                  ),
                ),
                
                // 저장 상세 설정
                if (selectedLocation == 'email') ...[
                  const SizedBox(height: 24),
                  buildEmailSection(
                    emailAddress: emailAddress,
                    emailDomain: emailDomain,
                    onEmailAddressChanged: onEmailAddressChanged,
                    onEmailDomainChanged: onEmailDomainChanged,
                    onEmailSend: onEmailSend,
                  ),
                ] else if (selectedLocation == 'computer') ...[
                  const SizedBox(height: 24),
                  buildComputerSection(
                    selectedFilePath: selectedFilePath,
                    onSelectPath: onSelectPath,
                    onFileSave: onFileSave,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
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
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFFEF4444),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  // 체크박스 빌더
  static Widget buildCheckbox(String label, bool value, Function(bool) onChanged) {
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
          color: value ? const Color(0xFF3B82F6).withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF3B82F6) : Colors.white,
                border: Border.all(
                  color: value ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: value
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded( // 텍스트가 넘치지 않도록 Expanded 추가
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: value ? const Color(0xFF1F2937) : const Color(0xFF6B7280),
                  fontWeight: value ? FontWeight.w500 : FontWeight.w400,
                  height: 1.4, // 줄간격 조정
                ),
                softWrap: true, // 자동 줄바꿈 허용
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
              color: isSelected ? const Color(0xFF3B82F6) : const Color(0xFFD1D5DB),
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
                    style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      hintText: '이메일 주소',
                      hintStyle: TextStyle(color: Color(0xFF9CA3AF)),
                    ),
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('@', style: TextStyle(fontSize: 16, color: Color(0xFF6B7280))),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD1D5DB)),
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFFF9FAFB),
                ),
                child: DropdownButton<String>(
                  value: emailDomain,
                  items: const [
                    DropdownMenuItem(value: 'naver.com', child: Text('naver.com')),
                    DropdownMenuItem(value: 'gmail.com', child: Text('gmail.com')),
                    DropdownMenuItem(value: 'daum.net', child: Text('daum.net')),
                  ],
                  onChanged: (value) => onEmailDomainChanged(value ?? 'naver.com'),
                  style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
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
    required VoidCallback onSelectPath,
    required VoidCallback onFileSave,
  }) {
    return _buildFormSection(
      title: '저장 경로',
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              border: Border.all(color: const Color(0xFFD1D5DB)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              selectedFilePath ?? '저장 경로를 선택해주세요',
              style: TextStyle(
                fontSize: 14,
                color: selectedFilePath != null ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSelectPath,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF6B7280),
                    side: const BorderSide(color: Color(0xFFD1D5DB)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    '경로 선택',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: selectedFilePath != null ? onFileSave : null,
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
        ],
      ),
    );
  }
}