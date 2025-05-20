class User {
  final int id;
  final String name;
  final String login;
  final String email;
  final bool hasEmail;
  final bool active;
  final String lang;
  final String tz;
  final Company? company;
  final Partner? partner;
  final MaintenancePerson? maintenancePerson;
  final List<dynamic> teams;
  final Permissions? permissions;

  User({
    required this.id,
    required this.name,
    required this.login,
    required this.email,
    required this.hasEmail,
    required this.active,
    required this.lang,
    required this.tz,
    this.company,
    this.partner,
    this.maintenancePerson,
    this.teams = const [],
    this.permissions,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] ?? {};
    return User(
      id: userJson['id'] ?? 0,
      name: userJson['name'] ?? '',
      login: userJson['login'] ?? '',
      email: userJson['email'] ?? '',
      hasEmail: userJson['has_email'] ?? false,
      active: userJson['active'] ?? false,
      lang: userJson['lang'] ?? '',
      tz: userJson['tz'] ?? '',
      company: userJson['company_id'] != null ? Company.fromJson(userJson['company_id']) : null,
      partner: userJson['partner_id'] != null ? Partner.fromJson(userJson['partner_id']) : null,
      maintenancePerson: json['maintenance_person'] != null ? MaintenancePerson.fromJson(json['maintenance_person']) : null,
      teams: json['teams'] ?? [],
      permissions: json['permissions'] != null ? Permissions.fromJson(json['permissions']) : null,
    );
  }
}

class Company {
  final int id;
  final String name;

  Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }
}

class Partner {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String mobile;

  Partner({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.mobile,
  });

  factory Partner.fromJson(Map<String, dynamic> json) {
    return Partner(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      mobile: json['mobile'] ?? '',
    );
  }
}

class MaintenancePerson {
  final int id;
  final String displayName;
  final String firstName;
  final String name;
  final String email;
  final String phone;
  final String mobile;
  final bool available;
  final Role? role;
  final String specialties;
  final String certifications;
  final String? hireDate;
  final String employeeNumber;
  final int requestCount;

  MaintenancePerson({
    required this.id,
    required this.displayName,
    required this.firstName,
    required this.name,
    required this.email,
    required this.phone,
    required this.mobile,
    required this.available,
    this.role,
    required this.specialties,
    required this.certifications,
    this.hireDate,
    required this.employeeNumber,
    required this.requestCount,
  });

  factory MaintenancePerson.fromJson(Map<String, dynamic> json) {
    return MaintenancePerson(
      id: json['id'] ?? 0,
      displayName: json['display_name'] ?? '',
      firstName: json['first_name'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      mobile: json['mobile'] ?? '',
      available: json['available'] ?? false,
      role: json['role'] != null ? Role.fromJson(json['role']) : null,
      specialties: json['specialties'] ?? '',
      certifications: json['certifications'] ?? '',
      hireDate: json['hire_date'],
      employeeNumber: json['employee_number'] ?? '',
      requestCount: json['request_count'] ?? 0,
    );
  }
}

class Role {
  final int id;
  final String name;
  final String description;

  Role({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class Permissions {
  final bool canCreateRequest;
  final bool canManageTeamRequests;
  final bool canAssignRequests;
  final bool canManageAllRequests;
  final bool canValidateRequests;

  Permissions({
    required this.canCreateRequest,
    required this.canManageTeamRequests,
    required this.canAssignRequests,
    required this.canManageAllRequests,
    required this.canValidateRequests,
  });

  factory Permissions.fromJson(Map<String, dynamic> json) {
    return Permissions(
      canCreateRequest: json['can_create_request'] ?? false,
      canManageTeamRequests: json['can_manage_team_requests'] ?? false,
      canAssignRequests: json['can_assign_requests'] ?? false,
      canManageAllRequests: json['can_manage_all_requests'] ?? false,
      canValidateRequests: json['can_validate_requests'] ?? false,
    );
  }
}