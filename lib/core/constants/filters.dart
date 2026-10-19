class Filters {
  static final List<FilterOption> typeList = [
    FilterOption(id: 'all', name: 'Semua'),
    FilterOption(id: 'manga', name: 'Manga'),
    FilterOption(id: 'manhwa', name: 'Manhwa'),
    FilterOption(id: 'manhua', name: 'Manhua'),
  ];

  static final List<FilterOption> statusList = [
    FilterOption(id: 'all', name: 'Semua'),
    FilterOption(id: 'ongoing', name: 'Ongoing'),
    FilterOption(id: 'completed', name: 'Completed'),
    FilterOption(id: 'hiatus', name: 'Hiatus'),
  ];

  static final List<FilterOption> sortbyList = [
    FilterOption(id: 'latest', name: 'Terbaru'),
    FilterOption(id: 'rating', name: 'Rating'),
    FilterOption(id: 'newseries', name: 'Seri Baru'),
    FilterOption(id: 'default', name: 'Default'),
  ];

  // Ids from GET /genres.
  static final List<FilterOption> genreList = [
    FilterOption(id: '11', name: '4-Koma'),
    FilterOption(id: '19', name: 'Action'),
    FilterOption(id: '49', name: 'Adult'),
    FilterOption(id: '16', name: 'Adventure'),
    FilterOption(id: '22', name: 'Comedy'),
    FilterOption(id: '7', name: 'Cooking'),
    FilterOption(id: '40', name: 'Demons'),
    FilterOption(id: '29', name: 'Drama'),
    FilterOption(id: '47', name: 'Ecchi'),
    FilterOption(id: '28', name: 'Fantasy'),
    FilterOption(id: '17', name: 'Game'),
    FilterOption(id: '41', name: 'Gender Bender'),
    FilterOption(id: '15', name: 'Gore'),
    FilterOption(id: '34', name: 'Harem'),
    FilterOption(id: '10', name: 'Historical'),
    FilterOption(id: '18', name: 'Horror'),
    FilterOption(id: '6', name: 'Isekai'),
    FilterOption(id: '23', name: 'Josei'),
    FilterOption(id: '35', name: 'Magic'),
    FilterOption(id: '46', name: 'Martial Arts'),
    FilterOption(id: '37', name: 'Mature'),
    FilterOption(id: '20', name: 'Mecha'),
    FilterOption(id: '9', name: 'Medical'),
    FilterOption(id: '36', name: 'Military'),
    FilterOption(id: '44', name: 'Music'),
    FilterOption(id: '39', name: 'Mystery'),
    FilterOption(id: '33', name: 'One-Shot'),
    FilterOption(id: '43', name: 'Police'),
    FilterOption(id: '4', name: 'Psychological'),
    FilterOption(id: '14', name: 'Reincarnation'),
    FilterOption(id: '26', name: 'Romance'),
    FilterOption(id: '42', name: 'School'),
    FilterOption(id: '2', name: 'School Life'),
    FilterOption(id: '32', name: 'Sci-Fi'),
    FilterOption(id: '1', name: 'Seinen'),
    FilterOption(id: '31', name: 'Shoujo'),
    FilterOption(id: '27', name: 'Shoujo Ai'),
    FilterOption(id: '30', name: 'Shounen'),
    FilterOption(id: '25', name: 'Shounen Ai'),
    FilterOption(id: '13', name: 'Slice of Life'),
    FilterOption(id: '12', name: 'Sports'),
    FilterOption(id: '45', name: 'Super Power'),
    FilterOption(id: '24', name: 'Supernatural'),
    FilterOption(id: '5', name: 'Thriller'),
    FilterOption(id: '38', name: 'Tragedy'),
    FilterOption(id: '21', name: 'Vampire'),
    FilterOption(id: '8', name: 'Webtoons'),
    FilterOption(id: '3', name: 'Yuri'),
  ];
}

/// Selectable explore filter value.
class FilterOption {
  const FilterOption({required this.id, required this.name});

  final String id;
  final String name;
}
