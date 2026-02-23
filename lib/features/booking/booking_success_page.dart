// import 'package:flutter/material.dart';
// import '../../models/booking_model.dart';

// class BookingSuccessPage extends StatelessWidget {
//   final BookingModel booking;

//   const BookingSuccessPage({super.key, required this.booking});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Booking Berhasil")),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text("Kode Booking: ${booking.bookingCode}"),
//             Text("Nomor Antrian: ${booking.nomorAntrian}"),
//             Text("Layanan: ${booking.service}"),
//             Text("Dokter: ${booking.doctor}"),
//             Text("Tanggal: ${booking.bookingDate}"),
//             Text("Waktu: ${booking.bookingTime}"),
//             Text("Total: Rp ${booking.totalPrice}"),
//           ],
//         ),
//       ),
//     );
//   }
// }
