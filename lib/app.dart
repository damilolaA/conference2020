import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:conferenceapp/agenda/bloc/bloc.dart';
import 'package:conferenceapp/agenda/helpers/agenda_layout_helper.dart';
import 'package:conferenceapp/agenda/repository/talks_repository.dart';
import 'package:conferenceapp/analytics.dart';
import 'package:conferenceapp/main_page/home_page.dart';
import 'package:conferenceapp/profile/auth_repository.dart';
import 'package:conferenceapp/profile/favorites_repository.dart';
import 'package:conferenceapp/profile/user_repository.dart';
import 'package:conferenceapp/ticket/bloc/bloc.dart';
import 'package:conferenceapp/ticket/repository/ticket_repository.dart';
import 'package:dynamic_theme/dynamic_theme.dart';
import 'package:firebase_analytics/observer.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key key, this.title}) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    return DynamicTheme(
      defaultBrightness: Brightness.light,
      data: (brightness) => ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: brightness == Brightness.light
            ? Colors.grey[100]
            : Colors.grey[850],
        accentColor: brightness == Brightness.light
            ? Colors.orange[300]
            : Colors.orange[800],
        toggleableActiveColor: Colors.orange[800],
        dividerColor:
            brightness == Brightness.light ? Colors.white : Colors.white54,
        brightness: brightness,
        fontFamily: 'PTSans',
        bottomAppBarTheme: Theme.of(context).bottomAppBarTheme.copyWith(
              elevation: 0,
            ),
        pageTransitionsTheme: PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      themedWidgetBuilder: (context, theme) {
        return RepositoryProviders(
          child: BlocProviders(
            child: ChangeNotifierProviders(
              child: MaterialApp(
                title: title,
                theme: theme,
                navigatorObservers: [
                  FirebaseAnalyticsObserver(analytics: analytics),
                ],
                home: HomePage(title: title),
              ),
            ),
          ),
        );
      },
    );
  }
}

class BlocProviders extends StatelessWidget {
  const BlocProviders({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AgendaBloc>(
          builder: (BuildContext context) =>
              AgendaBloc(RepositoryProvider.of<TalkRepository>(context))
                ..add(InitAgenda()),
        ),
        BlocProvider<TicketBloc>(
          builder: (BuildContext context) =>
              TicketBloc(RepositoryProvider.of<TicketRepository>(context))
                ..add(FetchTicket()),
        ),
      ],
      child: child,
    );
  }
}

class RepositoryProviders extends StatelessWidget {
  final Widget child;

  const RepositoryProviders({Key key, @required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider(
      builder: (_) => AuthRepository(FirebaseAuth.instance),
      child: RepositoryProvider(
        builder: _userRepositoryBuilder,
        child: RepositoryProvider<TalkRepository>(
          builder: (_) => FirestoreTalkRepository(),
          child: RepositoryProvider(
            builder: _favoritesRepositoryBuilder,
            child: RepositoryProvider(
              builder: _ticketRepositoryBuilder,
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  UserRepository _userRepositoryBuilder(BuildContext context) {
    return UserRepository(
      RepositoryProvider.of<AuthRepository>(context),
      Firestore.instance,
    );
  }

  FavoritesRepository _favoritesRepositoryBuilder(BuildContext context) {
    return FavoritesRepository(
      RepositoryProvider.of<TalkRepository>(context),
      RepositoryProvider.of<UserRepository>(context),
    );
  }

  TicketRepository _ticketRepositoryBuilder(BuildContext context) {
    return TicketRepository(
      RepositoryProvider.of<UserRepository>(context),
    );
  }
}

class ChangeNotifierProviders extends StatelessWidget {
  const ChangeNotifierProviders({Key key, this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AgendaLayoutHelper>(
      builder: (_) => AgendaLayoutHelper(false),
      child: child,
    );
  }
}
