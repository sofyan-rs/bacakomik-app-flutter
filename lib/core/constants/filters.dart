import 'package:bacakomik_app/core/models/filter_model.dart';

class Filters {
  static final List<FilterModel> typeList = [
    FilterModel(id: 'all', name: 'Semua'),
    FilterModel(id: 'manga', name: 'Manga'),
    FilterModel(id: 'manhwa', name: 'Manhwa'),
    FilterModel(id: 'manhua', name: 'Manhua'),
  ];

  static final List<FilterModel> statusList = [
    FilterModel(id: 'all', name: 'Semua'),
    FilterModel(id: 'Ongoing', name: 'Ongoing'),
    FilterModel(id: 'Completed', name: 'Completed'),
  ];

  static final List<FilterModel> sortbyList = [
    FilterModel(id: 'update', name: 'Terbaru'),
    FilterModel(id: 'popular', name: 'Populer'),
    FilterModel(id: 'titleasc', name: 'Judul A-Z'),
    FilterModel(id: 'titledesc', name: 'Judul Z-A'),
  ];

  static final List<FilterModel> genreList = [
    FilterModel(id: 'action', name: 'Action'),
    FilterModel(id: 'adventure', name: 'Adventure'),
    FilterModel(id: 'comedy', name: 'Comedy'),
    FilterModel(id: 'drama', name: 'Drama'),
    FilterModel(id: 'ecchi', name: 'Ecchi'),
    FilterModel(id: 'fantasy', name: 'Fantasy'),
    FilterModel(id: 'harem', name: 'Harem'),
    FilterModel(id: 'historical', name: 'Historical'),
    FilterModel(id: 'horror', name: 'Horror'),
    FilterModel(id: 'isekai', name: 'Isekai'),
    FilterModel(id: 'josei', name: 'Josei'),
    FilterModel(id: 'magic', name: 'Magic'),
    FilterModel(id: 'martial arts', name: 'Martial Arts'),
    FilterModel(id: 'mature', name: 'Mature'),
    FilterModel(id: 'mecha', name: 'Mecha'),
    FilterModel(id: 'mystery', name: 'Mystery'),
    FilterModel(id: 'psychological', name: 'Psychological'),
    FilterModel(id: 'romance', name: 'Romance'),
    FilterModel(id: 'school', name: 'School'),
    FilterModel(id: 'sci-fi', name: 'Sci-Fi'),
    FilterModel(id: 'seinen', name: 'Seinen'),
    FilterModel(id: 'shoujo', name: 'Shoujo'),
    FilterModel(id: 'shoujo ai', name: 'Shoujo Ai'),
    FilterModel(id: 'shounen', name: 'Shounen'),
    FilterModel(id: 'shounen ai', name: 'Shounen Ai'),
    FilterModel(id: 'slice of life', name: 'Slice of Life'),
    FilterModel(id: 'sports', name: 'Sports'),
    FilterModel(id: 'supernatural', name: 'Supernatural'),
    FilterModel(id: 'thriller', name: 'Thriller'),
    FilterModel(id: 'tragedy', name: 'Tragedy'),
    FilterModel(id: 'yaoi', name: 'Yaoi'),
    FilterModel(id: 'yuri', name: 'Yuri'),
  ];
}
