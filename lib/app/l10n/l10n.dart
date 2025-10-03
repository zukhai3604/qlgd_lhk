import 'package:flutter/widgets.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// A BuildContext extension to provide easy access to the AppLocalizations object.
// Usage: context.l10n.yourString

export 'package:flutter_gen/gen_l10n/app_localizations.dart';

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this)!;
}
