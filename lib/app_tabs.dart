import 'package:flutter/material.dart';

import 'theme.dart';

/// The app's top-level destinations, in the website's navigation order
/// (content/navigation.json since 27 October 2026): System Hub, Training Hub,
/// Community & Careers Hub, then My Account. The app keeps Home as its start
/// tab, since it has no logo to tap, and the ATO Package Builder lives in the
/// Training Hub's Tools, as on the website. [title] is the website's name;
/// [label] is the short form that fits a phone's tab bar.
enum AppTab {
  home('Home', 'Home', Icons.home_outlined, Icons.home_rounded),
  systemHub('Systems', 'System Hub', Icons.hub_outlined, Icons.hub),
  training('Training', 'Training Hub', Icons.auto_stories_outlined,
      Icons.auto_stories),
  community('Community', 'Community & Careers Hub', Icons.groups_outlined,
      Icons.groups),
  account('Account', 'My Account', Icons.person_outline, Icons.person);

  const AppTab(this.label, this.title, this.icon, this.selectedIcon);
  final String label, title;
  final IconData icon, selectedIcon;
}

/// The website's navigation (.site-header nav), as a tab bar: a bordered
/// strip with one item per hub, the current item on the blue gradient. Every
/// label stays on one line at any text size: labels scale up to 1.3× and
/// then shorten, and each tab announces its full hub name.
class AppTabBar extends StatelessWidget {
  const AppTabBar(
      {super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: SbdColors.navSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: SbdColors.navBorder),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Row(children: [
              for (final tab in AppTab.values)
                Expanded(
                    child: _TabButton(
                        tab: tab,
                        selected: tab.index == selected,
                        onTap: () => onSelected(tab.index))),
            ]),
          ),
        ),
      );
}

class _TabButton extends StatelessWidget {
  const _TabButton(
      {required this.tab, required this.selected, required this.onTap});
  final AppTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : SbdColors.navInk;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.title,
      excludeSemantics: true,
      child: Tooltip(
        message: tab.title,
        excludeFromSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: InkWell(
            key: ValueKey('tab-${tab.name}'),
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: AnimatedContainer(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              constraints: const BoxConstraints(minHeight: 52),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              decoration: BoxDecoration(
                gradient: selected ? SbdColors.navCurrent : null,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: selected
                        ? SbdColors.navCurrentBorder
                        : Colors.transparent),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(selected ? tab.selectedIcon : tab.icon,
                      size: 21, color: color),
                  const SizedBox(height: 3),
                  Text(
                    tab.label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: color,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
