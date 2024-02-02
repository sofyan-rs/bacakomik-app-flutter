import 'package:bacakomik_app/core/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:solar_icons/solar_icons.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: const Icon(SolarIconsBold.history, color: AppColors.primary),
          title: const Text('Riwayat Baca'),
          subtitle: const Text('Lihat riwayat baca komik'),
          onTap: () {},
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsBold.trashBinMinimalistic,
              color: AppColors.primary),
          title: const Text('Bersihkan Cache'),
          subtitle: const Text(
              'Bersihkan cache tanpa menghapus data favorit dan riwayat baca'),
          onTap: () {},
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading:
              const Icon(SolarIconsBold.database, color: AppColors.primary),
          title: const Text('Cadangkan Data'),
          subtitle: const Text('Cadangkan data favorit dan riwayat baca'),
          onTap: () {},
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsBold.refresh, color: AppColors.primary),
          title: const Text('Pulihkan Data'),
          subtitle: const Text('Pulihkan data favorit dan riwayat baca'),
          onTap: () {},
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsBold.moon, color: AppColors.primary),
          title: const Text('Aktifkan Mode Gelap'),
          subtitle: const Text('Ubah tampilan menjadi mode gelap'),
          contentPadding: const EdgeInsets.only(left: 15, top: 0, bottom: 0),
          trailing: DropdownButton(
            borderRadius: BorderRadius.circular(5),
            underline: Container(),
            icon: const Icon(SolarIconsOutline.altArrowDown),
            padding: const EdgeInsets.symmetric(horizontal: 15),
            value: 'Sistem',
            items: const [
              DropdownMenuItem(
                value: 'Sistem',
                child: Text('Sistem'),
              ),
              DropdownMenuItem(
                value: 'Aktif',
                child: Text('Aktif'),
              ),
              DropdownMenuItem(
                value: 'Nonaktif',
                child: Text('Nonaktif'),
              ),
            ],
            onChanged: (value) {},
          ),
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsBold.bugMinimalistic,
              color: AppColors.primary),
          title: const Text('Lapor Bug atau Saran'),
          onTap: () {},
        ),
        Divider(
          height: 1,
          color: Colors.grey.withOpacity(0.1),
        ),
        ListTile(
          leading: const Icon(SolarIconsBold.code, color: AppColors.primary),
          title: const Text('Tentang Aplikasi'),
          onTap: () {},
        ),
        Container(
          height: 15,
          color: Colors.grey.withOpacity(0.1),
        ),
      ],
    );
  }
}
