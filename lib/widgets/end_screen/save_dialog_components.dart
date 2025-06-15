import 'package:flutter/material.dart';

class SaveDialogComponents {
  
  static Widget buildMainSection({
    required bool isContentFile,
    required String selectedLocation,
    required String? selectedFilePath,
    required String emailAddress,
    required String emailDomain,
    required Function(bool) onContentFileChanged,
    required Function(String) onLocationChanged,
    required Function(String) onEmailAddressChanged,
    required Function(String) onEmailDomainChanged,
    required VoidCallback onSelectPath,
    required VoidCallback onEmailSend,
    required VoidCallback onFileSave,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFC8C8C8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF999999), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '저장할 파일을 선택하세요',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 12),
          
          // 체크박스들
          Row(
            children: [
              buildCheckbox('내용 파일', isContentFile, onContentFileChanged),
              const SizedBox(width: 15),
              buildCheckbox('요약 파일', !isContentFile, (value) {
                onContentFileChanged(!value);
              }),
            ],
          ),
          
          const SizedBox(height: 18),
          
          const Text(
            '저장 위치를 선택하세요',
            style: TextStyle(fontSize: 13, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          
          // 위치 선택 버튼들
          Row(
            children: [
              buildLocationButton(
                text: '이메일',
                location: 'email',
                isSelected: selectedLocation == 'email',
                onPressed: () => onLocationChanged('email'),
              ),
              const SizedBox(width: 8),
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
          
          // 저장 경로 섹션 (조건부 표시 - 애니메이션 포함)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            height: selectedLocation == 'email' ? 120 : 
                   selectedLocation == 'computer' ? 100 : 0,
            child: selectedLocation.isNotEmpty 
                ? Padding(
                    padding: const EdgeInsets.only(top: 15),
                    child: selectedLocation == 'email' 
                        ? buildEmailSection(
                            emailAddress: emailAddress,
                            emailDomain: emailDomain,
                            onEmailAddressChanged: onEmailAddressChanged,
                            onEmailDomainChanged: onEmailDomainChanged,
                            onEmailSend: onEmailSend,
                          )
                        : buildComputerSection(
                            selectedFilePath: selectedFilePath,
                            onSelectPath: onSelectPath,
                            onFileSave: onFileSave,
                          ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static Widget buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: Checkbox(
            value: value,
            onChanged: (newValue) => onChanged(newValue ?? false),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
      ],
    );
  }

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
          backgroundColor: isSelected ? const Color(0xFF4A4A4A) : const Color(0xFF666666),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: const Size(60, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }

  static Widget buildEmailSection({
    required String emailAddress,
    required String emailDomain,
    required Function(String) onEmailAddressChanged,
    required Function(String) onEmailDomainChanged,
    required VoidCallback onEmailSend,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '이메일 주소',
          style: TextStyle(fontSize: 11, color: Colors.black),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 28,
                child: TextField(
                  onChanged: onEmailAddressChanged,
                  style: const TextStyle(fontSize: 11),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    isDense: true,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF999999)),
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
                style: const TextStyle(fontSize: 11, color: Colors.pink),
                underline: Container(),
                isDense: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: emailAddress.isNotEmpty ? onEmailSend : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF666666),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF999999),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: const Size(50, 28),
            ),
            child: const Text('전송', style: TextStyle(fontSize: 11)),
          ),
        ),
      ],
    );
  }

  static Widget buildComputerSection({
    required String? selectedFilePath,
    required VoidCallback onSelectPath,
    required VoidCallback onFileSave,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFF999999)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              selectedFilePath ?? '저장 경로를 선택해주세요',
              style: TextStyle(
                fontSize: 11,
                color: selectedFilePath != null ? Colors.black : Colors.grey[600],
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: onSelectPath,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF666666),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: const Size(60, 28),
                ),
                child: const Text('경로 선택', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 28,
              child: ElevatedButton(
                onPressed: selectedFilePath != null ? onFileSave : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF666666),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF999999),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  minimumSize: const Size(50, 28),
                ),
                child: const Text('전송', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}