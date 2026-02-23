// import 'package:flutter/material.dart';
// import '../../../models/services_model.dart';
// import '../../../core/services/api_service.dart';
// import 'services_detail_page.dart';

// class ServicesPage extends StatefulWidget {
//   @override
//   _ServicesPageState createState() => _ServicesPageState();
// }

// class _ServicesPageState extends State<ServicesPage> {
//   late Future<List<ServiceModel>> servicesFuture;
//   String selectedFilter = "all";

//   @override
//   void initState() {
//     super.initState();
//     servicesFuture = ServiceApi.fetchServices();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text("Layanan")),
//       body: FutureBuilder<List<ServiceModel>>(
//         future: servicesFuture,
//         builder: (context, snapshot) {
//           if (!snapshot.hasData) {
//             return Center(child: CircularProgressIndicator());
//           }

//           List<ServiceModel> services = snapshot.data!;

//           if (selectedFilter != "all") {
//             services = services
//                 .where((s) => s.serviceType == selectedFilter)
//                 .toList();
//           }

//           return Column(
//             children: [
//               SizedBox(height: 10),

//               // FILTER BUTTON
//               SingleChildScrollView(
//                 scrollDirection: Axis.horizontal,
//                 child: Row(
//                   children: [
//                     filterButton("all", "Semua"),
//                     filterButton("general", "Umum"),
//                     filterButton("vaccination", "Vaksin"),
//                     filterButton("surgery", "Operasi"),
//                     filterButton("grooming", "Grooming"),
//                   ],
//                 ),
//               ),

//               Expanded(
//                 child: ListView.builder(
//                   itemCount: services.length,
//                   itemBuilder: (context, index) {
//                     final service = services[index];

//                     return Card(
//                       margin: EdgeInsets.all(10),
//                       child: ListTile(
//                         title: Text(service.name),
//                         subtitle: Text(service.description),
//                         trailing: Text(service.formattedPrice),
//                         onTap: () {
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (_) =>
//                                   ServiceDetailPage(service: service),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   Widget filterButton(String type, String label) {
//     return Padding(
//       padding: EdgeInsets.symmetric(horizontal: 5),
//       child: ElevatedButton(
//         onPressed: () {
//           setState(() {
//             selectedFilter = type;
//           });
//         },
//         child: Text(label),
//       ),
//     );
//   }
// }
