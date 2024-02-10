// import 'package:flixer/src/apiFunctions/discoverSeries.dart';
// import 'package:flixer/src/widgets/categoryRow.dart';
// import 'package:flutter/material.dart';

// class SeriesPage extends StatefulWidget {
//   const SeriesPage({super.key});

//   @override
//   State<SeriesPage> createState() => _SeriesPageState();
// }

// class _SeriesPageState extends State<SeriesPage> {
//   late Future<List> movies;

//   @override
//   void initState() {
//     super.initState();
//     // this should not be done in build method.
//     movies = getDiscoverSeries();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: Theme.of(context).colorScheme.background,
//       child: FutureBuilder(
//           future: movies,
//           builder: (context, snapshot) {
//             return snapshot.hasData
//                 ? ListView.separated(
//                     itemBuilder: (BuildContext context, int index) {
//                       return CategoryRow(
//                         genreList: snapshot.data![index],
//                       );
//                     },
//                     separatorBuilder: (BuildContext context, int index) =>
//                         Divider(
//                           color: Theme.of(context).colorScheme.secondary,
//                         ),
//                     itemCount: snapshot.data!.length)
//                 : Center(
//                     child: CircularProgressIndicator(),
//                   );
//           }),
//     );
//   }
// }
