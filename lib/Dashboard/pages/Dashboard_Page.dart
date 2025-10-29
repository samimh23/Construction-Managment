import 'package:constructionproject/Manger/manager_provider/atendence_provider.dart';
import 'package:constructionproject/Construction/Provider/ConstructionSite/Provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  String? selectedSite;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final attendanceProvider = Provider.of<AttendanceProvider>(
        context,
        listen: false,
      );
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
      backgroundColor: Color(0xFFF1F5F9),
      body: Column(
        children: [
          _buildTopHeader(),
          Expanded(
            child:
                attendanceProvider.isLoading
                    ? Center(child: CircularProgressIndicator())
                    : attendanceProvider.error != null
                    ? Center(child: Text(attendanceProvider.error!))
                    : SingleChildScrollView(
                      padding: EdgeInsets.all(isMediumScreen ? 24 : 16),
                      child: Column(
                        children: [
                          // Site Selector at the top for better UX
                          _buildSiteSelector(constructionSites),
                          SizedBox(height: 20),

                          // Compact KPI Cards
                          _buildKPICards(
                            isLargeScreen,
                            isMediumScreen,
                            todayPresent,
                            todayAbsent,
                            dailyPayout,
                            averageDailyWage,
                          ),
                          SizedBox(height: 24),

                          _buildMainContent(
                            isLargeScreen,
                            isMediumScreen,
                            monthlyPresent,
                            monthlyAbsent,
                            averageDailyWage,
                            presentCount,
                            absentCount,
                            presentWorkers,
                            absentWorkers,
                            constructionSites,
                          ),
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
    bool isMediumScreen,
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
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Charts section
          Expanded(
            flex: 3,
            child: Column(
              children: [
                SizedBox(
                  height: 350,
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildAttendanceChart(
                          'Today\'s Attendance',
                          true,
                        ),
                      ),
                      SizedBox(width: 20),
                      Expanded(
                        child: _buildAttendanceChart(
                          'Monthly Attendance',
                          false,
                          monthlyPresent,
                          monthlyAbsent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 24),

          // Side panel
          SizedBox(
            width: 350,
            child: Column(
              children: [
                if (selectedSite != null) ...[
                  _buildSiteQuickStats(presentCount, absentCount),
                  SizedBox(height: 20),
                ],
                SizedBox(
                  height: selectedSite != null ? 450 : 350,
                  child:
                      selectedSite != null
                          ? _buildWorkersPanel(
                            presentWorkers,
                            absentWorkers,
                            averageDailyWage,
                          )
                          : _buildEmptyState(),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Column(
        children: [
          // Attendance charts
          SizedBox(
            height: isMediumScreen ? 300 : 280,
            child:
                isMediumScreen
                    ? Row(
                      children: [
                        Expanded(
                          child: _buildAttendanceChart(
                            'Today\'s Attendance',
                            true,
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          child: _buildAttendanceChart(
                            'Monthly Attendance',
                            false,
                            monthlyPresent,
                            monthlyAbsent,
                          ),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        Expanded(
                          child: _buildAttendanceChart(
                            'Today\'s Attendance',
                            true,
                          ),
                        ),
                        SizedBox(height: 12),
                        Expanded(
                          child: _buildAttendanceChart(
                            'Monthly Attendance',
                            false,
                            monthlyPresent,
                            monthlyAbsent,
                          ),
                        ),
                      ],
                    ),
          ),
          SizedBox(height: 20),

          if (selectedSite != null) ...[
            _buildSiteQuickStats(presentCount, absentCount),
            SizedBox(height: 20),
          ],

          SizedBox(
            height: 450,
            child:
                selectedSite != null
                    ? _buildWorkersPanel(
                      presentWorkers,
                      absentWorkers,
                      averageDailyWage,
                    )
                    : _buildEmptyState(),
          ),
        ],
      );
    }
  }

  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF3B82F6).withOpacity(0.2),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.dashboard_rounded, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Construction Dashboard',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  'Real-time workforce monitoring & analytics',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  getFormattedDate(),
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String getFormattedDate() {
    final now = DateTime.now();
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    String month = months[now.month - 1];
    return '$month ${now.day}, ${now.year}';
  }

  Widget _buildSiteSelector(List constructionSites) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3B82F6).withOpacity(0.15),
                      Color(0xFF3B82F6).withOpacity(0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFF3B82F6),
                  size: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Construction Site',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Select a site to view details',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              hintText: 'Choose a construction site...',
              hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              prefixIcon: Icon(
                Icons.search,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(0xFF3B82F6), width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            value: selectedSite,
            items:
                constructionSites.map<DropdownMenuItem<String>>((site) {
                  final name = site.name ?? '';
                  final id = site.id ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text(
                      name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1E293B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
            onChanged: (siteId) async {
              setState(() {
                selectedSite = siteId;
              });
              if (siteId != null) {
                final attendanceProvider = Provider.of<AttendanceProvider>(
                  context,
                  listen: false,
                );
                await attendanceProvider.fetchSiteDailyAttendance(siteId);
                setState(() {});
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKPICards(
    bool isLargeScreen,
    bool isMediumScreen,
    int todayPresent,
    int todayAbsent,
    double dailyPayout,
    double averageDailyWage,
  ) {
    final attendanceProvider = Provider.of<AttendanceProvider>(context);

    // Previous day's data for trend calculations
    int prevPresent =
        attendanceProvider.ownerDashboardSummary?['yesterday']?['present'] ?? 0;
    int prevAbsent =
        attendanceProvider.ownerDashboardSummary?['yesterday']?['absent'] ?? 0;
    double prevPayout =
        attendanceProvider.ownerDashboardSummary?['yesterday']?['totalPayout']
            ?.toDouble() ??
        0.0;

    // Calculate trends
    double presentDiff = (todayPresent - prevPresent) as double;
    double presentTrendPercent =
        prevPresent == 0 ? 0 : (presentDiff / prevPresent) * 100;
    String todayPresentTrend =
        (presentTrendPercent >= 0 ? '+' : '') +
        presentTrendPercent.toStringAsFixed(1) +
        '%';

    double absentDiff = (todayAbsent - prevAbsent) as double;
    double absentTrendPercent =
        prevAbsent == 0 ? 0 : (absentDiff / prevAbsent) * 100;
    String todayAbsentTrend =
        (absentTrendPercent >= 0 ? '+' : '') +
        absentTrendPercent.toStringAsFixed(1) +
        '%';

    double payoutDiff = dailyPayout - prevPayout;
    double payoutTrendPercent =
        prevPayout == 0 ? 0 : (payoutDiff / prevPayout) * 100;
    String dailyPayoutTrend =
        (payoutTrendPercent >= 0 ? '+' : '') +
        payoutTrendPercent.toStringAsFixed(1) +
        '%';

    int prevTotal = prevPresent + prevAbsent;
    int todayTotal = todayPresent + todayAbsent;
    double prevEfficiency =
        prevTotal == 0 ? 0 : (prevPresent / prevTotal) * 100;
    double todayEfficiency =
        todayTotal == 0 ? 0 : (todayPresent / todayTotal) * 100;
    double efficiencyChange = todayEfficiency - prevEfficiency;
    String efficiencyTrend =
        (efficiencyChange >= 0 ? '+' : '') +
        efficiencyChange.toStringAsFixed(1) +
        '%';

    final kpis = [
      {
        'title': 'Present',
        'value': '$todayPresent',
        'subtitle': 'workers',
        'icon': Icons.people,
        'color': Color(0xFF059669),
        'trend': todayPresentTrend,
      },
      {
        'title': 'Absent',
        'value': '$todayAbsent',
        'subtitle': 'workers',
        'icon': Icons.person_off,
        'color': Color(0xFFDC2626),
        'trend': todayAbsentTrend,
      },
      {
        'title': 'Payout',
        'value': '${(dailyPayout / 1000).toStringAsFixed(1)}k',
        'subtitle': 'today',
        'icon': Icons.payments,
        'color': Color(0xFF3B82F6),
        'trend': dailyPayoutTrend,
      },
      {
        'title': 'Rate',
        'value': '${todayEfficiency.toInt()}%',
        'subtitle': 'attendance',
        'icon': Icons.trending_up,
        'color': Color(0xFF7C3AED),
        'trend': efficiencyTrend,
      },
    ];

    if (isLargeScreen || isMediumScreen) {
      return Row(
        children:
            kpis
                .map(
                  (kpi) => Expanded(
                    child: Container(
                      margin: EdgeInsets.only(
                        right: kpis.indexOf(kpi) < kpis.length - 1 ? 16 : 0,
                      ),
                      child: _buildCompactKPICard(kpi),
                    ),
                  ),
                )
                .toList(),
      );
    } else {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildCompactKPICard(kpis[0])),
              SizedBox(width: 12),
              Expanded(child: _buildCompactKPICard(kpis[1])),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildCompactKPICard(kpis[2])),
              SizedBox(width: 12),
              Expanded(child: _buildCompactKPICard(kpis[3])),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildCompactKPICard(Map<String, dynamic> kpi) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.9 + (value * 0.1),
          child: Opacity(
            opacity: value,
            child: Container(
              padding: EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white,
                    (kpi['color'] as Color).withOpacity(0.03),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (kpi['color'] as Color).withOpacity(0.2),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (kpi['color'] as Color).withOpacity(0.08),
                    blurRadius: 12,
                    offset: Offset(0, 4),
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
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              (kpi['color'] as Color).withOpacity(0.15),
                              (kpi['color'] as Color).withOpacity(0.08),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (kpi['color'] as Color).withOpacity(0.2),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          kpi['icon'] as IconData,
                          color: kpi['color'] as Color,
                          size: 22,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                (kpi['trend'] as String).startsWith('+')
                                    ? [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]
                                    : [Color(0xFFFEE2E2), Color(0xFFFECACA)],
                          ),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: ((kpi['trend'] as String).startsWith('+')
                                      ? Color(0xFF059669)
                                      : Color(0xFFDC2626))
                                  .withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (kpi['trend'] as String).startsWith('+')
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 12,
                              color:
                                  (kpi['trend'] as String).startsWith('+')
                                      ? Color(0xFF059669)
                                      : Color(0xFFDC2626),
                            ),
                            SizedBox(width: 4),
                            Text(
                              kpi['trend'] as String,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color:
                                    (kpi['trend'] as String).startsWith('+')
                                        ? Color(0xFF059669)
                                        : Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 1200),
                    tween: Tween(begin: 0.0, end: 1.0),
                    curve: Curves.easeOutCubic,
                    builder: (context, animValue, child) {
                      final displayValue = kpi['value'] as String;
                      return Text(
                        displayValue,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.5,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 6),
                  Text(
                    kpi['title'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF475569),
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    kpi['subtitle'] as String,
                    style: TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttendanceChart(
    String title,
    bool isToday, [
    int monthlyPresent = 0,
    int monthlyAbsent = 0,
  ]) {
    int present =
        isToday
            ? Provider.of<AttendanceProvider>(
                  context,
                ).ownerDashboardSummary?['today']?['present'] ??
                0
            : monthlyPresent;
    int absent =
        isToday
            ? Provider.of<AttendanceProvider>(
                  context,
                ).ownerDashboardSummary?['today']?['absent'] ??
                0
            : monthlyAbsent;
    int total = present + absent;
    int attendanceRate = ((present / (total == 0 ? 1 : total)) * 100).toInt();

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFAFAFA)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3B82F6).withOpacity(0.1),
                      Color(0xFF3B82F6).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isToday ? Icons.today_rounded : Icons.calendar_month_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                        letterSpacing: 0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      '$total total workers',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors:
                        attendanceRate >= 85
                            ? [Color(0xFFDCFCE7), Color(0xFFBBF7D0)]
                            : [Color(0xFFFEF3C7), Color(0xFFFDE68A)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (attendanceRate >= 85
                              ? Color(0xFF059669)
                              : Color(0xFFD97706))
                          .withOpacity(0.2),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      attendanceRate >= 85
                          ? Icons.check_circle
                          : Icons.warning_rounded,
                      size: 14,
                      color:
                          attendanceRate >= 85
                              ? Color(0xFF059669)
                              : Color(0xFFD97706),
                    ),
                    SizedBox(width: 4),
                    Text(
                      '$attendanceRate%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color:
                            attendanceRate >= 85
                                ? Color(0xFF059669)
                                : Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final chartSize = constraints.maxHeight * 0.75;
                return Row(
                  children: [
                    SizedBox(
                      width: chartSize,
                      height: chartSize,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          PieChart(
                            PieChartData(
                              sections: [
                                PieChartSectionData(
                                  value: present.toDouble(),
                                  color: Color(0xFF059669),
                                  title: '',
                                  radius: chartSize * 0.28,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF059669),
                                      Color(0xFF10B981),
                                    ],
                                  ),
                                ),
                                PieChartSectionData(
                                  value: absent.toDouble(),
                                  color: Color(0xFFEF4444),
                                  title: '',
                                  radius: chartSize * 0.28,
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFFEF4444),
                                      Color(0xFFDC2626),
                                    ],
                                  ),
                                ),
                              ],
                              centerSpaceRadius: chartSize * 0.18,
                              sectionsSpace: 3,
                            ),
                          ),
                          Container(
                            width: chartSize * 0.36,
                            height: chartSize * 0.36,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x10000000),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '$total',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  'Total',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildChartLegend(
                            'Present',
                            present,
                            Color(0xFF059669),
                          ),
                          SizedBox(height: 12),
                          _buildChartLegend(
                            'Absent',
                            absent,
                            Color(0xFFEF4444),
                          ),
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
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color, color.withOpacity(0.7)]),
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
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

  Widget _buildSiteQuickStats(int presentCount, int absentCount) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Site Overview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 12),
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
              SizedBox(width: 12),
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

  Widget _buildQuickStat(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Text(title, style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  Widget _buildWorkersPanel(
    List<dynamic> presentWorkers,
    List<dynamic> absentWorkers,
    double averageDailyWage,
  ) {
    return DefaultTabController(
      length: 2,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16),
              child: TabBar(
                labelColor: Color(0xFF3B82F6),
                unselectedLabelColor: Color(0xFF64748B),
                indicator: BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                dividerColor: Colors.transparent,
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(text: 'Present (${presentWorkers.length})'),
                  Tab(text: 'Absent (${absentWorkers.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildWorkersList(
                    presentWorkers,
                    Color(0xFF059669),
                    Icons.check_circle,
                    averageDailyWage,
                  ),
                  _buildWorkersList(
                    absentWorkers,
                    Color(0xFFDC2626),
                    Icons.cancel,
                    averageDailyWage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkersList(
    List<dynamic> workers,
    Color color,
    IconData icon,
    double averageDailyWage,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child:
          workers.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Icon(Icons.person_off, color: color, size: 24),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No workers in this category',
                      style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.only(bottom: 16),
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  final name =
                      worker is String
                          ? worker
                          : worker['name'] ?? 'Unknown Worker';
                  return Container(
                    margin: EdgeInsets.only(bottom: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              name
                                  .split(' ')
                                  .map((name) => name.isNotEmpty ? name[0] : '')
                                  .join('')
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Wage: ${worker['dailyWage']?.toString() ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Icon(icon, color: color, size: 16),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Icon(
                Icons.location_city,
                size: 32,
                color: Color(0xFF64748B),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Select a Site Above',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Choose a construction site to view worker attendance details',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.4,
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
