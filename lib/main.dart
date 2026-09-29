import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'services/country_service.dart';
import 'services/storage_service.dart';
import 'utils/app_theme.dart';
import 'viewmodels/game_view_model.dart';
import 'viewmodels/quiz_view_model.dart';
import 'views/quiz_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.create();
  final countryService = CountryService();

  runApp(
    CountryTriviaApp(
      storageService: storageService,
      countryService: countryService,
    ),
  );
}

class CountryTriviaApp extends StatelessWidget {
  final StorageService storageService;
  final CountryService countryService;

  const CountryTriviaApp({
    super.key,
    required this.storageService,
    required this.countryService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => GameViewModel(
            countryService: countryService,
            storageService: storageService,
          )..initialize(),
        ),
        ChangeNotifierProxyProvider<GameViewModel, QuizViewModel>(
          create: (ctx) => QuizViewModel(
            gameViewModel: ctx.read<GameViewModel>(),
          ),
          update: (ctx, gameVM, previous) =>
              previous ?? QuizViewModel(gameViewModel: gameVM),
        ),
      ],
      child: MaterialApp(
        title: 'Country Trivia',
        theme: AppTheme.lightTheme,
        home: const QuizPage(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
