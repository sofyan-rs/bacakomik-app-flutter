import 'package:flutter/material.dart';

import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:bacakomik_app/core/constants/texts.dart';
import 'package:bacakomik_app/core/models/comic_details_model/comic_details_model.dart';
import 'package:bacakomik_app/presentation/widgets/chip/custom_chip.dart';

class ComicDetails extends StatefulWidget {
  const ComicDetails({
    Key? key,
    required this.altTitle,
    required this.releaseYear,
    required this.synopsis,
    required this.genres,
  }) : super(key: key);

  final String altTitle;
  final String releaseYear;
  final String synopsis;
  final List<GenreModel> genres;

  @override
  State<ComicDetails> createState() => _ComicDetailsState();
}

class _ComicDetailsState extends State<ComicDetails> {
  int synopsisMaxLines = 3;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.altTitle.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppText.altTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.altTitle,
                  style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context)
                        .colorScheme
                        .onBackground
                        .withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                AppText.releaseYear,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                widget.releaseYear,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              // color: Theme.of(context).colorScheme.onBackground.withOpacity(0.1),
              // borderRadius: BorderRadius.circular(5),
              border: Border.symmetric(
                horizontal: BorderSide(
                  width: 2,
                  color: Theme.of(context)
                      .colorScheme
                      .onBackground
                      .withOpacity(0.1),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.synopsis.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        AppText.synopsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        widget.synopsis,
                        maxLines: widget.synopsis.length > 120
                            ? synopsisMaxLines
                            : 1000,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.5),
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (widget.synopsis.length > 120)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              if (synopsisMaxLines == 3) {
                                synopsisMaxLines = 1000;
                              } else {
                                synopsisMaxLines = 3;
                              }
                            });
                          },
                          child: Text(
                            synopsisMaxLines == 3
                                ? AppText.seeMore
                                : AppText.hide,
                            style: TextStyle(
                              fontSize: 16,
                              color: AppColors.primary.withOpacity(0.8),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],
                  ),
                Flex(
                  direction: Axis.horizontal,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: widget.genres
                            .map(
                              (genre) => CustomChip(
                                text: genre.name,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer
                                    .withOpacity(0.3),
                                textColor: Theme.of(context)
                                    .colorScheme
                                    .onSecondaryContainer
                                    .withOpacity(0.5),
                                textSize: 14,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                            )
                            .toList(),
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
  }
}
