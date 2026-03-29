import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Dashboard',
          style: GoogleFonts.lato(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome Back!',
              style: GoogleFonts.lato(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Here’s your activity overview.',
              style: GoogleFonts.lato(color: Colors.grey[700]),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildStatCard(
                  icon: Icons.medical_services,
                  title: 'Medications',
                  value: '5',
                  color: Colors.orange,
                ),
                _buildStatCard(
                  icon: Icons.person,
                  title: 'Patients',
                  value: '12',
                  color: Colors.green,
                ),
                _buildStatCard(
                  icon: Icons.notifications,
                  title: 'Reminders',
                  value: '3',
                  color: Colors.red,
                ),
                _buildStatCard(
                  icon: Icons.history,
                  title: 'History',
                  value: '8',
                  color: Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 30),
            Text(
              'Recent Activities',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildActivityTile(
              icon: Icons.check_circle,
              title: 'Consultation Completed',
              subtitle: 'Yesterday, 03:00 PM',
              color: Colors.green,
            ),
            _buildActivityTile(
              icon: Icons.pending_actions,
              title: 'New Appointment',
              subtitle: 'Today, 11:00 AM',
              color: Colors.orange,
            ),
            _buildActivityTile(
              icon: Icons.warning,
              title: 'Missed Dose',
              subtitle: 'Today, 08:00 AM',
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 15),
          Text(
            title,
            style: GoogleFonts.lato(fontSize: 14, color: Colors.grey[700]),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.lato(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(
          title,
          style: GoogleFonts.lato(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.lato(color: Colors.grey[600], fontSize: 12),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {},
      ),
    );
  }
}