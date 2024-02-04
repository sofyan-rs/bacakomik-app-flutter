import 'package:bacakomik_app/core/bloc/history_cubit/history_cubit.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/presentation/screens/sub/comic_details/comic_details_screen.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';
import 'package:solar_icons/solar_icons.dart';

class HistoryComicCard extends StatefulWidget {
  const HistoryComicCard({
    Key? key,
    required this.title,
    required this.cover,
    required this.slug,
    required this.chapter,
    required this.chapterSlug,
    required this.readDate,
  }) : super(key: key);

  final String title;
  final String cover;
  final String slug;
  final String chapter;
  final String chapterSlug;
  final DateTime readDate;

  @override
  State<HistoryComicCard> createState() => _HistoryComicCardState();
}

class _HistoryComicCardState extends State<HistoryComicCard> {
  void _goToComicDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ComicDetailsScreen(
          slug: widget.slug,
          title: widget.title,
          cover: widget.cover,
        ),
      ),
    );
  }

  void _clearHistory() {
    bool isClearHistoryInComicSlug = false;

    showModalBottomSheet(
      useSafeArea: true,
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
          return SizedBox(
            height: 260,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 15, left: 15, right: 15),
                      child: Text(
                        AppText.clearHistoryComicConfirmation,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      title: Row(
                        children: [
                          Checkbox(
                            checkColor: Colors.white,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(3),
                            ),
                            value: isClearHistoryInComicSlug,
                            onChanged: (value) {
                              setState(() {
                                isClearHistoryInComicSlug = value!;
                              });
                            },
                          ),
                          const Text(
                            AppText.clearHistoryAllChapter,
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          isClearHistoryInComicSlug =
                              !isClearHistoryInComicSlug;
                        });
                      },
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.only(
                          left: 15, right: 15, bottom: 15),
                      child: Row(
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
                              if (isClearHistoryInComicSlug) {
                                context
                                    .read<HistoryCubit>()
                                    .removeHistoryBySlug(widget.slug);
                              } else {
                                context
                                    .read<HistoryCubit>()
                                    .removeHistory(widget.chapterSlug);
                              }
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
                    ),
                  ],
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Slidable(
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.3,
          children: [
            const SizedBox(width: 10),
            SlidableAction(
              onPressed: (context) {
                _clearHistory();
              },
              icon: SolarIconsOutline.trashBinMinimalistic,
              foregroundColor: Colors.white,
              backgroundColor: AppColors.error,
              label: AppText.delete,
              borderRadius: const BorderRadius.all(Radius.circular(5)),
            ),
          ],
        ),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .secondaryContainer
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Theme.of(context).primaryColor.withOpacity(0.5),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: CachedNetworkImage(
                        fit: BoxFit.cover,
                        imageUrl: widget.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CustomChip(
                                text: 'Ch. ${widget.chapter}',
                                backgroundColor: AppColors.primary,
                              ),
                              CustomChip(
                                text:
                                    '${widget.readDate.day}/${widget.readDate.month}/${widget.readDate.year}',
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                textColor: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer,
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      _goToComicDetails(context);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
