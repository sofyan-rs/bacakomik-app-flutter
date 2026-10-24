class AppText {
  /// `1 comic`, `3 comics`.
  static String count(int n, String one, String many) =>
      '$n ${n == 1 ? one : many}';

  // Hi Text
  static const String goodMorning = 'Good morning';
  static const String goodAfternoon = 'Good afternoon';
  static const String goodEvening = 'Good evening';
  static const String goodNight = 'Good night';

  // Navigation Bar Text
  static const String home = 'Home';
  static const String explore = 'Explore';
  static const String bookmark = 'Bookmarks';
  static const String more = 'More';
  static const String historyTab = 'History';

  // Home Screen Text
  static const String newSeries = 'New series';
  static const String latest = 'Latest chapters';
  static const String seeAll = 'See all';
  static const String continueReading = 'Continue reading';
  static const String retry = 'Try again';

  // Error Text
  static const String error = 'Something went wrong';

  // Comic Details Screen Text
  static const String chapterList = 'Chapters';
  static const String synopsis = 'Synopsis';
  static const String hide = 'Hide';
  static const String addedToBookmark = 'Added to bookmarks';
  static const String removedFromBookmark = 'Removed from bookmarks';
  static const String saveImg = 'Save image';
  static const String seeCover = 'View cover';
  static const String rating = 'Rating';
  static const String chapter = 'Chapter';
  static const String chapters = 'Chapters';
  static const String chapterLower = 'chapter';
  static const String chaptersLower = 'chapters';
  static const String released = 'Released';
  static const String readMore = 'Read more';
  static const String newLabel = 'New';
  static const String startReading = 'Start reading';
  static const String addBookmark = 'Add to bookmarks';
  static const String removeBookmark = 'Remove from bookmarks';
  static const String selectAll = 'Select all';
  static const String markRead = 'Mark as read';
  static const String markUnread = 'Mark as unread';
  static const String searchChapter = 'Search chapter';
  static const String searchChapterHint = 'Chapter number';
  static const String sortChapter = 'Sort chapters';
  static const String share = 'Share';
  static const String shareSuffix = 'read it on BacaKomik';
  static const String titleCopied = 'Title copied to clipboard';
  static const String copyTitle = 'Copy title';
  static const String successSaveImg = 'Image saved to gallery.';
  static const String failedSaveImg = "Couldn't save image.";

  // Bookmarks Screen Text
  static const String bookmarkEmpty = 'No bookmarks yet';
  static const String bookmarkEmptyHint =
      "Tap the bookmark icon on a comic's page to save it here.";
  static const String searchBookmarkHint = 'Search bookmarks';
  static const String filterAll = 'All';
  static const String filterUpdated = 'Updated';
  static const String filterFinished = 'Completed';
  static const String comic = 'comic';
  static const String comics = 'comics';
  static const String hasUpdate = 'updated';
  static const String deleteBookmark = 'Delete bookmarks';
  static const String deleteBookmarkDescription =
      'Are you sure you want to remove these comics from your bookmarks?';
  static const String selected = 'selected';
  static const String cancel = 'Cancel';
  static const String delete = 'Delete';

  // Search Screen Text
  static const String searchHint = 'Search comics';
  static const String comicNotFound = 'No comics found';
  static const String comicNotFoundFilter =
      'Try changing or resetting the filters.';
  static const String comicNotFoundSearch = 'Try a different keyword.';

  // Filter Screen Text
  static const String filter = 'Filter';
  static const String reset = 'Reset';
  static const String type = 'Type';
  static const String status = 'Status';
  static const String genre = 'Genre';
  static const String sortShort = 'Sort';
  static const String sortShortLong = 'Sort by';
  static const String showResults = 'Show results';
  static const String close = 'Close';
  static const String exploreSearchHint = 'Search comic titles';

  // History Screen Text
  static const String historyEmpty = 'No reading history yet';
  static const String historyEmptyHint = 'Chapters you read will show up here.';
  static const String swipeToDelete = 'swipe to delete';
  static const String today = 'Today';
  static const String yesterday = 'Yesterday';
  static const String deleteLastChapter = 'Last chapter only';
  static const String deleteAllChapters = 'All chapters of this comic';
  static const String clearHistory = 'Clear history';
  static const String clearHistoryConfirmation =
      'Are you sure you want to clear all saved reading history?';

  // More Screen Text
  static const String history = 'Reading history';

  static const String clearCache = 'Clear cache';
  static const String clearCacheDescription = 'Library and downloads stay safe';
  static const String clearCacheScope =
      'Covers · chapter pages · temporary data';
  static const String cacheImages = 'Covers & chapter pages';
  static const String cacheCleared = 'Cache cleared';
  static const String removed = 'Removed';
  static const String kept = 'Kept';
  static const String clearCacheConfirmation =
      'Saved images are deleted and downloaded again when you open them. '
      'Bookmarks, reading history and downloads are kept.';

  static const String backupData = 'Back up data';
  static const String backupDataDescription = 'Bookmarks and reading history';
  static const String successBackupData = 'Data backed up';
  static const String failedBackupData = "Couldn't back up data";

  static const String restoreData = 'Restore data';
  static const String restoreDataDescription = 'From a backup file';
  static const String successRestoreData = 'Data restored';
  static const String failedRestoreData = "Couldn't restore data";

  static const String sync = 'Sync';
  static const String syncDrive = 'Google Drive sync';
  static const String syncDriveDescription =
      'Bookmarks and reading history on all your devices';
  static const String syncSigningIn = 'Connecting…';
  static const String syncSignInFailed = "Couldn't sign in to Google";
  static const String syncNow = 'Sync now';
  static const String syncing = 'Syncing…';
  static const String syncFailed = 'Sync failed, tap to try again';
  static const String syncNever = 'Never synced';
  static const String syncLast = 'Last';
  static const String syncSignOut = 'Disconnect Google Drive';
  static const String syncSignOutDescription =
      'Data on this device stays saved';

  static const String bugReport = 'Report a bug or suggestion';
  static const String aboutApp = 'About the app';
  static const String website = 'Kurodev website';
  static const String linkFailed = "Couldn't open the link";
  static const String chaptersRead = 'Chapters read';
  static const String data = 'Data';
  static const String theme = 'Theme';
  static const String about = 'About';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String version = 'Version';

  // Download Text
  static const String downloads = 'Downloads';
  static const String downloadsDescription = 'Chapters for offline reading';
  static const String download = 'Download';
  static const String downloadQueued = 'queued for download';
  static const String downloadQueue = 'Queue';
  static const String downloadWaiting = 'Waiting';
  static const String downloadFailed = 'Failed';
  static const String downloadRetry = 'Retry download';
  static const String downloadRetryAll = 'Retry all';
  static const String downloadCancel = 'Cancel download';
  static const String downloadsEmpty = 'No downloads yet';
  static const String downloadsEmptyHint =
      "Select chapters on a comic's page, then tap the download icon.";
  static const String downloadedChapters = 'Downloaded chapters';
  static const String storageUsed = 'Storage used';
  static const String deleteDownloads = 'Delete downloads';
  static const String deleteComicDownloads =
      'Delete all downloaded chapters of this comic?';
  static const String clearDownloads = 'Delete all downloads';
  static const String clearDownloadsConfirmation =
      'All downloaded chapters are deleted from this device. Bookmarks and '
      'reading history are kept.';
  static const String downloadedLabel = 'Downloaded';
  static const String downloadNotificationRunning = 'Downloading chapters';
  static const String downloadNotificationDone = 'Downloads complete';
  static const String downloadNotificationFailed = 'Some downloads failed';

  // Update Text
  static const String checkUpdate = 'Check for updates';
  static const String updateAvailable = 'Update available';
  static const String updateNow = 'Update';
  static const String updateLater = 'Later';
  static const String updateRetry = 'Try again';
  static const String updateDownloading = 'Downloading';
  static const String updateInstalling = 'Opening installer';
  static const String updateFailed = 'Update failed. Try again later.';
  static const String upToDate = "You're on the latest version";
  static const String checkUpdateFailed = "Couldn't check for updates";
  static const String viewRelease = 'View on GitHub';

  // Settings Text

  // Reader Text
  static const String readerSettings = 'Reader settings';
  static const String readingDirection = 'Reading direction';
  static const String directionVertical = 'Vertical';
  static const String directionRtl = 'Right to left';
  static const String directionLtr = 'Left to right';
  static const String pageSize = 'Page size';
  static const String fitWidth = 'Fit width';
  static const String fitHeight = 'Fit height';
  static const String keepScreenOn = 'Keep screen on';
  static const String keepScreenOnHint = 'While reading a chapter';
  static const String pageGap = 'Page gap';
  static const String pageGapHint = '8px line between pages';
  static const String pageShort = 'Page';
  static const String autoScrollSpeed = 'Scroll speed';
  static const String autoScrollHint = 'Vertical mode. Tap the screen to pause';
  static const String autoScrollStart = 'Start auto-scroll';
  static const String autoScrollStop = 'Stop auto-scroll';
  static const String slower = 'Slower';
  static const String faster = 'Faster';
  static const String pages = 'pages';
  static const String finished = 'Finished';
  static const String finishedLower = 'finished';
  static const String nextChapter = 'Next';
  static const String previousChapter = 'Previous chapter';
  static const String releasedOn = 'Released';
  static const String continueTo = 'Continue to Chapter';
  static const String latestChapterReached =
      "You're on the latest chapter. New chapters will show up in Bookmarks.";
  static const String toHome = 'Go home';

  // Bookmark groups and categories
  static const String groupBy = 'Group by';
  static const String groupByStatus = 'Status';
  static const String groupByStatusDescription = 'All, updated, completed';
  static const String groupBySource = 'Source';
  static const String groupBySourceDescription = 'One tab per source';
  static const String groupByCategory = 'Category';
  static const String groupByCategoryDescription = 'Your own categories';
  static const String categories = 'Categories';
  static const String manageCategories = 'Manage categories';
  static const String categoriesDescription =
      'Long press bookmarks, then the folder button to put them in one.';
  static const String uncategorized = 'Uncategorized';
  static const String setCategories = 'Set categories';
  static const String noCategories = 'No categories yet';
  static const String newCategoryHint = 'New category';
  static const String addCategory = 'Add category';
  static const String renameCategory = 'Rename';
  static const String deleteCategory = 'Delete category';
  static const String deleteCategoryDescription =
      'Its comics stay bookmarked and keep their other categories.';
  static const String save = 'Save';
  static const String skip = 'Skip';

  // Bookmark refresh notification
  static const String progressChannel = 'Progress';
  static const String updatingBookmarks = 'Updating bookmarks';
  static const String bookmarksUpdated = 'Bookmarks updated';
  static const String haveNewChapters = 'with new chapters';

  // Sources and extensions
  static const String changeSource = 'Change source';
  static const String manage = 'Manage';
  static const String addSource = 'Add source';
  static const String openSource = 'Open';
  static const String sourceFrom = 'From';
  static const String sourceConnecting = 'Connecting';
  static const String sourceOnline = 'Online';
  static const String sourceOffline = 'Offline';
  static const String sourceError = 'Error';
  static const String noSourceShort = 'No source installed';
  static const String extensions = 'Extensions';
  static const String extensionsDescription = 'Sources to read comics from';
  static const String installed = 'Installed';
  static const String available = 'Available';
  static const String install = 'Install';
  static const String update = 'Update';
  static const String uninstall = 'Uninstall';
  static const String uninstallDescription =
      'Its bookmarks and reading history stay, but can only be opened again '
      'after reinstalling the extension.';
  static const String extensionInstalled = 'installed';
  static const String extensionUpdated = 'updated';
  static const String needsAppUpdate = 'Needs app update';
  static const String noExtensionsHint =
      'Install an extension to browse and read comics.';
  static const String noAvailableExtensions = 'Nothing new to install';
  static const String noAvailableExtensionsHint =
      'Every extension from your repos is installed. Add a repo for more.';
  static const String manageRepos = 'Extension repos';
  static const String reposDescription = 'Where extensions are listed from';
  static const String addRepo = 'Add repo';
  static const String repoAdding = 'Checking repo…';
  static const String repoInvalid = 'Not a valid extension repo URL';
  static const String repoFailed = 'Repo unavailable';
  static const String repoWarning =
      'Extensions run code and access the internet. Only add repos you trust.';
  static const String noFilters = 'This source has no filters.';
  static const String duplicateTitle = 'Already in your library';
  static const String duplicateMessagePrefix =
      'You bookmarked this series from';
  static const String duplicateMessage =
      'Migrate moves that bookmark and its reading history here. '
      'Add anyway keeps both as separate entries.';
  static const String migrate = 'Migrate';
  static const String addAnyway = 'Add anyway';
  static const String migrated = 'Migrated to this source';
}
