import 'package:flutter/material.dart';
import '../../../models/doctor_model.dart';
import '../../../models/services_model.dart';
import '../../../core/services/doctor_api.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/booking_api.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  List<DoctorModel> doctors = [];
  List<ServiceModel> services = [];

  DoctorModel? selectedDoctor;
  ServiceModel? selectedService;

  final namaPemilik = TextEditingController();
  final email = TextEditingController();
  final telepon = TextEditingController();
  final namaHewan = TextEditingController();
  final umur = TextEditingController();

  String jenisHewan = "Kucing";
  DateTime selectedDate = DateTime.now();
  String selectedTime = "09:00";

  final times = ["09:00", "10:00", "11:00", "13:00", "14:00"];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    try {
      final d = await DoctorApi.fetchDoctors();
      final s = await ServiceApi.fetchServices();

      if (d.isEmpty || s.isEmpty) {
        throw Exception("Data kosong");
      }

      setState(() {
        doctors = d;
        services = s;
        selectedDoctor = doctors.first;
        selectedService = services.first;
        loading = false;
      });
    } catch (e) {
      print("ERROR LOAD: $e");
      setState(() => loading = false);
    }
  }

  Future<void> submit() async {
    final booking = await BookingApi.createBooking(
      namaPemilik: namaPemilik.text,
      email: email.text,
      telepon: telepon.text,
      namaHewan: namaHewan.text,
      jenisHewan: jenisHewan,
      umur: int.parse(umur.text),
      serviceId: selectedService!.id,
      doctorId: selectedDoctor!.id,
      bookingDate:
          "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}",
      bookingTime: selectedTime,
    );

    showModalBottomSheet(
      context: context,
      builder: (_) => SuccessSheet(booking: booking),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Booking")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: namaPemilik,
              decoration: const InputDecoration(labelText: "Nama Pemilik"),
            ),
            TextField(
              controller: email,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: telepon,
              decoration: const InputDecoration(labelText: "Telepon"),
            ),
            TextField(
              controller: namaHewan,
              decoration: const InputDecoration(labelText: "Nama Hewan"),
            ),
            TextField(
              controller: umur,
              decoration: const InputDecoration(labelText: "Umur Hewan"),
              keyboardType: TextInputType.number,
            ),

            DropdownButtonFormField<String>(
              value: jenisHewan,
              items: [
                "Kucing",
                "Anjing",
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => jenisHewan = v!),
            ),

            DropdownButtonFormField<DoctorModel>(
              value: selectedDoctor,
              items: doctors
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => selectedDoctor = v),
            ),

            DropdownButtonFormField<ServiceModel>(
              value: selectedService,
              items: services
                  .map((e) => DropdownMenuItem(value: e, child: Text(e.name)))
                  .toList(),
              onChanged: (v) => setState(() => selectedService = v),
            ),

            DropdownButtonFormField<String>(
              value: selectedTime,
              items: times
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) => setState(() => selectedTime = v!),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : submit,
              child: const Text("Booking Sekarang"),
            ),
          ],
        ),
      ),
    );
  }
}

class SuccessSheet extends StatelessWidget {
  final booking;

  const SuccessSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle, size: 60, color: Colors.green),
          const SizedBox(height: 16),
          const Text("Booking Berhasil 🎉"),
          const SizedBox(height: 10),
          Text("Nomor Antrian: ${booking.nomorAntrian}"),
          Text("Tanggal: ${booking.bookingDate}"),
          Text("Jam: ${booking.bookingTime}"),
        ],
      ),
    );
  }
}
