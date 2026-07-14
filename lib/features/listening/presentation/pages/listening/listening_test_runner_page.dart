import 'dart:async';
import 'package:flutter/material.dart';
import 'package:aptis_app/features/listening/data/models/question.dart';
import 'package:aptis_app/features/listening/presentation/models/listening_answer.dart';
import 'package:aptis_app/features/listening/presentation/pages/listening/listening_multiple_choice_page.dart';
import 'package:aptis_app/features/listening/presentation/pages/listening/listening_matching_page.dart';

class ListeningTestRunnerPage extends StatefulWidget {
  const ListeningTestRunnerPage({super.key});

  @override
  State<ListeningTestRunnerPage> createState() => _ListeningTestRunnerPageState();
}

class _ListeningTestRunnerPageState extends State<ListeningTestRunnerPage> {
  // Mock questions for 4 parts
  final List<Question> _questions = [
    const Question(
      id: "q1",
      part: 1,
      questionType: "MULTIPLE_CHOICE",
      content: "What is not original?",
      options: ["Furniture", "Home", "Bicycle"],
      correctAnswers: ["Furniture"],
      assetCdnUrl: "https://aptiskey.com/audio/question1_13/audio_q1.mp3",
      maxPlayCount: 2,
    ),
    const Question(
      id: "q2",
      part: 2,
      questionType: "MATCHING",
      content: '''Four people are discussing their views on the topic above. Complete the sentences. Use each answer only once. 
You will not need two of the answers.
Speaker A [Blank 1]
Speaker B [Blank 2]
Speaker C [Blank 3]
Speaker D [Blank 4]''',
      options: [
        // Speaker A
        "Does not use commercial cleaning products", "Give away used items", "Buy environmentally friendly products", "Reuse containers for storing food", "Plant trees in the backyard", "Use solar panels for electricity",
        // Speaker B
        "Does not use commercial cleaning products", "Give away used items", "Buy environmentally friendly products", "Reuse containers for storing food", "Plant trees in the backyard", "Use solar panels for electricity",
        // Speaker C
        "Does not use commercial cleaning products", "Give away used items", "Buy environmentally friendly products", "Reuse containers for storing food", "Plant trees in the backyard", "Use solar panels for electricity",
        // Speaker D
        "Does not use commercial cleaning products", "Give away used items", "Buy environmentally friendly products", "Reuse containers for storing food", "Plant trees in the backyard", "Use solar panels for electricity"
      ],
      correctAnswers: [
        "Does not use commercial cleaning products",
        "Give away used items",
        "Buy environmentally friendly products",
        "Reuse containers for storing food"
      ],
      assetCdnUrl: "https://aptiskey.com/audio/question14/audio_q1.mp3",
      maxPlayCount: 2,
    ),
    const Question(
      id: "q3",
      part: 3,
      questionType: "MULTIPLE_CHOICE",
      content: "Why hasn't he gone to college?\nWhy did he decide to travel for 2 years?",
      options: [
        "He wasn't ready to start higher education",
        "He couldn't afford the tuition fees.",
        "He didn't get good enough grades",
        "To gain life experience.",
        "To avoid studying.",
        "To travelling."
      ],
      correctAnswers: [
        "He wasn't ready to start higher education",
        "To gain life experience."
      ],
      assetCdnUrl: "https://aptiskey.com/audio/question16/1_study_break.mp3",
      maxPlayCount: 2,
    ),
    const Question(
      id: "q4",
      part: 4,
      questionType: "MATCHING",
      content: '''Listen to a man and a woman discussing changes in the workplace. Read the opinions below and decide whose opinion matches the statements, the man, the woman, or both.
Who expresses which opinion?
1. Continuity is important when planning a career [Blank 1]
2. Job security cannot be guaranteed [Blank 2]
3. Job satisfaction is important for motivator [Blank 3]
4. Technological improvement is good for the economy [Blank 4]''',
      options: [
        "Man", "Woman", "Both",
        "Man", "Woman", "Both",
        "Man", "Woman", "Both",
        "Man", "Woman", "Both",
      ],
      correctAnswers: ["Man", "Woman", "Both", "Man"],
      assetCdnUrl: "https://aptiskey.com/audio/question15/audio_q1.mp3",
      maxPlayCount: 2,
    ),
  ];

  int _currentIndex = 0;
  final Map<String, Answer> _answers = {};
  
  // Timer State
  Timer? _timer;
  Duration _timeRemaining = const Duration(minutes: 30);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining -= const Duration(seconds: 1);
        });
      } else {
        _timer?.cancel();
        _handleTimeUp();
      }
    });
  }
  
  void _handleTimeUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Time is up! End of Listening Test')),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _handleNext() {
    if (_currentIndex < _questions.length - 1) {
      setState(() {
        _currentIndex++;
      });
    } else {
      // End of test logic here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End of Listening Test')),
      );
    }
  }

  void _handleBack() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentQuestion = _questions[_currentIndex];
    final savedAnswer = _answers[currentQuestion.id];

    if (currentQuestion.part == 1 || currentQuestion.part == 3) {
      return ListeningMultipleChoicePage(
        key: ValueKey(currentQuestion.id),
        questionData: currentQuestion,
        currentScreen: _currentIndex + 1,
        totalScreens: _questions.length,
        timeRemaining: _timeRemaining,
        onNext: _handleNext,
        onBack: _handleBack,
        initialAnswer: savedAnswer is MultipleChoiceAnswer ? savedAnswer : null,
        onAnswerChanged: (answer) {
          _answers[currentQuestion.id] = answer;
        },
      );
    } else {
      return ListeningMatchingPage(
        key: ValueKey(currentQuestion.id),
        questionData: currentQuestion,
        currentScreen: _currentIndex + 1,
        totalScreens: _questions.length,
        timeRemaining: _timeRemaining,
        onNext: _handleNext,
        onBack: _handleBack,
        initialAnswer: savedAnswer is MatchingAnswer ? savedAnswer : null,
        onAnswerChanged: (answer) {
          _answers[currentQuestion.id] = answer;
        },
      );
    }
  }
}
