import 'package:flixer/global/strings.dart';
import 'package:flixer/src/mesa/mesaLobbyView.dart';
import 'package:flixer/src/mesa/mesaSession.dart';
import 'package:flixer/src/mesa/mesaSetupView.dart';
import 'package:flixer/src/mesa/mesaWidgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Entry to the group table: create one, join with a code or play on one
/// phone.
class MesaHomeView extends StatefulWidget {
  const MesaHomeView({super.key});

  @override
  State<MesaHomeView> createState() => _MesaHomeViewState();
}

class _MesaHomeViewState extends State<MesaHomeView> {
  final TextEditingController _name = TextEditingController();
  bool joining = false;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      _name.text = prefs.getString('mesaName') ?? '';
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get name => _name.text.trim();

  Future<void> saveName() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('mesaName', name);
  }

  bool checkName() {
    if (name.isNotEmpty) return true;
    showMessage(context, tr('yourName'));
    return false;
  }

  void openSetup({required bool online}) {
    if (!checkName()) return;
    saveName();
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MesaSetupView(online: online, name: name)));
  }

  Future<void> join() async {
    if (!checkName()) return;
    final code = await askCode();
    if (code == null || !mounted) return;
    saveName();
    setState(() {
      joining = true;
    });
    try {
      final session = await FirebaseMesaSession.join(code, name);
      if (!mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => MesaLobbyView(session: session)));
    } on MesaUnavailable catch (e) {
      if (mounted) showMessage(context, mesaErrorText(e));
    } finally {
      if (mounted) {
        setState(() {
          joining = false;
        });
      }
    }
  }

  Future<String?> askCode() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surfaceTint,
        title: Text(tr('joinMesa'),
            style: Theme.of(context).textTheme.displayMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 6,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9]')),
          ],
          style: TextStyle(
              fontSize: 24,
              letterSpacing: 6,
              color: Theme.of(context).colorScheme.onBackground),
          decoration: InputDecoration(
            hintText: 'ABC123',
            hintStyle:
                TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
          onSubmitted: (value) =>
              Navigator.pop(context, value.trim().toUpperCase()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(tr('cancel'),
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onBackground))),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, controller.text.trim().toUpperCase()),
              child: Text(tr('join'),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary))),
        ],
      ),
    ).then((code) => code == null || code.length != 6 ? null : code);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.background,
        elevation: 0,
        iconTheme:
            IconThemeData(color: Theme.of(context).colorScheme.onBackground),
        title:
            Text(tr('mesa'), style: Theme.of(context).textTheme.displayMedium),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.groups_rounded,
              size: 70, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            tr('mesaIntro'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 25),
          TextField(
            controller: _name,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(color: Theme.of(context).colorScheme.onBackground),
            decoration: InputDecoration(
              labelText: tr('yourName'),
              labelStyle:
                  TextStyle(color: Theme.of(context).colorScheme.secondary),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceTint,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          option(
            icon: Icons.add_circle_outline,
            title: tr('createMesa'),
            subtitle: tr('createMesaHint'),
            onTap: () => openSetup(online: true),
          ),
          option(
            icon: Icons.login,
            title: tr('joinMesa'),
            onTap: joining ? null : join,
            trailing: joining
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary))
                : null,
          ),
          option(
            icon: Icons.phone_android,
            title: tr('onePhone'),
            subtitle: tr('onePhoneHint'),
            onTap: () => openSetup(online: false),
          ),
        ],
      ),
    );
  }

  Widget option(
      {required IconData icon,
      required String title,
      String? subtitle,
      Widget? trailing,
      VoidCallback? onTap}) {
    return Card(
      color: Theme.of(context).colorScheme.surfaceTint,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: Theme.of(context).colorScheme.onBackground),
        title: Text(title, style: Theme.of(context).textTheme.displaySmall),
        subtitle: subtitle == null
            ? null
            : Text(subtitle,
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary)),
        trailing: trailing ??
            Icon(Icons.chevron_right,
                color: Theme.of(context).colorScheme.secondary),
      ),
    );
  }
}
