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
    FilterModel(id: 'ongoing', name: 'Ongoing'),
    FilterModel(id: 'completed', name: 'Completed'),
    FilterModel(id: 'hiatus', name: 'Hiatus'),
  ];

  static final List<FilterModel> sortbyList = [
    FilterModel(id: 'latest', name: 'Terbaru'),
    FilterModel(id: 'rating', name: 'Rating'),
    FilterModel(id: 'newseries', name: 'Seri Baru'),
    FilterModel(id: 'default', name: 'Default'),
  ];

  // Ids from GET /genres.
  static final List<FilterModel> genreList = [
    FilterModel(id: '11', name: '4-Koma'),
    FilterModel(id: '19', name: 'Action'),
    FilterModel(id: '49', name: 'Adult'),
    FilterModel(id: '16', name: 'Adventure'),
    FilterModel(id: '22', name: 'Comedy'),
    FilterModel(id: '7', name: 'Cooking'),
    FilterModel(id: '40', name: 'Demons'),
    FilterModel(id: '29', name: 'Drama'),
    FilterModel(id: '47', name: 'Ecchi'),
    FilterModel(id: '28', name: 'Fantasy'),
    FilterModel(id: '17', name: 'Game'),
    FilterModel(id: '41', name: 'Gender Bender'),
    FilterModel(id: '15', name: 'Gore'),
    FilterModel(id: '34', name: 'Harem'),
    FilterModel(id: '10', name: 'Historical'),
    FilterModel(id: '18', name: 'Horror'),
    FilterModel(id: '6', name: 'Isekai'),
    FilterModel(id: '23', name: 'Josei'),
    FilterModel(id: '35', name: 'Magic'),
    FilterModel(id: '46', name: 'Martial Arts'),
    FilterModel(id: '37', name: 'Mature'),
    FilterModel(id: '20', name: 'Mecha'),
    FilterModel(id: '9', name: 'Medical'),
    FilterModel(id: '36', name: 'Military'),
    FilterModel(id: '44', name: 'Music'),
    FilterModel(id: '39', name: 'Mystery'),
    FilterModel(id: '33', name: 'One-Shot'),
    FilterModel(id: '43', name: 'Police'),
    FilterModel(id: '4', name: 'Psychological'),
    FilterModel(id: '14', name: 'Reincarnation'),
    FilterModel(id: '26', name: 'Romance'),
    FilterModel(id: '42', name: 'School'),
    FilterModel(id: '2', name: 'School Life'),
    FilterModel(id: '32', name: 'Sci-Fi'),
    FilterModel(id: '1', name: 'Seinen'),
    FilterModel(id: '31', name: 'Shoujo'),
    FilterModel(id: '27', name: 'Shoujo Ai'),
    FilterModel(id: '30', name: 'Shounen'),
    FilterModel(id: '25', name: 'Shounen Ai'),
    FilterModel(id: '13', name: 'Slice of Life'),
    FilterModel(id: '12', name: 'Sports'),
    FilterModel(id: '45', name: 'Super Power'),
    FilterModel(id: '24', name: 'Supernatural'),
    FilterModel(id: '5', name: 'Thriller'),
    FilterModel(id: '38', name: 'Tragedy'),
    FilterModel(id: '21', name: 'Vampire'),
    FilterModel(id: '8', name: 'Webtoons'),
    FilterModel(id: '3', name: 'Yuri'),
  ];
}
