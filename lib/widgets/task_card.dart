import 'package:flutter/material.dart';
import 'package:maintenance_app/models/maintenance_task.dart';
import 'package:maintenance_app/config/constants.dart';
import 'package:maintenance_app/screens/tasks/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  final MaintenanceTask task;
  final VoidCallback? onTap;

  const TaskCard({Key? key, required this.task, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String statusText;

    switch (task.status) {
      case AppConstants.STATUS_PENDING:
        statusColor = Colors.orange;
        statusText = 'Pending';
        break;
      case AppConstants.STATUS_IN_PROGRESS:
        statusColor = Colors.blue;
        statusText = 'In Progress';
        break;
      case AppConstants.STATUS_COMPLETED:
        statusColor = Colors.green;
        statusText = 'Completed';
        break;
      case AppConstants.STATUS_CANCELLED:
        statusColor = Colors.red;
        statusText = 'Rebuttal';
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Unknown';
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: Container(
          width: 12,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor,
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        title: Text(
          task.name,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  '${task.scheduledDate.day}/${task.scheduledDate.month}/${task.scheduledDate.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right),
        onTap: onTap ?? () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TaskDetailScreen(task: task),
            ),
          );
        },
      ),
    );
  }
}

