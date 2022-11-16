import 'package:country_coder/country_coder.dart';
import 'package:every_door/constants.dart';
import 'package:every_door/models/amenity.dart';
import 'package:every_door/providers/editor_settings.dart';
import 'package:flutter/material.dart';
import 'package:every_door/models/field.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PhonePresetField extends PresetField {
  PhonePresetField(
      {required String key,
      required String label,
      FieldPrerequisite? prerequisite})
      : super(
            key: key,
            label: label,
            icon: Icons.phone,
            prerequisite: prerequisite);

  @override
  Widget buildWidget(OsmChange element) => PhoneInputField(this, element);

  @override
  bool hasRelevantKey(Map<String, String> tags) =>
      tags.containsKey('phone') || tags.containsKey('contact:phone');
}

class PhoneInputField extends ConsumerStatefulWidget {
  final PhonePresetField field;
  final OsmChange element;

  const PhoneInputField(this.field, this.element);

  @override
  ConsumerState createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends ConsumerState<PhoneInputField> {
  late final TextEditingController _controller;
  late final FocusNode _focus;
  late final List<String> numbers;
  late final String? countryIso;
  late final String phoneTag;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focus = FocusNode();
    _focus.addListener(() {
      if (!_focus.hasFocus) {
        submitPhone(_controller.text);
      }
    });

    numbers = (widget.element.getContact('phone') ?? '')
        .split(';')
        .map((e) => e.trim())
        .where((element) => element.isNotEmpty)
        .toList();

    countryIso = CountryCoder.instance.iso1A2Code(
      lat: widget.element.location.latitude,
      lon: widget.element.location.longitude,
    );

    phoneTag = ref.read(editorSettingsProvider).preferContact
        ? 'contact:phone'
        : 'phone';
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String? format(String value) {
    if (value.length < 4) return null;
    final kDigits = '0123456789'.split('');
    String digits = value.characters.where((p0) => kDigits.contains(p0)).string;
    try {
      if (value.startsWith('+') || digits.length >= 11) {
        final res = PhoneNumber.fromRaw('+$digits');
        return res.validate()
            ? '+${res.countryCode} ${res.getFormattedNsn()}'
            : null;
      }
      final res = countryIso != null
          ? PhoneNumber.fromIsoCode(countryIso!, value)
          : PhoneNumber.fromRaw(value);
      if (!res.validate()) return null;
      if (!value.contains('-')) {
        value = res.getFormattedNsn();
      }
      return '+${res.countryCode} ${res.getFormattedNsn()}';
    } on PhoneNumberException {
      return null;
    }
  }

  bool submitPhone(String value) {
    value = value.trim();
    if (value.length < 4) return false;
    String phone = format(value) ?? value;
    _controller.clear();
    if (numbers.contains(phone)) return true;
    setState(() {
      numbers.add(phone);
      widget.element.setContact(phoneTag, numbers.join('; '));
    });
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: TextFormField(
            controller: _controller,
            focusNode: _focus,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              fillColor: Theme.of(context).colorScheme.primary.withAlpha(20),
              labelText: widget.field.label,
              errorStyle: TextStyle(color: Theme.of(context).errorColor),
              focusedErrorBorder:
                  UnderlineInputBorder(borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2.0)),
              suffixIcon: GestureDetector(
                child: Icon(Icons.done),
                onTap: () {
                  if (submitPhone(_controller.text)) _focus.unfocus();
                },
              ),
            ),
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (value) => value != null &&
                    value.isNotEmpty &&
                    format(value.trim()) == null
                ? loc.fieldPhoneWrong
                : null,
            onFieldSubmitted: submitPhone,
          ),
        ),
        for (final number in numbers)
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(6.0)),
                color: Theme.of(context).colorScheme.background,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: GestureDetector(
                      child: Text(number, style: TextStyle(color: Theme.of(context).primaryColor, fontSize: 16.0)),
                      onTap: () {
                        if (kFollowLinks &&
                            RegExp(r'^\+?[0-9 .-]+$').hasMatch(number)) {
                          final uri = Uri.tryParse('tel:$number');
                          if (uri != null) launchUrl(uri);
                        }
                      },
                    ),
                  ),
                  GestureDetector(
                    child: Icon(Icons.close, size: 30.0),
                    onTap: () {
                      setState(() {
                        numbers.remove(number);
                        widget.element.setContact(phoneTag, numbers.join('; '));
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
