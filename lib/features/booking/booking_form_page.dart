// import 'package:flutter/material.dart';
// import '../../core/services/booking_api.dart';
// import 'booking_success_page.dart';

// class BookingFormPage extends StatefulWidget {
//   final int serviceId;
//   final int doctorId;
//   final String bookingDate;
//   final String bookingTime;

//   const BookingFormPage({
//     super.key,
//     required this.serviceId,
//     required this.doctorId,
//     required this.bookingDate,
//     required this.bookingTime,
//   });

//   @override
//   State<BookingFormPage> createState() => _BookingFormPageState();
// }

// class _BookingFormPageState extends State<BookingFormPage> {
//   final namaController = TextEditingController();
//   final emailController = TextEditingController();
//   final teleponController = TextEditingController();
//   final namaHewanController = TextEditingController();
//   final jenisController = TextEditingController();
//   final rasController = TextEditingController();
//   final umurController = TextEditingController();

//   bool isLoading = false;

//   void submitBooking() async {
//     setState(() => isLoading = true);

//     try {
//       final booking = await BookingApi.createBooking(
//         serviceId: widget.serviceId,
//         doctorId: widget.doctorId,
//         bookingDate: widget.bookingDate,
//         bookingTime: widget.bookingTime,
//         namaPemilik: namaController.text,
//         email: emailController.text,
//         telepon: teleponController.text,
//         namaHewan: namaHewanController.text,
//         jenisHewan: jenisController.text,
//         ras: rasController.text,
//         umur: int.parse(umurController.text),
//       );

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => BookingSuccessPage(booking: booking),
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("Booking gagal")),
//       );
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Isi Data")),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             TextField(controller: namaController, decoration: const InputDecoration(labelText: "Nama Pemilik")),
//             TextField(controller: emailController, decoration: const InputDecoration(labelText: "Email")),
//             TextField(controller: teleponController, decoration: const InputDecoration(labelText: "Telepon")),
//             TextField(controller: namaHewanController, decoration: const InputDecoration(labelText: "Nama Hewan")),
//             TextField(controller: jenisController, decoration: const InputDecoration(labelText: "Jenis Hewan")),
//             TextField(controller: rasController, decoration: const InputDecoration(labelText: "Ras")),
//             TextField(controller: umurController, decoration: const InputDecoration(labelText: "Umur")),
//             const SizedBox(height: 20),
//             isLoading
//                 ? const CircularProgressIndicator()
//                 : ElevatedButton(
//                     onPressed: submitBooking,
//                     child: const Text("Konfirmasi Booking"),
//                   )
//           ],
//         ),
//       ),
//     );
//   }
// }
