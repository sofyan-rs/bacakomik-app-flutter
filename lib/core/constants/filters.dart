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
    FilterOption(id: 'cancelled', name: 'Cancelled'),
  ];

  // `sort` enum of GET /series (see /openapi.json). Unknown values are
  // rejected with 400.
  static final List<FilterOption> sortbyList = [
    FilterOption(id: 'latest', name: 'Terbaru'),
    FilterOption(id: 'newseries', name: 'Seri Baru'),
    FilterOption(id: 'popular', name: 'Populer'),
    FilterOption(id: 'az', name: 'A–Z'),
    FilterOption(id: 'za', name: 'Z–A'),
  ];

  // Snapshot of GET /genres, shown until the live list loads on app start
  // (see GenresCubit) and kept when that fetch fails.
  static final List<FilterOption> genreList = [
    FilterOption(id: '19', name: 'Action'),
    FilterOption(id: '49', name: 'Adult'),
    FilterOption(id: '16', name: 'Adventure'),
    FilterOption(id: '22', name: 'Comedy'),
    FilterOption(id: '50', name: 'Crime'),
    FilterOption(id: '40', name: 'Demons'),
    FilterOption(id: '51', name: 'Doujinshi'),
    FilterOption(id: '29', name: 'Drama'),
    FilterOption(id: '47', name: 'Ecchi'),
    FilterOption(id: '28', name: 'Fantasy'),
    FilterOption(id: '17', name: 'Game'),
    FilterOption(id: '41', name: 'Gender Bender'),
    FilterOption(id: '52', name: 'Genderswap'),
    FilterOption(id: '53', name: "Girls' Love"),
    FilterOption(id: '34', name: 'Harem'),
    FilterOption(id: '10', name: 'Historical'),
    FilterOption(id: '18', name: 'Horror'),
    FilterOption(id: '6', name: 'Isekai'),
    FilterOption(id: '23', name: 'Josei'),
    FilterOption(id: '35', name: 'Magic'),
    FilterOption(id: '54', name: 'Magical Girls'),
    FilterOption(id: '46', name: 'Martial Arts'),
    FilterOption(id: '37', name: 'Mature'),
    FilterOption(id: '20', name: 'Mecha'),
    FilterOption(id: '9', name: 'Medical'),
    FilterOption(id: '36', name: 'Military'),
    FilterOption(id: '55', name: 'Monster Girls'),
    FilterOption(id: '56', name: 'Monsters'),
    FilterOption(id: '44', name: 'Music'),
    FilterOption(id: '39', name: 'Mystery'),
    FilterOption(id: '57', name: 'Ninja'),
    FilterOption(id: '58', name: 'Philosophical'),
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
    FilterOption(id: '59', name: 'Smut'),
    FilterOption(id: '12', name: 'Sports'),
    FilterOption(id: '60', name: 'Superhero'),
    FilterOption(id: '24', name: 'Supernatural'),
    FilterOption(id: '5', name: 'Thriller'),
    FilterOption(id: '38', name: 'Tragedy'),
    FilterOption(id: '61', name: 'Wuxia'),
    FilterOption(id: '62', name: 'Yaoi'),
    FilterOption(id: '3', name: 'Yuri'),
  ];
}

/// Selectable explore filter value.
class FilterOption {
  const FilterOption({required this.id, required this.name});

  final String id;
  final String name;
}
