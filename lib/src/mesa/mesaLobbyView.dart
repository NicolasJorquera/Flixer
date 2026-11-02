import 'package:flixer/global/strings.dart';
import 'package:flixer/src/mesa/mesaModels.dart';
import 'package:flixer/src/mesa/mesaSession.dart';
import 'package:flixer/src/mesa/mesaVoteView.dart';
import 'package:flixer/src/mesa/mesaWidgets.dart';
import 'package:flixer/src/widgets/statusViews.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Waiting room of an online table: shows the code and who joined. The host
/// starts the vote and everyone moves on together.
class MesaLobbyView extends StatefulWidget {
  final MesaSession session;
  const MesaLobbyView({super.key, required this.session});

  @override
  State<MesaLobbyView> createState() => _MesaLobbyViewState();
}

class _MesaLobbyViewState extends State<MesaLobbyView> {
  bool _left = false;

  @override
  void initState() {
    super.initState();
    widget.session.state.addListener(onChange);
  }

  @override
  void dispose() {
    widget.session.state.removeListener(onChange);
    super.dispose();
  }

  void onChange() {
    final state = widget.session.state.value;
    if (_left || state == null || !mounted) return;
    if (widget.session.closed) {
      _left = true;
      showMessage(context, tr('mesaClosed'));
      widget.session.leave();
      Navigator.popUntil(context, (route) => route.isFirst);
    } else if (state.status != MesaStatus.lobby) {
      _left = true;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) => MesaVoteView(session: widget.session)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) confirmLeave(context, widget.session);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.background,
          elevation: 0,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.onBackground),
          title: Text(tr('mesa'),
              style: Theme.of(context).textTheme.displayMedium),
        ),
        body: ValueListenableBuilder<MesaState?>(
          valueListenable: widget.session.state,
          builder: (context, state, _) {
            if (state == null) return const LoadingView();
            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(tr('shareCode'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall),
                const SizedBox(height: 10),
                Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: state.code));
                      showMessage(context, tr('copied'));
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 25, vertical: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceTint,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.code,
                            semanticsLabel: state.code.split('').join(' '),
                            style: TextStyle(
                                fontSize: 36,
                                letterSpacing: 8,
                                fontWeight: FontWeight.bold,
                                color:
                                    Theme.of(context).colorScheme.onBackground),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.copy,
                              color: Theme.of(context).colorScheme.secondary),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                sectionTitle(context,
                    '${tr('inTable')} (${state.members.length}/${FirebaseMesaSession.maxMembers})'),
                const SizedBox(height: 8),
                for (final member in state.members)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceTint,
                      child: Text(member.name.characters.first.toUpperCase(),
                          style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onBackground)),
                    ),
                    title: Text(
                      member.id == '0'
                          ? '${member.name} (${tr('host')})'
                          : member.name,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                  ),
                const SizedBox(height: 25),
                widget.session.isHost
                    ? MesaButton(
                        label: tr('startVoting'),
                        icon: Icons.play_arrow,
                        onPressed: () => widget.session.start(),
                      )
                    : Text(tr('waitingHost'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary)),
              ],
            );
          },
        ),
      ),
    );
  }
}
