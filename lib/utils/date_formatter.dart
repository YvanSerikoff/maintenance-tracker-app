import 'package:intl/intl.dart';

String formatDate(DateTime date) {
  return DateFormat('dd/MM/yyyy').format(date);
}

String formatDateFull(DateTime date) {
  return DateFormat('dd MMM yyyy, HH:mm').format(date);
}

String formatDateRelative(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  
  if (difference.inDays > 7) {
    return formatDate(date);
  } else if (difference.inDays > 1) {
    return '${difference.inDays} days ago';
  } else if (difference.inDays == 1) {
    return 'Yesterday';
  } else if (difference.inHours > 1) {
    return '${difference.inHours} hours ago';
  } else if (difference.inMinutes > 1) {
    return '${difference.inMinutes} minutes ago';
  } else {
    return 'Just now';
  }
}

String formatTimeAgo(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);
  
  if (difference.inDays > 365) {
    return '${(difference.inDays / 365).floor()} year(s) ago';
  } else if (difference.inDays > 30) {
    return '${(difference.inDays / 30).floor()} month(s) ago';
  } else if (difference.inDays > 0) {
    return '${difference.inDays} day(s) ago';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hour(s) ago';
  } else if (difference.inMinutes > 0) {
    return '${difference.inMinutes} minute(s) ago';
  } else {
    return 'Just now';
  }
}