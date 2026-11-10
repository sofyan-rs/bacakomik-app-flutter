# Package the Flutter release bundle without stripping its prebuilt libraries.
%global debug_package %{nil}
%global __os_install_post %{nil}

Name:           yoru
Version:        %{app_version}
Release:        1
Summary:        Reader for manga, manhwa and manhua
License:        GPL-3.0-only
URL:            https://github.com/sofyan-rs/yoru-comic-app
Source0:        %{name}-%{version}.tar.gz
BuildArch:      x86_64

# Replace RPMs published before the app was renamed to Yoru.
Provides:       bacakomik = %{version}-%{release}
Obsoletes:      bacakomik < %{version}-%{release}

# ELF dependencies are detected automatically. GStreamer's playback plugins
# are loaded at runtime and must be required explicitly.
Requires:       gtk3
Requires:       gstreamer1-plugins-base

%description
Browse, read and download manga, manhwa and manhua from extension sources,
with bookmarks, reading history and offline reading.

%prep
%setup -q

%build
# Already compiled by flutter build linux --release.

%install
mkdir -p %{buildroot}/opt/%{name} %{buildroot}%{_bindir}
cp -a bundle/. %{buildroot}/opt/%{name}/
ln -s /opt/%{name}/%{name} %{buildroot}%{_bindir}/%{name}
install -Dm644 yoru.desktop %{buildroot}%{_datadir}/applications/yoru.desktop
install -Dm644 yoru.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/yoru.png

%files
%license LICENSE
/opt/%{name}/
%{_bindir}/%{name}
%{_datadir}/applications/yoru.desktop
%{_datadir}/icons/hicolor/512x512/apps/yoru.png
