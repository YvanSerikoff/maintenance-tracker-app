String? validateRequired(String? value) {
  if (value == null || value.isEmpty) {
    return 'This field is required';
  }
  return null;
}

String? validateEmail(String? value) {
  if (value == null || value.isEmpty) {
    return 'Email is required';
  }
  
  final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  if (!emailRegExp.hasMatch(value)) {
    return 'Enter a valid email address';
  }
  
  return null;
}

String? validateUrl(String? value) {
  if (value == null || value.isEmpty) {
    return 'URL is required';
  }
  
  // Basic URL validation - you might want more sophisticated validation
  if (!value.startsWith('http://') && !value.startsWith('https://')) {
    return 'URL must start with http:// or https://';
  }
  
  return null;
}

String? validatePassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Password is required';
  }
  
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  
  return null;
}