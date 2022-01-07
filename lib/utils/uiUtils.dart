import 'package:flutter/cupertino.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class UIUtils {
  static void showInvalidActionAlert(BuildContext context, String action) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'common');
    showCupertinoDialog(
        context: context,
        builder: (_) {
          return CupertinoAlertDialog(
            title: Text(action),
            content: Text(dic!['action.disable']!),
            actions: [
              CupertinoButton(
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
