import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';
import 'education_screen.dart';
class PaymentUploadScreen extends StatefulWidget {
  final int transactionId;
  final String paymentMethod;
  final String paymentInstructions;

  const PaymentUploadScreen({
    Key? key,
    required this.transactionId,
    required this.paymentMethod,
    required this.paymentInstructions,
  }) : super(key: key);

  @override
  _PaymentUploadScreenState createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _provinceController = TextEditingController();
  final _postalController = TextEditingController();

  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  final ApiService _apiService = ApiService();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadPayment() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan pilih foto bukti transfer terlebih dahulu')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String fileName = _image!.path.split('/').last;
      FormData formData = FormData.fromMap({
        'transaction_id': widget.transactionId,
        'payment_method': widget.paymentMethod,
        'phone_number': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'province': _provinceController.text,
        'postal_code': _postalController.text,
        'proof_image': await MultipartFile.fromFile(_image!.path, filename: fileName),
      });

      final response = await _apiService.post('payment', formData);

      if (response.statusCode == 201) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('Berhasil'),
            content: Text('Bukti pembayaran berhasil diunggah. Menunggu verifikasi admin.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EducationScreen()),
                  );
                },
                child: Text('OK'),
              )
            ],
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengunggah bukti pembayaran. Pastikan ukuran file sesuai.')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Upload Bukti Transfer')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Informasi Transfer (${widget.paymentMethod}):', 
                             style: TextStyle(fontSize: 14, color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text(
                          widget.paymentInstructions,
                          style: TextStyle(fontSize: 16, color: Colors.green.shade900),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Text('Informasi Pengiriman', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(labelText: 'Nomor HP', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _addressController,
                          maxLines: 3,
                          decoration: InputDecoration(labelText: 'Alamat Lengkap', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(labelText: 'Kota/Kabupaten', border: OutlineInputBorder()),
                                validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: _provinceController,
                                decoration: InputDecoration(labelText: 'Provinsi', border: OutlineInputBorder()),
                                validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        TextFormField(
                          controller: _postalController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(labelText: 'Kode Pos', border: OutlineInputBorder()),
                          validator: (value) => value == null || value.isEmpty ? 'Wajib diisi' : null,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Text('Pilih Foto Bukti Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 250,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _image != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(_image!, fit: BoxFit.cover),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey),
                                SizedBox(height: 16),
                                Text('Ketuk untuk memilih foto', style: TextStyle(color: Colors.grey.shade600)),
                              ],
                            ),
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _uploadPayment,
                    child: Text('Unggah Bukti', style: TextStyle(fontSize: 18)),
                  ),
                  SizedBox(height: 48),
                ],
              ),
            ),
    );
  }
}
