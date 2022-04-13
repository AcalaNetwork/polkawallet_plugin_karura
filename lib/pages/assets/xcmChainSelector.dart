import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:polkawallet_plugin_karura/common/constants/base.dart';
import 'package:polkawallet_plugin_karura/common/constants/index.dart';
import 'package:polkawallet_plugin_karura/polkawallet_plugin_karura.dart';
import 'package:polkawallet_plugin_karura/utils/i18n/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/currencyWithIcon.dart';
import 'package:polkawallet_ui/components/tokenIcon.dart';
import 'package:polkawallet_ui/components/v3/bottomSheetContainer.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';

class XcmChainSelector extends StatefulWidget {
  XcmChainSelector(
    this.plugin, {
    required this.fromChains,
    required this.toChains,
    required this.crossChainIcons,
    required this.onChanged,
  });
  final PluginKarura plugin;
  final List<String> fromChains;
  final List<String> toChains;
  final Map<String, Widget> crossChainIcons;
  final Function(List<String>) onChanged;
  @override
  _XcmChainSelectorState createState() => _XcmChainSelectorState();
}

class _XcmChainSelectorState extends State<XcmChainSelector> {
  String _from = plugin_name_karura;
  String _to = relay_chain_name;

  void _switch() {
    final from = _from;
    if (from != plugin_name_karura) {
      setState(() {
        _from = plugin_name_karura;
        _to = from;
      });
    } else {
      setState(() {
        _from = widget.fromChains[0];
        _to = from;
      });
    }

    widget.onChanged([_from, _to]);
  }

  Future<void> _selectChain(int index, Map<String, Widget> crossChainIcons,
      List<String> options) async {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;
    final current = index == 0 ? _from : _to;

    showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return BottomSheetContainer(
          title: Text(dic['cross.chain.select']!),
          content: ChainSelector(
            widget.plugin,
            selected: current,
            options: options,
            crossChainIcons: crossChainIcons,
            onSelect: (chain) {
              if (chain != current) {
                if (chain != plugin_name_karura) {
                  setState(() {
                    if (current != plugin_name_karura) {
                      if (index == 0) {
                        _from = chain;
                      } else {
                        _to = chain;
                      }
                    } else {
                      _from = index == 0 ? chain : plugin_name_karura;
                      _to = index == 1 ? chain : plugin_name_karura;
                    }
                  });
                  widget.onChanged([_from, _to]);
                } else {
                  _switch();
                }
              }

              Navigator.of(context).pop();
            },
          ),
        );
      },
      context: context,
    );
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance!.addPostFrameCallback((_) {
      setState(() {
        _to = widget.toChains[0];
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context)!.getDic(i18n_full_dic_karura, 'acala')!;

    final crossChainIcons = Map<String, Widget>.from(
        widget.plugin.store!.assets.crossChainIcons.map((k, v) => MapEntry(
            k.toUpperCase(),
            (v as String).contains('.svg')
                ? SvgPicture.network(v)
                : Image.network(v))));

    final isFromKar = _from == 'karura';

    final labelStyle = Theme.of(context).textTheme.headline4;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dic['cross.chain.from'] ?? '', style: labelStyle),
              GestureDetector(
                child: RoundedCard(
                  padding: EdgeInsets.fromLTRB(8, 10, 0, 8),
                  margin: EdgeInsets.only(bottom: 8),
                  child: CurrencyWithIcon(
                    (_from.length > 8 ? '${_from.substring(0, 8)}...' : _from)
                        .toUpperCase(),
                    TokenIcon(_from, crossChainIcons, size: 28),
                    textStyle: TextStyle(fontSize: 14),
                    trailing: widget.fromChains.length == 0
                        ? null
                        : Icon(Icons.keyboard_arrow_down_rounded,
                            color: Theme.of(context).unselectedWidgetColor),
                  ),
                ),
                onTap: widget.fromChains.length == 0
                    ? null
                    : () => _selectChain(0, crossChainIcons,
                        [plugin_name_karura, ...widget.fromChains]),
              )
            ],
          ),
        ),
        Expanded(
          flex: 0,
          child: GestureDetector(
            child: Container(
              padding: EdgeInsets.fromLTRB(8, 14, 8, 20),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: Theme.of(context).toggleableActiveColor,
              ),
            ),
            onTap: widget.fromChains.length > 0 ? _switch : null,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(dic['cross.chain'] ?? '', style: labelStyle),
              GestureDetector(
                child: RoundedCard(
                  padding: EdgeInsets.fromLTRB(8, 10, 0, 8),
                  margin: EdgeInsets.only(bottom: 8),
                  child: CurrencyWithIcon(
                    (_to.length > 8 ? '${_to.substring(0, 8)}...' : _to)
                        .toUpperCase(),
                    TokenIcon(_to, crossChainIcons, size: 28),
                    textStyle: TextStyle(fontSize: 14),
                    trailing: widget.toChains.length == 1 &&
                            widget.fromChains.length == 0
                        ? null
                        : Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Theme.of(context).unselectedWidgetColor,
                          ),
                  ),
                ),
                onTap:
                    widget.toChains.length == 1 && widget.fromChains.length == 0
                        ? null
                        : () => _selectChain(
                            1,
                            crossChainIcons,
                            widget.fromChains.length > 0
                                ? [plugin_name_karura, ...widget.toChains]
                                : widget.toChains),
              )
            ],
          ),
        )
      ],
    );
  }
}

class ChainSelector extends StatelessWidget {
  ChainSelector(this.plugin,
      {required this.options,
      required this.crossChainIcons,
      required this.selected,
      required this.onSelect});
  final PluginKarura plugin;
  final List<String> options;
  final Map<String, Widget> crossChainIcons;
  final String selected;
  final Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: options.map((i) {
        return ListTile(
          selected: i == selected,
          title: CurrencyWithIcon(
            i.toUpperCase(),
            TokenIcon(i, crossChainIcons),
            textStyle: Theme.of(context).textTheme.headline4,
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 18,
            color: Theme.of(context).unselectedWidgetColor,
          ),
          onTap: () {
            onSelect(i);
          },
        );
      }).toList(),
    );
  }
}
