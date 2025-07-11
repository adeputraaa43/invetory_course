// Tetap sama
import 'package:d_chart/d_chart.dart';
import 'package:d_view/d_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:inventory_course/presentation/page/inout/inout_history_page.dart';
import '../../../config/app_color.dart';
import '../../../config/app_format.dart';
import '../../../data/model/history.dart';
import '../history/detail_history_page.dart';
import 'add_inout_page.dart';
import '../../controller/c_in_out.dart';
import '../../controller/c_user.dart';

class InOutPage extends StatefulWidget {
  const InOutPage({Key? key, required this.type}) : super(key: key);
  final String type; // "IN" atau "OUT"

  @override
  State<InOutPage> createState() => _InOutPageState();
}

class _InOutPageState extends State<InOutPage> {
  final cInOut = Get.put(CInOut());
  final cuser = Get.put(CUser());

  static const _domainToday = 'Hari Ini';
  static const _domainYesterday = 'Kemarin';
  static const _domainZero = 'Nol';

  @override
  void initState() {
    cInOut.getAnalysis(widget.type);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorToday = widget.type == 'IN'
        ? (isDark ? Colors.lightGreenAccent : Colors.green.shade700)
        : (isDark ? Colors.redAccent.shade100 : Colors.red.shade700);
    final colorYesterday = isDark ? Colors.deepPurpleAccent : Colors.deepPurple;
    final String typeTitle =
        widget.type == 'IN' ? 'Barang Masuk' : 'Barang Keluar';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Text(typeTitle),
        actions: cuser.data.level == 'Admin'
            ? [
                IconButton(
                  onPressed: () {
                    Get.to(() => AddInOutPage(type: widget.type))
                        ?.then((value) {
                      if (value ?? false) {
                        cInOut.getAnalysis(widget.type);
                      }
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ]
            : null,
      ),
      body: ListView(
        children: [
          // PIE CHART
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    return AspectRatio(
                      aspectRatio: 1,
                      child: Stack(
                        children: [
                          DChartPie(
                            data: [
                              {
                                'domain': _domainYesterday,
                                'measure': cInOut.listTotal[5]
                              },
                              {
                                'domain': _domainToday,
                                'measure': cInOut.listTotal[6]
                              },
                              if (cInOut.listTotal[6] == 0 &&
                                  cInOut.listTotal[5] == 0)
                                {'domain': _domainZero, 'measure': 1},
                            ],
                            fillColor: (pieData, index) {
                              switch (pieData['domain']) {
                                case _domainToday:
                                  return colorToday;
                                case _domainYesterday:
                                  return colorYesterday;
                                default:
                                  return Colors.grey.shade300;
                              }
                            },
                            labelColor: Colors.transparent,
                            donutWidth: 20,
                          ),
                          Center(
                            child: Obx(() {
                              return Text(
                                '${cInOut.percentToday.toStringAsFixed(1)}%',
                                style: Theme.of(context).textTheme.headline4,
                              );
                            }),
                          ),
                        ],
                      ),
                    );
                  }),
                  DView.spaceWidth(40),

                  // LEGEND
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DView.spaceHeight(20),
                        Row(
                          children: [
                            Container(height: 20, width: 20, color: colorToday),
                            DView.spaceWidth(8),
                            Text(_domainToday,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        DView.spaceHeight(),
                        Row(
                          children: [
                            Container(
                                height: 20, width: 20, color: colorYesterday),
                            DView.spaceWidth(8),
                            Text(_domainYesterday,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .copyWith(fontWeight: FontWeight.bold)),
                          ],
                        ),
                        DView.spaceHeight(30),
                        Obx(() {
                          String percent =
                              cInOut.percentDifferent.toStringAsFixed(1);
                          return Text(
                            '$percent% ${cInOut.textDifferent}\ndari kemarin\natau sama dengan',
                            maxLines: 5,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium!
                                .copyWith(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w300,
                                ),
                          );
                        }),
                        DView.spaceHeight(8),
                        Obx(() {
                          return Text(
                            'Rp ${AppFormat.currency(cInOut.different.toString())}',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium!
                                .copyWith(
                                  color: colorToday,
                                  fontWeight: FontWeight.bold,
                                ),
                          );
                        }),
                      ],
                    ),
                  ),
                  DView.spaceWidth(16),
                ],
              ),
            ),
          ),

          // BAR CHART
          GetBuilder<CInOut>(builder: (_) {
            return AspectRatio(
              aspectRatio: 16 / 9,
              child: DChartBar(
                data: [
                  {
                    'id': 'Bar',
                    'data': List.generate(cInOut.listTotal.length, (index) {
                      return {
                        'domain': cInOut.week()[index],
                        'measure': cInOut.listTotal[index],
                      };
                    }),
                  },
                ],
                showDomainLine: false,
                showMeasureLine: false,
                showBarValue: false,
                barColor: (barData, index, id) => colorToday,
                measureLabelColor: isDark ? Colors.white : Colors.black54,
                domainLabelColor: isDark ? Colors.white : Colors.black87,
                axisLineColor: Colors.transparent,
              ),
            );
          }),

          // TOTAL CARD
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Obx(() {
              double total =
                  widget.type == 'IN' ? cInOut.totalMasuk : cInOut.totalKeluar;
              return Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(top: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.type == 'IN' ? Icons.download : Icons.upload,
                      color:
                          widget.type == 'IN' ? Colors.green : Colors.redAccent,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total $typeTitle:',
                      style: Theme.of(context).textTheme.titleMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const Spacer(),
                    Text(
                      'Rp ${AppFormat.currency(total.toString())}',
                      style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: colorToday,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              );
            }),
          ),

          DView.spaceHeight(16),

          // HEADER RIWAYAT
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                DView.textTitle(
                  'Riwayat $typeTitle',
                  color: isDark ? Colors.white : Colors.black,
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    Get.to(() => InOutHistoryPage(type: widget.type));
                  },
                  child: Row(
                    children: const [
                      Text(
                        'Lihat Semua',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(Icons.navigate_next, color: AppColor.primary),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // LIST RIWAYAT
          GetBuilder<CInOut>(builder: (_) {
            if (cInOut.list.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text(
                    'Tidak ada data',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return ListView.separated(
              itemCount: cInOut.list.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Colors.white54,
                indent: 16,
                endIndent: 16,
              ),
              itemBuilder: (context, index) {
                History history = cInOut.list[index];
                return ListTile(
                  onTap: () {
                    Get.to(() => DetailHistoryPage(
                        idHistory: '${history.idHistory}'))?.then((value) {
                      if (value ?? false) {
                        cInOut.getAnalysis(widget.type);
                      }
                    });
                  },
                  leading: widget.type == 'IN'
                      ? const Icon(Icons.south_west, color: Colors.green)
                      : const Icon(Icons.north_east, color: Colors.red),
                  horizontalTitleGap: 0,
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppFormat.date(history.createdAt!),
                        style: Theme.of(context).textTheme.subtitle2,
                      ),
                      Text(
                        'Rp ${AppFormat.currency(history.totalPrice ?? '0')}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}
