import 'package:flutter/material.dart';
import '../models/student_task.dart';
import '../models/class_schedule.dart';
import '../utils/date_formatter.dart';

enum ExpandedCard { none, task, schedule }

class DashboardBanner extends StatefulWidget {
  final StudentTask? nearestTask;
  final ClassSchedule? nearestSchedule;

  const DashboardBanner({
    super.key,
    required this.nearestTask,
    required this.nearestSchedule,
  });

  @override
  State<DashboardBanner> createState() => _DashboardBannerState();
}

class _DashboardBannerState extends State<DashboardBanner> {
  ExpandedCard _currentExpanded = ExpandedCard.none;

  void _toggleExpand(ExpandedCard card) {
    setState(() {
      if (_currentExpanded == card) {
        _currentExpanded = ExpandedCard.none;
      } else {
        _currentExpanded = card;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A00E0), Color(0xFF8E2DE2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hi, Bro!",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: _currentExpanded == ExpandedCard.task ? 3 : 1,
                child: GestureDetector(
                  onTap: () => _toggleExpand(ExpandedCard.task),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Colors.yellowAccent, size: 16),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text("Tugas Mepet", style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _currentExpanded == ExpandedCard.task ? 16 : 13,
                          ),
                          child: Text(
                            widget.nearestTask?.title ?? "Aman no tugas!",
                            maxLines: _currentExpanded == ExpandedCard.task ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.nearestTask != null)
                          Text(
                            formatWaktu(widget.nearestTask!.deadline),
                            style: const TextStyle(color: Colors.yellowAccent, fontSize: 11),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: _currentExpanded != ExpandedCard.none ? 0 : 5,
              ),
              Expanded(
                flex: _currentExpanded == ExpandedCard.schedule ? 3 : 1,
                child: GestureDetector(
                  onTap: () => _toggleExpand(ExpandedCard.schedule),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOutCubic,
                    margin: const EdgeInsets.only(left: 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.class_, color: Colors.lightBlueAccent, size: 16),
                            SizedBox(width: 5),
                            Expanded(
                              child: Text("Next Kelas", style: TextStyle(color: Colors.white70, fontSize: 11)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 300),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: _currentExpanded == ExpandedCard.schedule ? 16 : 13,
                          ),
                          child: Text(
                            widget.nearestSchedule?.course ?? "Free Class!",
                            maxLines: _currentExpanded == ExpandedCard.schedule ? 3 : 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.nearestSchedule != null)
                          Text(
                            "${widget.nearestSchedule!.startTime} di ${widget.nearestSchedule!.room}",
                            style: const TextStyle(color: Colors.lightBlueAccent, fontSize: 11),
                            maxLines: _currentExpanded == ExpandedCard.schedule ? 2 : 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
