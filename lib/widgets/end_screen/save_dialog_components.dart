// 저장화면 컴포넌트들

import 'package:flutter/material.dart';

class SaveDialogComponents {
  
  static Widget buildMainSection({
    required bool isContentFile,  // 내용 파일인지 요약 파일인지
    required String selectedLocation, // 저장 위치
    required String? selectedFilePath, // 선택된 파일 경로
    required String emailAddress, // 이메일 주소
    required String emailDomain, // 이메일 도메인
    required Function(bool) onContentFileChanged, // 내용 파일 체크박스 변경 콜백
    required Function(String) onLocationChanged, // 저장 위치 변경 콜백
    required Function(String) onEmailAddressChanged, // 이메일 주소 변경 콜백
    required Function(String) onEmailDomainChanged, // 이메일 도메인 변경 콜백
    required VoidCallback onSelectPath, // 경로 선택 콜백
    required VoidCallback onEmailSend, // 이메일 전송 콜백
    required VoidCallback onFileSave, // 파일 저장 콜백
    required BuildContext context, // BuildContext (X버튼 눌러서 다이얼로그 닫을 때 필요)
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC8C8C8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF999999), width: 1.5),
      ),
      child: Stack(
        children:[
          Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '파일 유형 선택',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,           
            ),
          ),
          const SizedBox(height: 16),
          
          // 체크박스들
          Row(
            children: [
              buildCheckbox('내용 파일', isContentFile, onContentFileChanged),
              const SizedBox(width: 24),
              buildCheckbox('요약 파일', !isContentFile, (value) {
                onContentFileChanged(!value);
              }),
            ],
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            '저장 위치를 선택하세요',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF2C2C2C),
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 12),
          
          // 위치 선택 버튼들
          Row(
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
          
          // 저장 경로 섹션 (애니메이션 제거 - 즉시 표시)
              if (selectedLocation == 'email') ...[
                const SizedBox(height: 20),
                buildEmailSection(
                  emailAddress: emailAddress,
                  emailDomain: emailDomain,
                  onEmailAddressChanged: onEmailAddressChanged,
                  onEmailDomainChanged: onEmailDomainChanged,
                  onEmailSend: onEmailSend,
                ),
              ] else if (selectedLocation == 'computer') ...[
                const SizedBox(height: 20),
                buildComputerSection(
                  selectedFilePath: selectedFilePath,
                  onSelectPath: onSelectPath,
                  onFileSave: onFileSave,
                ),
              ],
            ],
          ),
          // 우측 상단 X 버튼
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
                debugPrint('저장 취소');
              },
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF757575),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 체크박스 빌더
  static Widget buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 18,
          height: 18,
          child: Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            activeColor: const Color(0xFF555555),
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(3),
            ), 
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13, 
            color: Color(0xFF424242),
            fontWeight: FontWeight.w400,
            letterSpacing: -0.1,
          ),
        ),
      ],
    );
  }

  // 위치 선택 버튼 빌더
  static Widget buildLocationButton({
    required String text,
    required String location,
    required bool isSelected,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? const Color(0xFF3C3C3C) : const Color(0xFF757575),
          foregroundColor: Colors.white,
          elevation: isSelected ? 2 : 0,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          minimumSize: const Size(70, 32),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12, 
            fontWeight: FontWeight.w500,
            letterSpacing: -0.1,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '이메일 주소',
            style: TextStyle(
              fontSize: 12, 
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    onChanged: onEmailAddressChanged,
                    style: const TextStyle(fontSize: 12, color: Color(0xFF2C2C2C)),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(color: Color(0xFF757575)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD0D0D0)),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.white,
                ),
                child: DropdownButton<String>(
                  value: emailDomain,
                  items: const [
                    DropdownMenuItem(value: 'naver.com', child: Text('naver.com')),
                    DropdownMenuItem(value: 'gmail.com', child: Text('gmail.com')),
                    DropdownMenuItem(value: 'daum.net', child: Text('daum.net')),
                  ],
                  onChanged: (value) => onEmailDomainChanged(value ?? 'naver.com'),
                  style: const TextStyle(
                    fontSize: 12, 
                    color: Color(0xFF2C2C2C),
                    fontWeight: FontWeight.w400,
                  ),
                  underline: Container(),
                  isDense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: emailAddress.isNotEmpty ? onEmailSend : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF555555),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                minimumSize: const Size(60, 32),
              ),
              child: const Text(
                '전송',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.1,
                ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '저장 경로',
            style: TextStyle(
              fontSize: 12, 
              color: Color(0xFF424242),
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 36,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFAFAFA),
              border: Border.all(color: const Color(0xFFD0D0D0)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                selectedFilePath ?? '저장 경로를 선택해주세요',
                style: TextStyle(
                  fontSize: 12,
                  color: selectedFilePath != null ? const Color(0xFF2C2C2C) : const Color(0xFF757575),
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.1,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: onSelectPath,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF757575),
                    foregroundColor: Colors.white,
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    minimumSize: const Size(70, 32),
                  ),
                  child: const Text(
                    '경로 선택',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: selectedFilePath != null ? onFileSave : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF555555),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFBDBDBD),
                    elevation: 1,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    minimumSize: const Size(60, 32),
                  ),
                  child: const Text(
                    '저장',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.1,
                    ),
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