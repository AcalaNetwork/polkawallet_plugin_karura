import 'package:flutter/cupertino.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/dialog.dart';

class UIUtils {
  static void showInvalidActionAlert(BuildContext context, String action) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    showCupertinoDialog(
        context: context,
        builder: (_) {
          return PolkawalletAlertDialog(
            title: Text(action),
            content: Text(dic!['action.disable']!),
            actions: [
              PolkawalletActionSheetAction(
                child: Text(dic['cancel']!),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}
