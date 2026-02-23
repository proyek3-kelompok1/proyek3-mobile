// import 'package:flutter/material.dart';
// import '../../../models/services_model.dart';
// import '../../booking/booking_doctor_page.dart';

// class ServiceDetailPage extends StatelessWidget {
//   final ServiceModel service;

//   const ServiceDetailPage({required this.service});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(service.name)),
//       body: Padding(
//         padding: EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(service.description),
//             SizedBox(height: 10),
//             Text("Harga: ${service.formattedPrice}"),
//             Text("Durasi: ${service.formattedDuration}"),
//             SizedBox(height: 20),
//             Text(service.details),
//             SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(
//                       builder: (_) => BookingDoctorPage(serviceId: service.id),
//                     ),
//                   );
//                 },
//                 child: Text("Booking Sekarang"),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
