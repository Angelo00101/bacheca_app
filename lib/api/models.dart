DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

String _two(int n) => n.toString().padLeft(2, '0');

/// Formatta una data come gg/mm/aaaa.
String formatDate(DateTime? d) =>
    d == null ? '' : '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// Formatta data e ora come gg/mm/aaaa hh:mm.
String formatDateTime(DateTime? d) =>
    d == null ? '' : '${formatDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

class Company {
  final int id;
  final String name;
  final String email;

  const Company({required this.id, required this.name, required this.email});

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        id: json['id'] as int,
        name: json['name'] as String,
        email: json['email'] as String,
      );
}

class Job {
  final int id;
  final String title;
  final String description;
  final String location;
  final String companyName;
  final DateTime? createdAt;

  /// Presente solo negli annunci dell'area riservata.
  final int? applicationsCount;

  const Job({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.companyName,
    this.createdAt,
    this.applicationsCount,
  });

  factory Job.fromJson(Map<String, dynamic> json) => Job(
        id: json['id'] as int,
        title: json['title'] as String,
        description: json['description'] as String,
        location: (json['location'] as String?) ?? '',
        companyName: (json['company_name'] as String?) ?? '',
        createdAt: _parseDate(json['created_at']),
        applicationsCount: json['applications_count'] as int?,
      );
}

class JobApplication {
  final int id;
  final int jobId;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String cvOriginalName;
  final DateTime? createdAt;

  const JobApplication({
    required this.id,
    required this.jobId,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.cvOriginalName,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  factory JobApplication.fromJson(Map<String, dynamic> json) => JobApplication(
        id: json['id'] as int,
        jobId: json['job_id'] as int,
        firstName: json['first_name'] as String,
        lastName: json['last_name'] as String,
        email: json['email'] as String,
        phone: (json['phone'] as String?) ?? '',
        cvOriginalName: (json['cv_original_name'] as String?) ?? 'curriculum.pdf',
        createdAt: _parseDate(json['created_at']),
      );
}
