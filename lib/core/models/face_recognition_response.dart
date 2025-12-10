class FaceRecognitionResponse {
  final String status;
  final String? nama;
  final double? jarakKemiripan;
  final bool? dikenali;
  final String? pesan;

  FaceRecognitionResponse({
    required this.status,
    this.nama,
    this.jarakKemiripan,
    this.dikenali,
    this.pesan,
  });

  factory FaceRecognitionResponse.fromJson(Map<String, dynamic> json) {
    return FaceRecognitionResponse(
      status: json['status'] as String,
      nama: json['nama'] as String?,
      jarakKemiripan: json['jarak_kemiripan'] != null
          ? (json['jarak_kemiripan'] as num).toDouble()
          : null,
      dikenali: json['dikenali'] as bool?,
      pesan: json['pesan'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'nama': nama,
      'jarak_kemiripan': jarakKemiripan,
      'dikenali': dikenali,
      'pesan': pesan,
    };
  }

  bool get isSuccess => status == 'sukses';
  bool get isFaceDetected => status != 'gagal';
  bool get isRecognized => dikenali == true;
}
