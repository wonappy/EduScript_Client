// /// 재생 부분 컨트롤 버튼 위젯
// library;

// import 'package:flutter/material.dart';

// import '../../../core/global_core.dart';

// class BuildLecturePlayBarContent extends StatefulWidget {
//   final double screenWidth;
//   final double screenHeight;
//   final int? counterValue;  //widget_test.dart

//   const BuildLecturePlayBarContent({
//     super.key,
//     required this.screenWidth,
//     required this.screenHeight,
//     this.counterValue
//   });

//   @override
//   State<BuildLecturePlayBarContent> createState() => _BuildLecturePlayBarContentState();
// }

// class _BuildLecturePlayBarContentState extends State<BuildLecturePlayBarContent> {
//   bool isPlaying = false;
//   String currentTime = "00:00:00";

//   // 카운터 값을 시간으로 변환하는 함수
//   String _formatTimeFromCounter(int seconds){
//     int hours = seconds ~/ 3600;
//     int minutes = (seconds % 3600) ~/ 60;
//     int secs = seconds % 60;
//     return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
//   }

//   @override
//   Widget build(BuildContext context) {
//     // 외부 카운터 값이 있으면 사용, 없으면 기본값
//     String displayTime = widget.counterValue != null 
//         ? _formatTimeFromCounter(widget.counterValue!) 
//         : currentTime;
//     return Container(
//       padding: EdgeInsets.symmetric(
//         horizontal: widget.screenWidth * 0.04,
//         vertical: widget.screenWidth * 0.02,
//       ),
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(widget.screenWidth * 0.02),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           // 닫기 버튼 (재생 중일 때만 표시)
//           if (isPlaying) ...[
//             _buildControlIcon(
//               icon: Icons.close,
//               onTap: () {
//                 setState(() {
//                   isPlaying = false;
//                   currentTime = "00:00:00";
//                 });
//                 debugPrint('강의 종료');
//               },
//             ),
//             SizedBox(width: widget.screenWidth * 0.03),
//           ],
          
//           // 메인 재생/일시정지 버튼
//           GestureDetector(
//             onTap: () {
//               setState(() {
//                 if (!isPlaying) {
//                   isPlaying = true;
//                   currentTime = "00:40:00"; // 예시 시간
//                 } else {
//                   // 일시정지/재생 토글
//                 }
//               });
//               debugPrint(isPlaying ? '일시정지' : '강의 시작');
//             },
//             child: Container(
//               width: widget.screenWidth * 0.12,
//               height: widget.screenWidth * 0.12,
//               decoration: const BoxDecoration(
//                 color: Colors.black87,
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 isPlaying ? Icons.pause : Icons.play_arrow,
//                 color: Colors.white,
//                 size: widget.screenWidth * 0.06,
//               ),
//             ),
//           ),
          
//           // 정지 버튼 (재생 중일 때만 표시)
//           if (isPlaying) ...[
//             SizedBox(width: widget.screenWidth * 0.03),
//             _buildControlIcon(
//               icon: Icons.stop,
//               onTap: () {
//                 setState(() {
//                   isPlaying = false;
//                   currentTime = "00:00:00";
//                 });
//                 debugPrint('정지');
//               },
//             ),
//           ],
          
//           SizedBox(width: widget.screenWidth * 0.04),
          
//           // 시간 표시
//           Text(
//             displayTime,
//             style: TextStyle(
//               fontSize: getResponsiveFontSize(widget.screenWidth) * 0.8,
//               fontWeight: FontWeight.w500,
//               color: Colors.black87,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildControlIcon({
//     required IconData icon,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: EdgeInsets.all(widget.screenWidth * 0.02),
//         child: Icon(
//           icon,
//           color: Colors.black87,
//           size: widget.screenWidth * 0.05,
//         ),
//       ),
//     );
//   }
// }
