import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class FirstAidDetailScreen extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<String> steps;
  final List<String> warnings;

  const FirstAidDetailScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.steps,
    required this.warnings,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: TextStyle(fontSize: 18.sp)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: EdgeInsets.all(32.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 60.r,
                      color: color,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20.r),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step-by-Step Instructions',
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ...steps.asMap().entries.map((entry) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32.r,
                            height: 32.r,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 4.h),
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: Colors.red[200]!,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Colors.red[700],
                              size: 24.r,
                            ),
                            SizedBox(width: 12.w),
                            Text(
                              'Important Warnings',
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[700],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16.h),
                        ...warnings.map((warning) => Padding(
                              padding: EdgeInsets.only(bottom: 12.h),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.arrow_right,
                                    color: Colors.red[700],
                                    size: 24.r,
                                  ),
                                  SizedBox(width: 8.w),
                                  Expanded(
                                    child: Text(
                                      warning,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Colors.red[900],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                  Container(
                    padding: EdgeInsets.all(20.r),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue[700],
                          size: 28.r,
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'This is emergency first aid only. Always contact a veterinarian as soon as possible.',
                            style: TextStyle(
                              color: Colors.blue[900],
                              fontSize: 13.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}