import 'package:mobx/mobx.dart';

part 'accounts.g.dart';

class AccountsStore extends _AccountsStore with _$AccountsStore {}

abstract class _AccountsStore with Store {
  @observable
  ObservableMap<String?, Map?> addressIndexMap = ObservableMap<String?, Map?>();

  @observable
  ObservableMap<String?, String?> addressIconsMap =
      ObservableMap<String?, String?>();

  @action
  void setAddressIconsMap(List list) {
    list.forEach((i) {
      addressIconsMap[i[0]] = i[1];
    });
  }

  @action
  void setAddressIndex(List list) {
    list.forEach((i) {
      addressIndexMap[i['accountId']] = i;
    });
  }
}
