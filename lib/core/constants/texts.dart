class AppText {
  /// `1 comic`, `3 comics`.
  /// "Chapter 12", or the chapter's own [title] when its number was made
  /// up (see `Chapter.title`).
  static String chapterName(String number, [String? title]) =>
      title ?? '$chapter $number';

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
  static const String latest = 'Latest updates';
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
  static const String markedAllRead = 'marked as read';
  static const String markAllUnread = 'Mark all chapters as unread';
  static const String markAllUnreadDescription =
      'Reading progress of these comics is removed, and they leave History.';
  static const String markedAllUnread = 'marked as unread';
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
  static const String showAll = 'Show all';
  static const String showLess = 'Show less';
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
  static const String clearCacheDescription =
      'Library, covers and downloads stay safe';
  static const String clearCacheScope = 'Chapter pages · temporary data';
  static const String cacheImages = 'Chapter pages';
  static const String cacheCovers = 'Covers';
  static const String cacheCleared = 'Cache cleared';
  static const String removed = 'Removed';
  static const String kept = 'Kept';
  static const String clearCacheConfirmation =
      'Saved chapter pages are deleted and downloaded again when you open '
      'them. Covers, bookmarks, reading history and downloads are kept.';

  static const String backupData = 'Back up data';
  static const String backupDataDescription = 'Bookmarks and reading history';
  static const String successBackupData = 'Data backed up';
  static const String failedBackupData = "Couldn't back up data";

  static const String restoreData = 'Restore data';
  static const String restoreDataDescription = 'From a backup file';
  static const String successRestoreData = 'Data restored';
  static const String failedRestoreData = "Couldn't restore data";

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
  static const String sources = 'Sources';
  static const String library = 'Library';
  static const String backupAndSync = 'Backup & sync';
  static const String theme = 'Theme';
  static const String about = 'About';
  static const String themeSystem = 'System';
  static const String themeLight = 'Light';
  static const String themeDark = 'Dark';
  static const String kururinSound = 'Kuru-kuru sound';
  static const String kururinSoundDescription =
      'Plays while pulling to refresh Home';
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
  static const String incognito = 'Incognito mode';
  static const String incognitoDescription = 'Reading is not saved to history';
  static const String keepScreenOn = 'Keep screen on';
  static const String keepScreenOnHint = 'While reading a chapter';
  static const String pageGap = 'Page gap';
  static const String pageGapHint = '8px line between pages';
  static const String progressBar = 'Progress bar';
  static const String progressBarHint = 'Thin line at the bottom while reading';
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
  static const String groupByStatus = 'Status';
  static const String groupByStatusDescription = 'All, updated, completed';
  static const String groupBySource = 'Source';
  static const String groupBySourceDescription = 'One tab per source';
  static const String groupByCategory = 'Category';
  static const String groupByCategoryDescription = 'Your own categories';
  static const String groupAndSort = 'Group & sort';
  static const String groupTab = 'Group';
  static const String sortUpdated = 'Last updated';
  static const String sortTitle = 'Title';
  static const String sortChapters = 'Total chapters';
  static const String sortLatestChapter = 'Latest chapter';
  static const String sortAdded = 'Date added';
  static const String sortLastRead = 'Last read';
  static const String sortUnread = 'Unread chapters';
  static const String sortNewestFirst = 'Newest first';
  static const String sortOldestFirst = 'Oldest first';
  static const String sortAToZ = 'A to Z';
  static const String sortZToA = 'Z to A';
  static const String sortMostFirst = 'Most first';
  static const String sortFewestFirst = 'Fewest first';
  static const String sortReverseHint = 'Tap the selected order to reverse it.';
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
  static const String languages = 'Languages';
  static const String languagesDescription = 'Each language is its own source';
  static const String languagesHint =
      'Bookmarks and history are kept per language. Turning one off keeps '
      'them; its comics still open.';
  static const String searchExtensions = 'Search extensions';
  static const String allLanguages = 'All languages';
  static const String hideNsfw = 'Hide 18+';
  static const String languageFilterHint =
      'Extensions with several languages show under each of them.';
  static const String noMatchingExtensions = 'No extensions match';
  static const String noMatchingExtensionsHint =
      'Try another name or language.';
  static const String comicKeyTooLong =
      "This comic's link is too long to keep in the library.";
  static const String scanlators = 'Scanlators';
  static const String scanlatorsHint =
      'Whose version of a chapter shows when several groups have it. '
      'Saved on this device.';
  static const String sourceOrder = "Source's order";
  static const String sourceSettings = 'Settings';
  static const String sourceSettingsHint =
      "The extension's own settings. Changes apply to its next request.";
  static const String noSourceSettings = 'This source has no settings.';
  static const String openWebView = 'Open in WebView';
  static const String refresh = 'Refresh';
  static const String openInBrowser = 'Open in browser';
  static const String clearCookies = 'Clear cookies';
  static const String cookiesCleared = 'Cookies cleared';
  static const String pageNotLoaded = "Page didn't load";
  static String connectionFailed(String host) =>
      "Couldn't connect to $host. Your network may be blocking it; try "
      'again, or use a VPN or another network.';
  static const String verificationNeeded = 'Verification needed';
  static const String verificationNeededHint =
      'The site wants to check you are not a bot. Pass the check in the '
      'WebView, then close it to try again.';
  static const String verifyInWebView = 'Verify in WebView';
  static const String sourceConnecting = 'Connecting';
  static const String sourceOnline = 'Online';
  static const String sourceOffline = 'Offline';
  static const String sourceError = 'Error';
  static const String noSourceShort = 'No source installed';
  static const String noSourceHint =
      'Install a source in Extensions to start reading.';
  static const String extensions = 'Extensions';
  static const String extensionsDescription = 'Sources to read comics from';
  static const String installed = 'Installed';
  static const String available = 'Available';
  static const String install = 'Install';
  static const String installing = 'Installing…';
  static const String sourceNotInstalled = 'is not installed';
  static const String sourceLooking = 'Looking for it in your repos…';
  static const String sourceInstallHint =
      'Install the extension to open this comic.';
  static const String sourceNotInRepos =
      'None of your repos has this source. Add its repo in Extensions.';
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
  static const String stopRefresh = 'Stop updating bookmarks';

  // Migration
  static const String migration = 'Migration';
  static const String migrationDescription =
      'Move series to another source, or import from other apps';
  static const String migrateSource = 'Migrate source';
  static const String migrateSourceDescription =
      'Move bookmarks and reading history to another source';
  static const String importMihon = 'Import from Mihon / Tachiyomi';
  static const String importMihonDescription =
      'Bookmarks from a .tachibk backup';
  static const String importComix = 'Import from Comix.to';
  static const String importComixDescription =
      'Bookmarks and read chapters from a .csv export';
  static const String migrateFrom = 'From';
  static const String migrateTo = 'To';
  static const String importComixTo = 'Search the titles in';
  static const String pickSource = 'Pick a source';
  static const String noBookmarksToMigrate = 'No bookmarks to migrate';
  static const String noBookmarksToMigrateHint =
      'Bookmark comics first, then move them here.';
  static const String noOtherSource = 'Install another source to migrate to.';
  static const String findMatches = 'Find matches';
  static const String selectNone = 'Select none';
  static const String matchSearching = 'Searching…';
  static const String matchWaiting = 'Waiting';
  static const String matchNotFound = 'No match. Tap to search.';
  static const String matchFailed = 'Search failed. Tap to retry.';
  static const String matchSkipped = 'Skipped';
  static const String matchMigrated = 'Migrated';
  static const String matchMigrateFailed = 'Migration failed';
  static const String matchesFound = 'found';
  static const String searchingSlowly =
      'Comics are searched one at a time, a few seconds apart, so the site '
      'does not block you.';
  static const String pickMatch = 'Pick the match';
  static const String noResults = 'No results';
  static const String migrateCount = 'Migrate';
  static const String importCount = 'Import';
  static const String migrating = 'Migrating…';
  static const String importing = 'Importing…';
  static const String migrationDone = 'Migration done';
  static const String importDone = 'Import done';
  static const String added = 'added';
  static const String alreadyInLibrary = 'already in your library';
  static const String sameTitleElsewhere = 'bookmarked from another source';
  static const String failed = 'failed';
  static const String importLoadHint =
      'Covers and chapters load when you open a comic, or pull to refresh '
      'in Bookmarks.';
  static const String chaptersMarkedRead = 'chapters marked read';
  static const String mihonLoadHint =
      'Covers load when you open a comic, or pull to refresh in Bookmarks.';
  static const String readTo = 'Read to ch.';
  static const String chooseFile = 'Choose file';
  static const String readingFile = 'Reading file…';
  static const String mihonHint =
      'In Mihon, open More → Backup and restore → Create backup, then pick '
      'the .tachibk file here. Only bookmarked comics from sources BacaKomik '
      'has are imported, with their categories and read chapters. Run it '
      'again to bring read chapters to comics imported before.';
  static const String notAvailableHere = 'Not available here';
  static const String unreadableLinks = 'unreadable links';
  static const String needsInstall = 'Not installed';
  static const String done = 'Done';
}
