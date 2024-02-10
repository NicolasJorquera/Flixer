// import 'package:flixer/src/apiFunctions/discoverMovies.dart';
// import 'package:flixer/src/widgets/categoryRow.dart';
// import 'package:flutter/material.dart';
// import 'package:flixer/global/variables.dart';

// class MoviesPage extends StatefulWidget {
//   const MoviesPage({super.key});

//   @override
//   State<MoviesPage> createState() => _MoviesPageState();
// }

// class _MoviesPageState extends State<MoviesPage> {
//   @override
//   Widget build(BuildContext context) {
//     return RefreshIndicator(
//         onRefresh: () {
//           getDiscovermovies();
//           setState(() {});
//           return Future.delayed(const Duration(seconds: 4));
//         },
//         child: Container(
//             color: Theme.of(context).colorScheme.background,
//             child: ListView.separated(
//                 itemBuilder: (BuildContext context, int index) {
//                   return Padding(
//                     padding: EdgeInsets.fromLTRB(0, index == 0 ? 5 : 0, 0,
//                         index == movies.value.length - 1 ? 10 : 0),
//                     child: CategoryRow(
//                       list: movies.value[index],
//                     ),
//                   );
//                 },
//                 separatorBuilder: (BuildContext context, int index) => Divider(
//                       color: Theme.of(context).colorScheme.secondary,
//                     ),
//                 itemCount: movies.value.length)));
//   }
// }
