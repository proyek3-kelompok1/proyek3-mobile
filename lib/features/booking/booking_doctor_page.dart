// import 'package:flutter/material.dart';
// import 'booking_form_page.dart';

// class BookingDoctorPage extends StatefulWidget {
//   final int serviceId;

//   const BookingDoctorPage({super.key, required this.serviceId});

//   @override
//   State<BookingDoctorPage> createState() => _BookingDoctorPageState();
// }

// class _BookingDoctorPageState extends State<BookingDoctorPage> {
//   int? selectedDoctorId;
//   String selectedDate = "";
//   String selectedTime = "";

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Pilih Dokter")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             DropdownButtonFormField<int>(
//               decoration: const InputDecoration(labelText: "Dokter"),
//               items: const [
//                 DropdownMenuItem(value: 1, child: Text("Dr. Andi")),
//                 DropdownMenuItem(value: 2, child: Text("Dr. Sinta")),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   selectedDoctorId = value;
//                 });
//               },
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               decoration:
//                   const InputDecoration(labelText: "Tanggal (YYYY-MM-DD)"),
//               onChanged: (value) => selectedDate = value,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               decoration:
//                   const InputDecoration(labelText: "Waktu (09:00)"),
//               onChanged: (value) => selectedTime = value,
//             ),
//             const SizedBox(height: 20),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (_) => BookingFormPage(
//                       serviceId: widget.serviceId,
//                       doctorId: selectedDoctorId!,
//                       bookingDate: selectedDate,
//                       bookingTime: selectedTime,
//                     ),
//                   ),
//                 );
//               },
//               child: const Text("Lanjut"),
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
