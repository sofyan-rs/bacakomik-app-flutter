// flutter_inappwebview on WebKitGTK (webkit2gtk-4.1).
//
// WebKitGTK is opened with dlopen on first use, so the app needs neither its
// headers to build nor the library to start. Views are of two kinds:
//
// - headless: a WebKitWebView in a GtkOffscreenWindow, for pages that run
//   extension scripts;
// - visible: a WebKitWebView laid over the Flutter view in the window's
//   GtkOverlay (see linux/runner/my_application.cc), at the rect Dart sends.
//   Flutter cannot draw over it, so Dart hides it while something should.
//
// Everything goes through one method channel; calls name the view by "id".

#include "include/flutter_inappwebview_linux/inappwebview_linux_plugin.h"

#include <dlfcn.h>
#include <gtk/gtk.h>

#include <cstring>
#include <map>
#include <string>
#include <vector>

namespace {

// --- WebKitGTK, JavaScriptCore and libsoup, opened at run time -------------

// WebKitLoadEvent
constexpr int kLoadStarted = 0;
constexpr int kLoadFinished = 3;
// WebKitPolicyDecisionType
constexpr int kNewWindowAction = 1;
constexpr int kResponse = 2;
// WebKitCookiePersistentStorage
constexpr int kCookieStorageSqlite = 1;
// WebKitNetworkProxyMode
constexpr int kProxyDefault = 0;
constexpr int kProxyCustom = 2;

struct WebKit {
  bool tried = false;
  bool loaded = false;

  GType (*web_view_get_type)();
  void (*web_view_load_uri)(gpointer, const char*);
  void (*web_view_reload)(gpointer);
  void (*web_view_stop_loading)(gpointer);
  void (*web_view_go_back)(gpointer);
  gboolean (*web_view_can_go_back)(gpointer);
  const char* (*web_view_get_title)(gpointer);
  const char* (*web_view_get_uri)(gpointer);
  gpointer (*web_view_get_settings)(gpointer);
  void (*web_view_call_async_javascript_function)(gpointer, const char*,
                                                  gssize, GVariant*,
                                                  const char*, const char*,
                                                  GCancellable*,
                                                  GAsyncReadyCallback,
                                                  gpointer);
  gpointer (*web_view_call_async_javascript_function_finish)(gpointer,
                                                             GAsyncResult*,
                                                             GError**);
  gpointer (*navigation_policy_decision_get_navigation_action)(gpointer);
  gpointer (*navigation_action_get_request)(gpointer);
  const char* (*uri_request_get_uri)(gpointer);
  void (*policy_decision_ignore)(gpointer);
  void (*policy_decision_use)(gpointer);
  gpointer (*response_policy_decision_get_response)(gpointer);
  gboolean (*response_policy_decision_is_mime_type_supported)(gpointer);
  // WebKitGTK 2.40 and newer; without it navigations are not intercepted.
  gboolean (*response_policy_decision_is_main_frame_main_resource)(gpointer) =
      nullptr;
  const char* (*uri_response_get_uri)(gpointer);
  gpointer (*web_context_get_default)();
  gpointer (*web_context_get_website_data_manager)(gpointer);
  gpointer (*website_data_manager_get_cookie_manager)(gpointer);
  void (*cookie_manager_set_persistent_storage)(gpointer, const char*, int);
  void (*cookie_manager_get_cookies)(gpointer, const char*, GCancellable*,
                                     GAsyncReadyCallback, gpointer);
  GList* (*cookie_manager_get_cookies_finish)(gpointer, GAsyncResult*,
                                              GError**);
  void (*cookie_manager_delete_cookie)(gpointer, gpointer, GCancellable*,
                                       GAsyncReadyCallback, gpointer);
  gboolean (*cookie_manager_delete_cookie_finish)(gpointer, GAsyncResult*,
                                                  GError**);
  void (*cookie_manager_delete_all_cookies)(gpointer);
  // Optional: without them the views keep the system's proxy settings.
  gpointer (*network_proxy_settings_new)(const char*, const char* const*) =
      nullptr;
  void (*network_proxy_settings_free)(gpointer) = nullptr;
  // WebKitGTK 2.32 and newer; older ones set it on the web context.
  void (*website_data_manager_set_network_proxy_settings)(gpointer, int,
                                                          gpointer) = nullptr;
  void (*web_context_set_network_proxy_settings)(gpointer, int, gpointer) =
      nullptr;

  char* (*jsc_value_to_json)(gpointer, guint);
  gboolean (*jsc_value_is_undefined)(gpointer);

  const char* (*soup_cookie_get_name)(gpointer);
  const char* (*soup_cookie_get_value)(gpointer);
  const char* (*soup_cookie_get_domain)(gpointer);
  const char* (*soup_cookie_get_path)(gpointer);
  GDateTime* (*soup_cookie_get_expires)(gpointer);
  gboolean (*soup_cookie_get_secure)(gpointer);
  gboolean (*soup_cookie_get_http_only)(gpointer);
  void (*soup_cookie_free)(gpointer);

  gpointer cookie_manager = nullptr;
  gpointer context = nullptr;
  gpointer data_manager = nullptr;
};

WebKit wk;

template <typename T>
bool Sym(void* lib, const char* name, T* out) {
  *out = reinterpret_cast<T>(dlsym(lib, name));
  if (*out == nullptr) g_warning("WebKitGTK: %s is missing", name);
  return *out != nullptr;
}

// Opens WebKitGTK once; false where it is not installed.
bool LoadWebKit() {
  if (wk.tried) return wk.loaded;
  wk.tried = true;
  // WebKit's DMA-BUF renderer draws nothing inside the Flutter window; the
  // shared-memory one does. Left alone when the user set it.
  g_setenv("WEBKIT_DISABLE_DMABUF_RENDERER", "1", FALSE);
  void* webkit = dlopen("libwebkit2gtk-4.1.so.0", RTLD_NOW | RTLD_GLOBAL);
  void* jsc = dlopen("libjavascriptcoregtk-4.1.so.0", RTLD_NOW | RTLD_GLOBAL);
  void* soup = dlopen("libsoup-3.0.so.0", RTLD_NOW | RTLD_GLOBAL);
  if (webkit == nullptr || jsc == nullptr || soup == nullptr) {
    g_warning("WebKitGTK 4.1 is not installed: %s", dlerror());
    return false;
  }
#define W(name) Sym(webkit, "webkit_" #name, &wk.name)
#define J(name) Sym(jsc, #name, &wk.name)
#define S(name) Sym(soup, #name, &wk.name)
  wk.loaded =
      W(web_view_get_type) && W(web_view_load_uri) && W(web_view_reload) &&
      W(web_view_stop_loading) && W(web_view_go_back) &&
      W(web_view_can_go_back) && W(web_view_get_title) &&
      W(web_view_get_uri) && W(web_view_get_settings) &&
      W(web_view_call_async_javascript_function) &&
      W(web_view_call_async_javascript_function_finish) &&
      W(navigation_policy_decision_get_navigation_action) &&
      W(navigation_action_get_request) && W(uri_request_get_uri) &&
      W(policy_decision_ignore) && W(policy_decision_use) &&
      W(response_policy_decision_get_response) &&
      W(response_policy_decision_is_mime_type_supported) &&
      W(uri_response_get_uri) && W(web_context_get_default) &&
      W(web_context_get_website_data_manager) &&
      W(website_data_manager_get_cookie_manager) &&
      W(cookie_manager_set_persistent_storage) &&
      W(cookie_manager_get_cookies) && W(cookie_manager_get_cookies_finish) &&
      W(cookie_manager_delete_cookie) &&
      W(cookie_manager_delete_cookie_finish) &&
      W(cookie_manager_delete_all_cookies) && J(jsc_value_to_json) &&
      J(jsc_value_is_undefined) && S(soup_cookie_get_name) &&
      S(soup_cookie_get_value) && S(soup_cookie_get_domain) &&
      S(soup_cookie_get_path) && S(soup_cookie_get_expires) &&
      S(soup_cookie_get_secure) && S(soup_cookie_get_http_only) &&
      S(soup_cookie_free);
#undef W
#undef J
#undef S
  if (!wk.loaded) return false;
  wk.response_policy_decision_is_main_frame_main_resource =
      reinterpret_cast<gboolean (*)(gpointer)>(dlsym(
          webkit, "webkit_response_policy_decision_is_main_frame_main_resource"));
  wk.network_proxy_settings_new =
      reinterpret_cast<gpointer (*)(const char*, const char* const*)>(
          dlsym(webkit, "webkit_network_proxy_settings_new"));
  wk.network_proxy_settings_free = reinterpret_cast<void (*)(gpointer)>(
      dlsym(webkit, "webkit_network_proxy_settings_free"));
  wk.website_data_manager_set_network_proxy_settings =
      reinterpret_cast<void (*)(gpointer, int, gpointer)>(dlsym(
          webkit, "webkit_website_data_manager_set_network_proxy_settings"));
  wk.web_context_set_network_proxy_settings =
      reinterpret_cast<void (*)(gpointer, int, gpointer)>(
          dlsym(webkit, "webkit_web_context_set_network_proxy_settings"));

  // Cookies outlive the app, as they do in the WebViews of other platforms.
  gpointer context = wk.context = wk.web_context_get_default();
  gpointer data = wk.data_manager =
      wk.web_context_get_website_data_manager(context);
  wk.cookie_manager = wk.website_data_manager_get_cookie_manager(data);
  g_autofree char* dir =
      g_build_filename(g_get_user_data_dir(), g_get_prgname(), "webview",
                       nullptr);
  g_mkdir_with_parents(dir, 0700);
  g_autofree char* file = g_build_filename(dir, "cookies.sqlite", nullptr);
  wk.cookie_manager_set_persistent_storage(wk.cookie_manager, file,
                                           kCookieStorageSqlite);
  return true;
}

// --- Views -----------------------------------------------------------------

struct View {
  int64_t id = 0;
  GtkWidget* web_view = nullptr;
  // Headless views live in an offscreen window; visible ones in the overlay.
  GtkWidget* offscreen = nullptr;
  GdkRectangle rect = {0, 0, 0, 0};
  // Asks Dart before a main-frame page replaces the one shown.
  bool intercept = false;
  // Pages a link opens in a new window load in this view instead.
  bool new_windows_in_place = true;
};

struct Plugin {
  FlMethodChannel* channel = nullptr;
  GtkWidget* flutter_view = nullptr;
  std::map<int64_t, View*> views;
};

Plugin* plugin = nullptr;

int64_t ArgInt(FlValue* args, const char* key, int64_t fallback = 0) {
  FlValue* v = fl_value_lookup_string(args, key);
  if (v == nullptr) return fallback;
  if (fl_value_get_type(v) == FL_VALUE_TYPE_INT) return fl_value_get_int(v);
  if (fl_value_get_type(v) == FL_VALUE_TYPE_FLOAT) {
    return static_cast<int64_t>(fl_value_get_float(v) + 0.5);
  }
  return fallback;
}

const char* ArgString(FlValue* args, const char* key) {
  FlValue* v = fl_value_lookup_string(args, key);
  return v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_STRING
             ? fl_value_get_string(v)
             : nullptr;
}

bool ArgBool(FlValue* args, const char* key, bool fallback = false) {
  FlValue* v = fl_value_lookup_string(args, key);
  return v != nullptr && fl_value_get_type(v) == FL_VALUE_TYPE_BOOL
             ? fl_value_get_bool(v)
             : fallback;
}

View* FindView(FlValue* args) {
  auto it = plugin->views.find(ArgInt(args, "id", -1));
  return it == plugin->views.end() ? nullptr : it->second;
}

FlValue* EventArgs(View* view) {
  FlValue* args = fl_value_new_map();
  fl_value_set_string_take(args, "id", fl_value_new_int(view->id));
  return args;
}

void SetString(FlValue* map, const char* key, const char* value) {
  fl_value_set_string_take(
      map, key, value ? fl_value_new_string(value) : fl_value_new_null());
}

void Send(const char* method, FlValue* args) {
  g_autoptr(FlValue) owned = args;
  fl_method_channel_invoke_method(plugin->channel, method, owned, nullptr,
                                  nullptr, nullptr);
}

// The GtkOverlay that holds the Flutter view, if the runner made one.
GtkOverlay* Overlay() {
  GtkWidget* parent = gtk_widget_get_parent(plugin->flutter_view);
  return GTK_IS_OVERLAY(parent) ? GTK_OVERLAY(parent) : nullptr;
}

gboolean OnChildPosition(GtkOverlay*, GtkWidget* child,
                         GdkRectangle* allocation, gpointer) {
  for (auto& [id, view] : plugin->views) {
    if (view->web_view == child) {
      *allocation = view->rect;
      return TRUE;
    }
  }
  return FALSE;
}

// --- WebKit signals ----------------------------------------------------------

struct Navigation {
  gpointer decision;  // WebKitResponsePolicyDecision, held until Dart answers
};

// Dart answered whether a main-frame navigation may go on.
void OnNavigationAnswer(GObject* source, GAsyncResult* result,
                        gpointer data) {
  auto* nav = static_cast<Navigation*>(data);
  g_autoptr(FlMethodResponse) response = fl_method_channel_invoke_method_finish(
      FL_METHOD_CHANNEL(source), result, nullptr);
  FlValue* allow = response && FL_IS_METHOD_SUCCESS_RESPONSE(response)
                       ? fl_method_success_response_get_result(
                             FL_METHOD_SUCCESS_RESPONSE(response))
                       : nullptr;
  bool allowed = allow == nullptr ||
                 fl_value_get_type(allow) != FL_VALUE_TYPE_BOOL ||
                 fl_value_get_bool(allow);
  if (allowed &&
      wk.response_policy_decision_is_mime_type_supported(nav->decision)) {
    wk.policy_decision_use(nav->decision);
  } else {
    wk.policy_decision_ignore(nav->decision);
  }
  g_object_unref(nav->decision);
  delete nav;
}

void OnLoadChanged(GtkWidget* web_view, int event, gpointer data) {
  auto* view = static_cast<View*>(data);
  const char* uri = wk.web_view_get_uri(web_view);
  if (event == kLoadStarted) {
    FlValue* args = EventArgs(view);
    SetString(args, "url", uri);
    Send("onLoadStart", args);
  }
  if (event == kLoadFinished) {
    FlValue* args = EventArgs(view);
    SetString(args, "url", uri);
    Send("onLoadStop", args);
  }
}

gboolean OnLoadFailed(GtkWidget*, int, const char* uri, GError* error,
                      gpointer data) {
  // Stopped on purpose (a new load, a navigation Dart refused).
  const char* domain = g_quark_to_string(error->domain);
  if ((g_strcmp0(domain, "WebKitNetworkError") == 0 && error->code == 302) ||
      (g_strcmp0(domain, "WebKitPolicyError") == 0 && error->code == 102)) {
    return FALSE;
  }
  auto* view = static_cast<View*>(data);
  FlValue* args = EventArgs(view);
  SetString(args, "url", uri);
  SetString(args, "description", error->message);
  fl_value_set_string_take(args, "code", fl_value_new_int(error->code));
  Send("onReceivedError", args);
  return FALSE;
}

// A certificate WebKit refuses (e.g. an ISP's block page standing in for
// the site) is not a load-failed. Reported like other errors, so the app
// shows its own page instead of WebKit's and a hidden page fails at once.
gboolean OnTlsFailed(GtkWidget*, const char* uri, GTlsCertificate*,
                     GTlsCertificateFlags errors, gpointer data) {
  const char* description =
      errors & G_TLS_CERTIFICATE_BAD_IDENTITY
          ? "The certificate is not this site's: the network may be "
            "blocking it"
      : errors & G_TLS_CERTIFICATE_EXPIRED
          ? "The site's certificate has expired"
      : errors & G_TLS_CERTIFICATE_UNKNOWN_CA
          ? "The site's certificate is not from a trusted authority"
          : "The site's certificate was refused";
  auto* view = static_cast<View*>(data);
  FlValue* args = EventArgs(view);
  SetString(args, "url", uri);
  SetString(args, "description", description);
  fl_value_set_string_take(args, "code", fl_value_new_int(errors));
  Send("onReceivedError", args);
  return TRUE;
}

void OnTitle(GObject*, GParamSpec*, gpointer data) {
  auto* view = static_cast<View*>(data);
  FlValue* args = EventArgs(view);
  SetString(args, "title", wk.web_view_get_title(view->web_view));
  Send("onTitleChanged", args);
}

void OnUri(GObject*, GParamSpec*, gpointer data) {
  auto* view = static_cast<View*>(data);
  FlValue* args = EventArgs(view);
  SetString(args, "url", wk.web_view_get_uri(view->web_view));
  Send("onUpdateVisitedHistory", args);
}

void OnProgress(GObject* object, GParamSpec*, gpointer data) {
  auto* view = static_cast<View*>(data);
  gdouble progress = 0;
  g_object_get(object, "estimated-load-progress", &progress, nullptr);
  FlValue* args = EventArgs(view);
  fl_value_set_string_take(args, "progress",
                           fl_value_new_int(static_cast<int>(progress * 100)));
  Send("onProgressChanged", args);
}

gboolean OnDecidePolicy(GtkWidget* web_view, gpointer decision, int type,
                        gpointer data) {
  auto* view = static_cast<View*>(data);
  if (type == kResponse) {
    // Asked once the response is in, before the page changes: navigation
    // actions in WebKitGTK do not tell the main frame from iframes.
    if (!view->intercept ||
        wk.response_policy_decision_is_main_frame_main_resource == nullptr ||
        !wk.response_policy_decision_is_main_frame_main_resource(decision)) {
      return FALSE;
    }
    const char* uri = wk.uri_response_get_uri(
        wk.response_policy_decision_get_response(decision));
    g_autoptr(FlValue) args = EventArgs(view);
    SetString(args, "url", uri);
    fl_method_channel_invoke_method(
        plugin->channel, "shouldOverrideUrlLoading", args, nullptr,
        OnNavigationAnswer, new Navigation{g_object_ref(decision)});
    return TRUE;
  }
  if (type != kNewWindowAction) return FALSE;
  // No second windows: a page meant for one opens here, or nowhere.
  gpointer action =
      wk.navigation_policy_decision_get_navigation_action(decision);
  const char* uri =
      wk.uri_request_get_uri(wk.navigation_action_get_request(action));
  std::string target = uri ? uri : "";
  wk.policy_decision_ignore(decision);
  if (view->new_windows_in_place && !target.empty()) {
    wk.web_view_load_uri(web_view, target.c_str());
  }
  return TRUE;
}

// Clicking the Flutter view takes the keyboard back from a web view.
gboolean OnFlutterViewPress(GtkWidget* widget, GdkEvent*, gpointer) {
  if (!gtk_widget_has_focus(widget)) gtk_widget_grab_focus(widget);
  return FALSE;
}

// --- Methods -----------------------------------------------------------------

FlMethodResponse* Error(const char* code, const char* message) {
  return FL_METHOD_RESPONSE(fl_method_error_response_new(code, message, nullptr));
}

FlMethodResponse* Ok(FlValue* value = nullptr) {
  g_autoptr(FlValue) owned = value;
  return FL_METHOD_RESPONSE(fl_method_success_response_new(owned));
}

// Sends every view's requests through the proxy at "url", except to the
// hosts in "bypass"; back to the system's settings when "url" is null.
FlMethodResponse* SetProxy(FlValue* args) {
  if (!LoadWebKit()) return Ok();
  auto set = [](int mode, gpointer settings) {
    if (wk.website_data_manager_set_network_proxy_settings != nullptr) {
      wk.website_data_manager_set_network_proxy_settings(wk.data_manager, mode,
                                                         settings);
    } else {
      wk.web_context_set_network_proxy_settings(wk.context, mode, settings);
    }
  };
  if (wk.network_proxy_settings_new == nullptr ||
      wk.network_proxy_settings_free == nullptr ||
      (wk.website_data_manager_set_network_proxy_settings == nullptr &&
       wk.web_context_set_network_proxy_settings == nullptr)) {
    return Error("unsupported", "This WebKitGTK cannot set a proxy");
  }
  const char* url = ArgString(args, "url");
  if (url == nullptr) {
    set(kProxyDefault, nullptr);
    return Ok();
  }
  std::vector<const char*> hosts;
  FlValue* bypass = fl_value_lookup_string(args, "bypass");
  if (bypass != nullptr && fl_value_get_type(bypass) == FL_VALUE_TYPE_LIST) {
    for (size_t i = 0; i < fl_value_get_length(bypass); i++) {
      FlValue* host = fl_value_get_list_value(bypass, i);
      if (fl_value_get_type(host) == FL_VALUE_TYPE_STRING) {
        hosts.push_back(fl_value_get_string(host));
      }
    }
  }
  hosts.push_back(nullptr);
  gpointer settings = wk.network_proxy_settings_new(url, hosts.data());
  set(kProxyCustom, settings);
  wk.network_proxy_settings_free(settings);
  return Ok();
}

void DisposeView(View* view) {
  plugin->views.erase(view->id);
  g_signal_handlers_disconnect_by_data(view->web_view, view);
  if (view->offscreen != nullptr) {
    gtk_widget_destroy(view->offscreen);
  } else {
    if (gtk_widget_has_focus(view->web_view)) {
      gtk_widget_grab_focus(plugin->flutter_view);
    }
    gtk_widget_destroy(view->web_view);
  }
  delete view;
}

FlMethodResponse* Create(FlValue* args) {
  if (!LoadWebKit()) return Error("unavailable", "WebKitGTK 4.1 is missing");
  auto* view = new View();
  view->id = ArgInt(args, "id");
  view->intercept = ArgBool(args, "intercept");
  view->new_windows_in_place = ArgBool(args, "newWindowsInPlace", true);
  bool headless = ArgBool(args, "headless");

  GtkOverlay* overlay = headless ? nullptr : Overlay();
  if (!headless && overlay == nullptr) {
    delete view;
    return Error("no_overlay", "The window has no GtkOverlay for web views");
  }

  view->web_view =
      GTK_WIDGET(g_object_new(wk.web_view_get_type(), nullptr));
  gpointer settings = wk.web_view_get_settings(view->web_view);
  g_object_set(settings, "enable-javascript", TRUE,
               "javascript-can-open-windows-automatically", FALSE,
               "enable-developer-extras", ArgBool(args, "devTools"), nullptr);
  if (const char* ua = ArgString(args, "userAgent")) {
    g_object_set(settings, "user-agent", ua, nullptr);
  }

  g_signal_connect(view->web_view, "load-changed", G_CALLBACK(OnLoadChanged),
                   view);
  g_signal_connect(view->web_view, "load-failed", G_CALLBACK(OnLoadFailed),
                   view);
  g_signal_connect(view->web_view, "load-failed-with-tls-errors",
                   G_CALLBACK(OnTlsFailed), view);
  g_signal_connect(view->web_view, "notify::title", G_CALLBACK(OnTitle), view);
  g_signal_connect(view->web_view, "notify::uri", G_CALLBACK(OnUri), view);
  g_signal_connect(view->web_view, "notify::estimated-load-progress",
                   G_CALLBACK(OnProgress), view);
  g_signal_connect(view->web_view, "decide-policy",
                   G_CALLBACK(OnDecidePolicy), view);

  int width = static_cast<int>(ArgInt(args, "width", 360));
  int height = static_cast<int>(ArgInt(args, "height", 640));
  if (headless) {
    view->offscreen = gtk_offscreen_window_new();
    gtk_window_set_default_size(GTK_WINDOW(view->offscreen), width, height);
    gtk_widget_set_size_request(view->web_view, width, height);
    gtk_container_add(GTK_CONTAINER(view->offscreen), view->web_view);
    gtk_widget_show_all(view->offscreen);
  } else {
    // Shown once Dart sends where it goes.
    gtk_overlay_add_overlay(overlay, view->web_view);
  }
  plugin->views[view->id] = view;

  if (const char* url = ArgString(args, "url")) {
    wk.web_view_load_uri(view->web_view, url);
  }
  return Ok();
}

FlMethodResponse* SetRect(View* view, FlValue* args) {
  if (view->offscreen != nullptr) {
    gtk_widget_set_size_request(view->web_view,
                                static_cast<int>(ArgInt(args, "width")),
                                static_cast<int>(ArgInt(args, "height")));
    return Ok();
  }
  view->rect = {static_cast<int>(ArgInt(args, "x")),
                static_cast<int>(ArgInt(args, "y")),
                static_cast<int>(ArgInt(args, "width")),
                static_cast<int>(ArgInt(args, "height"))};
  bool visible = ArgBool(args, "visible") && view->rect.width > 0 &&
                 view->rect.height > 0;
  if (visible) {
    gtk_widget_show(view->web_view);
    gtk_widget_queue_resize(view->web_view);
  } else {
    if (gtk_widget_has_focus(view->web_view)) {
      gtk_widget_grab_focus(plugin->flutter_view);
    }
    gtk_widget_hide(view->web_view);
  }
  return Ok();
}

void OnJavaScriptDone(GObject* source, GAsyncResult* result, gpointer data) {
  g_autoptr(FlMethodCall) call = FL_METHOD_CALL(data);
  g_autoptr(GError) error = nullptr;
  gpointer value = wk.web_view_call_async_javascript_function_finish(
      source, result, &error);
  g_autoptr(FlValue) map = fl_value_new_map();
  if (error != nullptr) {
    SetString(map, "error", error->message);
  } else if (value != nullptr && !wk.jsc_value_is_undefined(value)) {
    g_autofree char* json = wk.jsc_value_to_json(value, 0);
    SetString(map, "value", json);
  }
  if (value != nullptr) g_object_unref(value);
  fl_method_call_respond_success(call, map, nullptr);
}

struct CookieCall {
  FlMethodCall* call;
  std::string name;    // deleteCookie: only this one
  std::string domain;  // deleteCookies: only this domain
  bool remove = false;
};

void OnCookieDeleted(GObject* source, GAsyncResult* result, gpointer) {
  wk.cookie_manager_delete_cookie_finish(source, result, nullptr);
}

bool DomainMatches(const char* cookie_domain, const std::string& domain) {
  if (domain.empty()) return true;
  std::string d = cookie_domain ? cookie_domain : "";
  if (!d.empty() && d[0] == '.') d.erase(0, 1);
  std::string want = domain[0] == '.' ? domain.substr(1) : domain;
  return d == want;
}

void OnCookies(GObject* source, GAsyncResult* result, gpointer data) {
  auto* c = static_cast<CookieCall*>(data);
  g_autoptr(GError) error = nullptr;
  GList* cookies =
      wk.cookie_manager_get_cookies_finish(source, result, &error);
  if (error != nullptr) {
    fl_method_call_respond_error(c->call, "cookies", error->message, nullptr,
                                 nullptr);
  } else if (c->remove) {
    for (GList* l = cookies; l != nullptr; l = l->next) {
      if ((c->name.empty() || c->name == wk.soup_cookie_get_name(l->data)) &&
          DomainMatches(wk.soup_cookie_get_domain(l->data), c->domain)) {
        wk.cookie_manager_delete_cookie(wk.cookie_manager, l->data, nullptr,
                                        OnCookieDeleted, nullptr);
      }
    }
    g_autoptr(FlValue) ok = fl_value_new_bool(TRUE);
    fl_method_call_respond_success(c->call, ok, nullptr);
  } else {
    g_autoptr(FlValue) list = fl_value_new_list();
    for (GList* l = cookies; l != nullptr; l = l->next) {
      FlValue* map = fl_value_new_map();
      SetString(map, "name", wk.soup_cookie_get_name(l->data));
      SetString(map, "value", wk.soup_cookie_get_value(l->data));
      SetString(map, "domain", wk.soup_cookie_get_domain(l->data));
      SetString(map, "path", wk.soup_cookie_get_path(l->data));
      GDateTime* expires = wk.soup_cookie_get_expires(l->data);
      fl_value_set_string_take(
          map, "expiresDate",
          expires ? fl_value_new_int(g_date_time_to_unix(expires) * 1000)
                  : fl_value_new_null());
      fl_value_set_string_take(map, "isSessionOnly",
                               fl_value_new_bool(expires == nullptr));
      fl_value_set_string_take(
          map, "isSecure", fl_value_new_bool(wk.soup_cookie_get_secure(l->data)));
      fl_value_set_string_take(
          map, "isHttpOnly",
          fl_value_new_bool(wk.soup_cookie_get_http_only(l->data)));
      fl_value_append_take(list, map);
    }
    fl_method_call_respond_success(c->call, list, nullptr);
  }
  g_list_free_full(cookies, reinterpret_cast<GDestroyNotify>(wk.soup_cookie_free));
  g_object_unref(c->call);
  delete c;
}

void HandleCall(FlMethodChannel*, FlMethodCall* call, gpointer) {
  const char* method = fl_method_call_get_name(call);
  FlValue* args = fl_method_call_get_args(call);
  bool has_args = args != nullptr && fl_value_get_type(args) == FL_VALUE_TYPE_MAP;
  g_autoptr(FlMethodResponse) response = nullptr;

  if (strcmp(method, "isAvailable") == 0) {
    response = Ok(fl_value_new_bool(LoadWebKit()));
  } else if (strcmp(method, "disposeAll") == 0) {
    while (!plugin->views.empty()) DisposeView(plugin->views.begin()->second);
    response = Ok();
  } else if (!has_args) {
    response = Error("bad_args", "Arguments must be a map");
  } else if (strcmp(method, "create") == 0) {
    response = Create(args);
  } else if (strcmp(method, "setProxy") == 0) {
    response = SetProxy(args);
  } else if (strcmp(method, "getCookies") == 0 ||
             strcmp(method, "deleteCookies") == 0) {
    const char* url = ArgString(args, "url");
    if (!LoadWebKit() || url == nullptr) {
      response = strcmp(method, "getCookies") == 0
                     ? Ok(fl_value_new_list())
                     : Ok(fl_value_new_bool(FALSE));
    } else {
      auto* c = new CookieCall{FL_METHOD_CALL(g_object_ref(call))};
      c->remove = strcmp(method, "deleteCookies") == 0;
      if (const char* name = ArgString(args, "name")) c->name = name;
      if (const char* domain = ArgString(args, "domain")) c->domain = domain;
      wk.cookie_manager_get_cookies(wk.cookie_manager, url, nullptr, OnCookies,
                                    c);
      return;
    }
  } else if (strcmp(method, "deleteAllCookies") == 0) {
    if (LoadWebKit()) wk.cookie_manager_delete_all_cookies(wk.cookie_manager);
    response = Ok(fl_value_new_bool(TRUE));
  } else if (View* view = FindView(args); view == nullptr) {
    response = Error("no_view", "No web view with this id");
  } else if (strcmp(method, "dispose") == 0) {
    DisposeView(view);
    response = Ok();
  } else if (strcmp(method, "setRect") == 0) {
    response = SetRect(view, args);
  } else if (strcmp(method, "loadUrl") == 0) {
    if (const char* url = ArgString(args, "url")) {
      wk.web_view_load_uri(view->web_view, url);
    }
    response = Ok();
  } else if (strcmp(method, "reload") == 0) {
    wk.web_view_reload(view->web_view);
    response = Ok();
  } else if (strcmp(method, "stopLoading") == 0) {
    wk.web_view_stop_loading(view->web_view);
    response = Ok();
  } else if (strcmp(method, "goBack") == 0) {
    wk.web_view_go_back(view->web_view);
    response = Ok();
  } else if (strcmp(method, "canGoBack") == 0) {
    response = Ok(fl_value_new_bool(wk.web_view_can_go_back(view->web_view)));
  } else if (strcmp(method, "getTitle") == 0) {
    const char* title = wk.web_view_get_title(view->web_view);
    response = Ok(title ? fl_value_new_string(title) : nullptr);
  } else if (strcmp(method, "getUrl") == 0) {
    const char* uri = wk.web_view_get_uri(view->web_view);
    response = Ok(uri ? fl_value_new_string(uri) : nullptr);
  } else if (strcmp(method, "callAsyncJavaScript") == 0) {
    const char* body = ArgString(args, "functionBody");
    wk.web_view_call_async_javascript_function(
        view->web_view, body ? body : "", -1, nullptr, nullptr, nullptr,
        nullptr, OnJavaScriptDone, g_object_ref(call));
    return;
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }
  fl_method_call_respond(call, response, nullptr);
}

}  // namespace

void inappwebview_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  if (plugin != nullptr) return;
  plugin = new Plugin();
  FlView* view = fl_plugin_registrar_get_view(registrar);
  plugin->flutter_view = view ? GTK_WIDGET(view) : nullptr;
  if (plugin->flutter_view != nullptr) {
    g_signal_connect(plugin->flutter_view, "button-press-event",
                     G_CALLBACK(OnFlutterViewPress), nullptr);
    if (GtkOverlay* overlay = Overlay()) {
      g_signal_connect(overlay, "get-child-position",
                       G_CALLBACK(OnChildPosition), nullptr);
    }
  }
  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  plugin->channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar),
      "yoru/inappwebview_linux", FL_METHOD_CODEC(codec));
  fl_method_channel_set_method_call_handler(plugin->channel, HandleCall,
                                            nullptr, nullptr);
}
