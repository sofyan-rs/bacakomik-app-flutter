import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/history_model.dart';
import 'package:bacakomik_app/presentation/screens/sub/history/widgets/history_comic_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solar_icons/solar_icons.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  void _clearAllHistories() {
    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return SizedBox(
          height: 200,
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                ),
                child: const Text(
                  AppText.clearHistory,
                  style: TextStyle(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  children: [
                    const Text(
                      AppText.clearHistoryDescription,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text(
                            AppText.cancel,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton(
                          onPressed: () {
                            context.read<HistoryCubit>().clearHistory();
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text(
                            AppText.delete,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Row(
          children: [
            Icon(
              SolarIconsBold.history,
              color: AppColors.primary,
            ),
            SizedBox(width: 10),
            Text(AppText.history),
          ],
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(
            SolarIconsOutline.arrowLeft,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              onPressed: _clearAllHistories,
              icon: const Icon(
                SolarIconsOutline.trashBinMinimalistic,
                color: Colors.white,
                size: 23,
              ),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
                padding: const EdgeInsets.all(12),
              ),
            ),
          ),
        ],
      ),
      body: BlocBuilder<HistoryCubit, List<HistoryModel>>(
        builder: (context, state) {
          final histories = state;
          final latestHistory = context.watch<HistoryCubit>().latestHistories;

          if (histories.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    SolarIconsOutline.history,
                    color: AppColors.primary.withOpacity(0.5),
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppText.historyEmpty,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context)
                          .colorScheme
                          .onBackground
                          .withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              final history = latestHistory[index];
              return HistoryComicCard(
                title: history.comicDetails.title,
                cover: history.comicDetails.coverImg,
                slug: history.comicSlug,
                chapter: history.latestHistory.chapterNumber,
                chapterSlug: history.latestHistory.slug,
                readDate: history.latestHistory.readDate,
              );
            },
            itemCount: latestHistory.length,
          );
        },
      ),
    );
  }
}
