import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Construction/Provider/ConstructionSite/Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  String? selectedSite;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
      final siteProvider = Provider.of<SiteProvider>(context, listen: false);

      await attendanceProvider.fetchOwnerDashboardSummary();

      final user = await attendanceProvider.authService.getCurrentUser();
      final ownerId = user?.id ?? '';
      await siteProvider.fetchSitesByOwner(ownerId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 1200;
    final isMediumScreen = screenWidth > 800;
    final attendanceProvider = Provider.of<AttendanceProvider>(context);
    final siteProvider = Provider.of<SiteProvider>(context);

    final summary = attendanceProvider.ownerDashboardSummary;
    int todayPresent = summary?['today']?['present'] ?? 0;
    int todayAbsent = summary?['today']?['absent'] ?? 0;
    int monthlyPresent = summary?['month']?['present'] ?? 0;
    int monthlyAbsent = summary?['month']?['absent'] ?? 0;
    double dailyPayout = summary?['today']?['totalPayout']?.toDouble() ?? 0.0;
    double monthlyPayout = summary?['month']?['totalPayout']?.toDouble() ?? 0.0;
    double averageDailyWage = attendanceProvider.averageDailyWage;

    final siteData = attendanceProvider.siteDailyAttendance;
    int presentCount = siteData?['presentCount'] ?? 0;
    int absentCount = siteData?['absentCount'] ?? 0;
    List<dynamic> presentWorkers = siteData?['present'] ?? [];
    List<dynamic> absentWorkers = siteData?['absent'] ?? [];

    final constructionSites = siteProvider.sites;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child: attendanceProvider.isLoading
                ? Center(child: CircularProgressIndicator())
                : attendanceProvider.error != null
                ? Center(child: Text(attendanceProvider.error!))
                : SingleChildScrollView(
              padding: EdgeInsets.all(isMediumScreen ? 32 : 16),
              child: Column(
                children: [
                  _buildKPICards(isLargeScreen, todayPresent, todayAbsent, dailyPayout, averageDailyWage),
                  SizedBox(height: 32),
                  _buildMainContent(isLargeScreen, monthlyPresent, monthlyAbsent, averageDailyWage, presentCount, absentCount, presentWorkers, absentWorkers, constructionSites),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(
      bool isLargeScreen,
      int monthlyPresent,
      int monthlyAbsent,
      double averageDailyWage,
      int presentCount,
      int absentCount,
      List<dynamic> presentWorkers,
      List<dynamic> absentWorkers,
      List constructionSites,
      ) {
    if (isLargeScreen) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  SizedBox(
                    height: 350,
                    child: Row(
                      children: [
                        Expanded(child: _buildAttendanceChart('Today\'s Attendance', true)),
                        SizedBox(width: 24),
                        Expanded(child: _buildAttendanceChart('Monthly Attendance', false, monthlyPresent, monthlyAbsent)),
                      ],
                    ),
                  ),
                  // REMOVED WEEKLY TRENDS CHART
                  // SizedBox(height: 24),
                  // SizedBox(
                  //   height: 300,
                  //   child: _buildTrendsChart(),
                  // ),
                ],
              ),
            ),
            SizedBox(width: 32),
            SizedBox(
              width: 380,
              child: Column(
                children: [
                  _buildSiteSelector(constructionSites),
                  SizedBox(height: 24),
                  if (selectedSite != null) ...[
                    _buildSiteQuickStats(presentCount, absentCount),
                    SizedBox(height: 24),
                  ],
                  SizedBox(
                    height: 500,
                    child: selectedSite != null
                        ? _buildWorkersPanel(presentWorkers, absentWorkers, averageDailyWage)
                        : _buildEmptyState(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Column(
        children: [
          SizedBox(
            height: 350,
            child: Row(
              children: [
                Expanded(child: _buildAttendanceChart('Today\'s Attendance', true)),
                SizedBox(width: 16),
                Expanded(child: _buildAttendanceChart('Monthly Attendance', false, monthlyPresent, monthlyAbsent)),
              ],
            ),
          ),
          // REMOVED WEEKLY TRENDS CHART
          // SizedBox(height: 24),
          // SizedBox(
          //   height: 300,
          //   child: _buildTrendsChart(),
          // ),
          SizedBox(height: 32),
          _buildSiteSelector(constructionSites),
          SizedBox(height: 24),
          if (selectedSite != null) ...[
            _buildSiteQuickStats(presentCount, absentCount),
            SizedBox(height: 24),
          ],
          SizedBox(
            height: 500,
            child: selectedSite != null
                ? _buildWorkersPanel(presentWorkers, absentWorkers, averageDailyWage)
                : _buildEmptyState(),
          ),
        ],
      );
    }
  }

  Widget _buildTopHeader() {
    return Container(
      height: 80,
      padding: EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Construction Analytics Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Real-time workforce monitoring and analytics',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 16, color: Color(0xFF64748B)),
                SizedBox(width: 8),
                Text(
                  'August 16, 2025',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(bool isLargeScreen, int todayPresent, int todayAbsent, double dailyPayout, double averageDailyWage) {
    final kpis = [
      {'title': 'Today Present', 'value': '$todayPresent', 'subtitle': 'workers on-site', 'icon': Icons.people, 'color': Color(0xFF059669), 'trend': '+5.2%'},
      {'title': 'Today Absent', 'value': '$todayAbsent', 'subtitle': 'workers absent', 'icon': Icons.person_off, 'color': Color(0xFFDC2626), 'trend': '-2.1%'},
      {'title': 'Daily Payout', 'value': '${(dailyPayout/1000).toStringAsFixed(1)}k', 'subtitle': 'total wages', 'icon': Icons.payments, 'color': Color(0xFF3B82F6), 'trend': '+12.5%'},
      {'title': 'Efficiency', 'value': '${((todayPresent / ((todayPresent + todayAbsent) == 0 ? 1 : (todayPresent + todayAbsent))) * 100).toInt()}%', 'subtitle': 'attendance rate', 'icon': Icons.trending_up, 'color': Color(0xFF7C3AED), 'trend': '+3.8%'},
    ];

    if (isLargeScreen) {
      return Row(
        children: kpis.map((kpi) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: kpis.indexOf(kpi) < kpis.length - 1 ? 24 : 0),
            child: _buildKPICard(kpi),
          ),
        )).toList(),
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildKPICard(kpis[0])),
              SizedBox(width: 16),
              Expanded(child: _buildKPICard(kpis[1])),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildKPICard(kpis[2])),
              SizedBox(width: 16),
              Expanded(child: _buildKPICard(kpis[3])),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildKPICard(Map<String, dynamic> kpi) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (kpi['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  kpi['icon'] as IconData,
                  color: kpi['color'] as Color,
                  size: 24,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (kpi['trend'] as String).startsWith('+') ? Color(0xFFDCFCE7) : Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  kpi['trend'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: (kpi['trend'] as String).startsWith('+') ? Color(0xFF059669) : Color(0xFFDC2626),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text(
            kpi['value'] as String,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 4),
          Text(
            kpi['title'] as String,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            kpi['subtitle'] as String,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart(String title, bool isToday, [int monthlyPresent = 0, int monthlyAbsent = 0]) {
    int present = isToday
        ? Provider.of<AttendanceProvider>(context).ownerDashboardSummary?['today']?['present'] ?? 0
        : monthlyPresent;
    int absent = isToday
        ? Provider.of<AttendanceProvider>(context).ownerDashboardSummary?['today']?['absent'] ?? 0
        : monthlyAbsent;
    int total = present + absent;
    int attendanceRate = ((present / (total == 0 ? 1 : total)) * 100).toInt();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$total total workers',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: attendanceRate >= 85 ? Color(0xFFDCFCE7) : Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$attendanceRate%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: attendanceRate >= 85 ? Color(0xFF059669) : Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = constraints.maxHeight * 0.7;
                return Row(
                  children: [
                    SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: PieChart(
                        PieChartData(
                          sections: [
                            PieChartSectionData(
                              value: present.toDouble(),
                              color: Color(0xFF059669),
                              title: '',
                              radius: chartSize * 0.25,
                            ),
                            PieChartSectionData(
                              value: absent.toDouble(),
                              color: Color.fromARGB(255, 244, 1, 1),
                              title: '',
                              radius: chartSize * 0.25,
                            ),
                          ],
                          centerSpaceRadius: chartSize * 0.15,
                          sectionsSpace: 2,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegend('Present', present, Color(0xFF059669)),
                          SizedBox(height: 8),
                          _buildChartLegend('Absent', absent, Color.fromARGB(255, 255, 0, 0)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, int value, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // REMOVED _buildTrendsChart

  Widget _buildSiteSelector(List constructionSites) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Construction Sites', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Select a site',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2)),
              prefixIcon: Icon(Icons.location_on, color: Color(0xFF64748B)),
              filled: true,
              fillColor: Color(0xFFF8FAFC),
            ),
            value: selectedSite,
            items: constructionSites.map<DropdownMenuItem<String>>((site) {
              final name = site.name ?? '';
              final id = site.id ?? '';
              return DropdownMenuItem(
                value: id,
                child: Text(name, overflow: TextOverflow.ellipsis),
              );
            }).toList(),
            onChanged: (siteId) async {
              setState(() {
                selectedSite = siteId;
              });
              if (siteId != null) {
                final attendanceProvider = Provider.of<AttendanceProvider>(context, listen: false);
                await attendanceProvider.fetchSiteDailyAttendance(siteId);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSiteQuickStats(int presentCount, int absentCount) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            selectedSite ?? '',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Present',
                  '$presentCount',
                  Color(0xFF059669),
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildQuickStat(
                  'Absent',
                  '$absentCount',
                  Color(0xFFDC2626),
                  Icons.cancel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String title, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildWorkersPanel(List<dynamic> presentWorkers, List<dynamic> absentWorkers, double averageDailyWage) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: TabBar(
                labelColor: Color(0xFF3B82F6),
                unselectedLabelColor: Color(0xFF64748B),
                indicator: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                dividerColor: Colors.transparent,
                tabs: [
                  Tab(
                    child: Text(
                      'Present (${presentWorkers.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Tab(
                    child: Text(
                      'Absent (${absentWorkers.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildWorkersList(presentWorkers, Color(0xFF059669), Icons.check_circle, averageDailyWage),
                  _buildWorkersList(absentWorkers, Color(0xFFDC2626), Icons.cancel, averageDailyWage),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersList(List<dynamic> workers, Color color, IconData icon, double averageDailyWage) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: workers.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.person_off,
                color: color,
                size: 32,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'No workers in this category',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: EdgeInsets.only(bottom: 20),
        itemCount: workers.length,
        itemBuilder: (context, index) {
          final worker = workers[index];
          final name = worker is String
              ? worker
              : worker['name'] ?? 'Unknown Worker';
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      name.split(' ').map((name) => name.isNotEmpty ? name[0] : '').join('').toUpperCase(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Daily Wage: ${worker['dailyWage'].toString()}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.location_city,
                size: 40,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Select a Construction Site',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose a site from the dropdown above to view worker details',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}