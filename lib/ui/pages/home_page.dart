import 'package:date_picker_timeline/date_picker_timeline.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/task.dart';
import '../widgets/task_tile.dart';
import '/services/notification_services.dart';
import '/controllers/task_controller.dart';

import '../pages/add_task_page.dart';
import '../size_config.dart';
import '../theme.dart';
import '../widgets/button.dart';
import '/services/theme_services.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late NotifyHelper notifyHelper;
  @override
  void initState() {
    super.initState();
    notifyHelper = NotifyHelper();
    notifyHelper.requestIOSPermissions();
    notifyHelper.initializeNotification();
    _taskController.getTasks();
  }

  final TaskController _taskController = Get.put(TaskController());
  DateTime _selectedDate = DateTime.now();
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: context.theme.backgroundColor,
      appBar: _appBar(),
      body: Column(
        children: [
          _addTaskBar(),
          _addDateBar(),
          SizedBox(height: 6),
          _showTasks(),
        ],
      ),
    );
  }

  AppBar _appBar() {
    return AppBar(
      centerTitle: true,
      elevation: 0,
      backgroundColor: context.theme.backgroundColor,
      actions: [
        IconButton(
          onPressed: () {
            NotifyHelper().cancelAllNotification();
            _taskController.deleteAllTasks();
          },
          icon: Icon(Icons.cleaning_services_outlined,
              size: 24, color: Get.isDarkMode ? Colors.white : darkGreyClr),
        ),
        CircleAvatar(
          backgroundImage: AssetImage('images/person.png'),
          radius: 18,
        ),
        SizedBox(width: 20),
      ],
      leading: IconButton(
        onPressed: () {
          ThemeServices().switchTheme();
          // NotifyHelper().displayNotification(
          //   title: 'Theme Changed',
          //   body: 'fdfd',
          // );
          // NotifyHelper().scheduledNotification();
        },
        icon: Icon(
          Get.isDarkMode
              ? Icons.wb_sunny_outlined
              : Icons.nightlight_round_outlined,
          size: 24,
          color: Get.isDarkMode ? Colors.white : darkGreyClr,
        ),
      ),
    );
  }

  _addTaskBar() {
    return Container(
      margin: EdgeInsets.only(left: 20, right: 10, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat.yMMMMd().format(DateTime.now()).toString(),
                style: subHeadingStyle,
              ),
              Text('Today', style: headingStyle),
            ],
          ),
          MyButton(
            label: '+ Add Task',
            onTap: () async {
              await Get.to(() => AddTaskPage());
              _taskController.getTasks();
            },
          ),
        ],
      ),
    );
  }

  _addDateBar() {
    return Container(
      margin: EdgeInsets.only(top: 6, left: 20),
      child: DatePicker(
        DateTime.now(),
        width: 70,
        height: 100,
        selectedTextColor: Colors.white,
        selectionColor: primaryClr,
        initialSelectedDate: DateTime.now(),
        dayTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        dateTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            color: Colors.grey,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        monthTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        onDateChange: (newDate) {
          setState(() {
            _selectedDate = newDate;
          });
        },
      ),
    );
  }

  Future<void> _onRefresh() async {
    _taskController.getTasks();
  }

  _showTasks() {
    return Expanded(
      child: Obx(
        () {
          if (_taskController.taskList.isEmpty) {
            return _noTaskMsg();
          } else {
            return RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView.builder(
                scrollDirection: SizeConfig.orientation == Orientation.landscape
                    ? Axis.horizontal
                    : Axis.vertical,
                itemCount: _taskController.taskList.length,
                itemBuilder: (BuildContext context, int index) {
                  var task = _taskController.taskList[index];

                  if (task.repeat == 'Daily' ||
                      task.date == DateFormat.yMd().format(_selectedDate) ||
                      (task.repeat == 'Weekly' &&
                          _selectedDate
                                      .difference(
                                          DateFormat.yMd().parse(task.date!))
                                      .inDays % 7 == 0) ||
                      (task.repeat == 'Monthly' &&
                          DateFormat.yMd().parse(task.date!).day ==
                              _selectedDate.day)) {
                    var date = DateFormat.jm().parse(task.startTime!);
                    var myTime = DateFormat('HH:mm').format(date);

                    NotifyHelper().scheduledNotification(
                      int.parse(myTime.toString().split(':')[0]),
                      int.parse(myTime.toString().split(':')[1]),
                      task,
                    );
                    return AnimationConfiguration.staggeredList(
                      position: index,
                      duration: Duration(milliseconds: 1000),
                      child: SlideAnimation(
                        horizontalOffset: 300,
                        child: FadeInAnimation(
                          child: GestureDetector(
                            onTap: () {
                              showBottomSheet(
                                context,
                                task,
                              );
                            },
                            child: TaskTile(task),
                          ),
                        ),
                      ),
                    );
                  } else {
                    return Container();
                  }

                  // var hour = task.startTime.toString().split(':')[0];
                  // var minutes = task.startTime.toString().split(':')[1];
                },
              ),
            );
          }
        },
      ),
    );
  }

  _noTaskMsg() {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: Duration(milliseconds: 2000),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: SingleChildScrollView(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                direction: SizeConfig.orientation == Orientation.landscape
                    ? Axis.horizontal
                    : Axis.vertical,
                children: [
                  SizeConfig.orientation == Orientation.landscape
                      ? SizedBox(height: 6)
                      : SizedBox(height: 220),
                  SvgPicture.asset(
                    'images/task.svg',
                    color: primaryClr.withOpacity(0.5),
                    height: 90,
                    semanticsLabel: 'Task',
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 10),
                    child: Text(
                      'You do not tasks yet!\nAdd new tasks to make sure your days productive.',
                      style: subTitleStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizeConfig.orientation == Orientation.landscape
                      ? SizedBox(height: 120)
                      : SizedBox(height: 180),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  showBottomSheet(BuildContext context, Task task) {
    Get.bottomSheet(
      SingleChildScrollView(
        child: Container(
          padding: EdgeInsets.all(4),
          width: SizeConfig.screenWidth,
          height: (SizeConfig.orientation == Orientation.landscape)
              ? (task.isCompleted == 1
                  ? SizeConfig.screenHeight * 0.6
                  : SizeConfig.screenHeight * 0.8)
              : (task.isCompleted == 1
                  ? SizeConfig.screenHeight * 0.30
                  : SizeConfig.screenHeight * 0.39),
          color: Get.isDarkMode ? darkHeaderClr : Colors.white,
          child: Column(
            children: [
              Flexible(
                child: Container(
                  height: 6,
                  width: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Get.isDarkMode ? Colors.grey[600] : Colors.grey[300],
                  ),
                ),
              ),
              SizedBox(height: 20),
              task.isCompleted == 1
                  ? Container()
                  : _buildBottomSheet(
                      lable: 'Task Completed',
                      onTap: () {
                        NotifyHelper().cancelNotification(task);

                        _taskController.markTaskCompleted(task.id!);
                        Get.back();
                      },
                      clr: primaryClr,
                    ),
              _buildBottomSheet(
                lable: 'delete task',
                onTap: () {
                  NotifyHelper().cancelNotification(task);
                  _taskController.deleteTasks(task);
                  Get.back();
                },
                clr: Colors.red[300]!,
              ),
              Divider(color: Get.isDarkMode ? Colors.grey : darkGreyClr),
              _buildBottomSheet(
                lable: 'Cancel',
                onTap: () {
                  Get.back();
                },
                clr: primaryClr,
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  _buildBottomSheet(
      {required String lable,
      required Function() onTap,
      required Color clr,
      bool isClose = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        height: 65,
        width: SizeConfig.screenWidth * 0.9,
        decoration: BoxDecoration(
          border: Border.all(
            width: 2,
            color: isClose
                ? Get.isDarkMode
                    ? Colors.grey[600]!
                    : Colors.grey[300]!
                : clr,
          ),
          borderRadius: BorderRadius.circular(20),
          color: isClose ? Colors.transparent : clr,
        ),
        child: Center(
          child: Text(lable,
              style: isClose
                  ? titleStyle
                  : titleStyle.copyWith(color: Colors.white)),
        ),
      ),
    );
  }
}
