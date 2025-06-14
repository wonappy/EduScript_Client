/// OnOffSwitch
/// 화면 공유 on/off 시 사용하는 위젯

import 'package:flutter/material.dart';

class OnOffSwitch extends StatefulWidget {
  final bool initialValue; // 초기 상태
  final Function(bool)? onChanged; // 상태 변경 시 콜백

  const OnOffSwitch({super.key, this.initialValue = true, this.onChanged});

  @override
  State<OnOffSwitch> createState() => _OnOffSwitchState();
}

class _OnOffSwitchState extends State<OnOffSwitch> {
  late bool isOn; // 현재 상태

  @override
  void initState() {
    super.initState();
    isOn = widget.initialValue; // 부모로부터 받은 초기값으로 설정
  }

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: isOn, // 현재 스위치 상태
      activeColor: Colors.blue, // 활성화 시 색상 (ON)
      onChanged: (bool value) {
        setState(() {
          isOn = value; // 상태 업데이트
        });
        widget.onChanged?.call(value); // 콜백
      },
    );
  }
}
