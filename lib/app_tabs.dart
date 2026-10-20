import 'package:flutter/material.dart';

import 'theme.dart';

/// The app's top-level destinations, in the website's navigation order
/// (content/navigation.json): Home, System Hub, Training Hub, ATO Package
/// Builder Hub, Community & Careers Hub, My Account. [title] is the website's
/// name; [label] is the short form that fits a phone's tab bar.
enum AppTab {
  home('Home', 'Home', Icons.home_outlined, Icons.home_rounded),
  systemHub('Systems', 'System Hub', Icons.hub_outlined, Icons.hub),
  training('Training', 'Training Hub', Icons.auto_stories_outlined,
      Icons.auto_stories),
  ato('ATO', 'ATO Package Builder Hub', Icons.verified_user_outlined,
      Icons.verified_user),
  community('Community', 'Community & Careers Hub', Icons.groups_outlined,
      Icons.groups),
  account('Account', 'My Account', Icons.person_outline, Icons.person);

  const AppTab(this.label, this.title, this.icon, this.selectedIcon);
  final String label, title;
  final IconData icon, selectedIcon;
}

/// Six destinations are one more than a standard phone tab bar holds, so this
/// bar keeps every label on one line at any text size: labels scale up to
/// 1.3× and then shorten, and each tab announces its full hub name.
class AppTabBar extends StatelessWidget {
  const AppTabBar(
      {super.key, required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.3,
        // Its own transparent Material, so ink shows above the bar's surface.
        child: Material(
          type: MaterialType.transparency,
          child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
    final color = selected ? SbdColors.cyan : SbdColors.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: tab.title,
      excludeSemantics: true,
      child: Tooltip(
        message: tab.title,
        excludeFromSemantics: true,
        child: InkWell(
          key: ValueKey('tab-${tab.name}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 160),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: selected
                          ? SbdColors.cyan.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(selected ? tab.selectedIcon : tab.icon,
                        size: 22, color: color),
                  ),
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
