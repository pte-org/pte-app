/// User-facing messages, labels, and brand text for the Aptis app.
///
/// Mirrors the pattern in [AppColors]: a private constructor and grouped
/// `static const` members so no widget hardcodes a string literal.
class AppStrings {
  AppStrings._();

  // --- Vocabulary / word matching (Q26 synonym) ----------------------
  /// Instructions shown above the synonym matching exercise.
  static const String vocabularyMatchInstruction =
      'Select a word from the list that has the most similar meaning to the '
      'word on the left.';

  // Temporary vocabulary sample content. Replace when questions are loaded
  // from ExamAttemptInProgress.
  static const List<String> vocabularySampleWords = [
    'study',
    'receive',
    'start',
    'talk',
    'pick',
  ];
  static const List<List<String>> vocabularySampleOptions = [
    ['read', 'write', 'learn', 'teach'],
    ['get', 'give', 'take', 'send'],
    ['begin', 'end', 'stop', 'finish'],
    ['speak', 'listen', 'whisper', 'shout'],
    ['choose', 'drop', 'leave', 'ignore'],
  ];

  // --- Definition matching (Q27) -------------------------------------
  static const String definitionMatchInstruction =
      'Complete each definition using a word from the list. Use each word once '
      'only. You will not need five of the words.';

  // Temporary sample content. Replace when questions are loaded.
  static const List<String> definitionPrompts = [
    'To get better at something is to',
    'To choose something is to',
    'To get money from work is to',
    'To help someone is to',
    'To give someone a job is to',
  ];
  static const List<List<String>> definitionOptions = [
    ['improve', 'reduce', 'delay', 'ignore'],
    ['select', 'reject', 'lose', 'copy'],
    ['earn', 'spend', 'owe', 'save'],
    ['assist', 'blame', 'avoid', 'follow'],
    ['employ', 'fire', 'train', 'meet'],
  ];

  // --- Collocation matching (Q30) ------------------------------------
  static const String collocationInstruction =
      'Select a word from the list that is most often used with the word on '
      'the left. Use each word once only. You will not need five of the words.';

  // Temporary sample content. Replace when questions are loaded.
  static const List<String> collocationWords = [
    'reduced',
    'sentimental',
    'immediate',
    'white-water',
    'semi-precious',
  ];
  static const List<List<String>> collocationOptions = [
    ['price', 'size', 'weight', 'colour'],
    ['value', 'price', 'number', 'weight'],
    ['family', 'friend', 'people', 'group'],
    ['rafting', 'swimming', 'diving', 'sailing'],
    ['stone', 'metal', 'wood', 'glass'],
  ];

  // --- Grammar / multiple choice -------------------------------------
  /// Label above the pre-answered example item in the grammar MCQ screen.
  static const String grammarExampleLabel = 'Example';

  // Temporary grammar sample content. Replace when questions are loaded
  // from ExamAttemptInProgress.
  static const String grammarExamplePrompt =
      'I ________ drunk three cups of coffee this morning';
  static const List<String> grammarExampleOptions = ['Have', 'Am', 'Are'];
  static const String grammarQuestionPrompt =
      'My best friend, ________ is from Australia, is coming to visit me '
      'next week.';
  static const List<String> grammarQuestionOptions = ['who', 'which', 'that'];

  // --- Sentence completion -------------------------------------------
  static const String sentenceCompletionInstruction =
      'Finish each sentence using a word from the list. Use each word once '
      'only. You will not need five of the words.';

  // Temporary sentence-completion sample content. The blank sits between the
  // matching `pre`/`post` entry; `post` may be empty. Replace when questions
  // are loaded from ExamAttemptInProgress.
  static const List<String> sentenceCompletionPre = [
    'After it rained, the path was all ',
    'It is important to create an eye-catching ',
    'My cousin spent a fortune on her wedding. It was incredibly ',
    'Teachers should always give ',
    'Doing voluntary work is really ',
  ];
  static const List<String> sentenceCompletionPost = [
    ' and my trainers got dirty.',
    ' when starting a business.',
    '',
    ' to their students so they know how to improve.',
    ' because it makes you feel like you are making a difference.',
  ];
  static const List<String> sentenceCompletionWordBank = [
    'muddy',
    'brand',
    'lavish',
    'feedback',
    'rewarding',
    'slippery',
    'expense',
    'comment',
    'generous',
    'dusty',
  ];

  // --- Reading: gap-fill message (R1) --------------------------------
  static const String readingGapFillInstruction =
      'Choose the word that fits in the gap. the first one is done for you.';
  static const String readingMessageGreeting = 'Hey Lewis,';
  static const String readingMessageSignOff = 'Love,';
  static const String readingMessageSignName = 'Helen';

  // Temporary sample content. Replace when questions are loaded.
  static const List<String> readingMessagePre = [
    'Can you ',
    'I have a work meeting ',
    "I won't be home on time to ",
    'Do you want to ',
    'We could also eat ',
    'Let me ',
  ];
  static const List<String> readingMessagePost = [
    ' me a favour?.',
    ' 6:00pm.',
    ' dinner.',
    ' pizza for dinner?',
    ' at that new Greek restaurant.',
    ' what you decide.',
  ];
  static const List<List<String>> readingMessageOptions = [
    ['do', 'make', 'give', 'take'],
    ['at', 'on', 'in', 'by'],
    ['have', 'make', 'cook', 'get'],
    ['order', 'buy', 'get', 'cook'],
    ['out', 'in', 'food', 'dinner'],
    ['know', 'tell', 'see', 'say'],
  ];
  static const String readingMessageFirstAnswer = 'do';

  // --- Reading: heading match (R4) -----------------------------------
  static const String readingHeadingInstruction =
      'Read the passage quickly. Choose a heading for each numbered paragraph '
      '(1-7) from the drop-down box. There is one more heading than you need.';
  static const String readingPassageTitle = 'Mission To Mars';

  // Temporary sample content. Replace when questions are loaded.
  static const List<String> readingPassageParagraphs = [
    '1. On 3rd June 2010 an international crew of six astronauts entered a '
        'space ship and prepared themselves for a 520 day voyage to the planet '
        'Mars and back.',
    '2. Emerging from the spaceship after an exhausting 520 days, Russian '
        'commander Alexei Sitev declared the mission finally over.',
    '3. Mars 500 was, in fact, a simulation exercise. The astronauts never '
        'even left the ground and their space ship was a specially constructed '
        'working model situated in a warehouse in Moscow.',
    '4. The aims of the mission were to see how well humans could cope with '
        'the confinement and stress involved in extended interplanetary '
        'travel.',
    '5. Throughout the study, the crew followed a strict daily routine of '
        'experiments, exercise and maintenance work.',
    '6. Communication with the outside world carried a realistic delay, '
        'adding to the sense of isolation the crew experienced.',
    '7. The success of Mars 500 offered valuable lessons for the real crewed '
        'missions that space agencies still hope to launch.',
  ];
  static const List<String> readingHeadingOptions = [
    'A simulated journey',
    'The crew emerges',
    'Life inside the module',
    'The purpose of the study',
    'A strict daily routine',
    'Isolation and delay',
    'Lessons for the future',
    'International cooperation',
  ];

  // --- Reading: sentence ordering (R2) -------------------------------
  static const String readingOrderingInstruction =
      'The sentences below are from a biography. Order the sentences to make a '
      'story. The first sentence of the story is an example.';
  static const String readingOrderingExample =
      'Audrey Hepburn was born in Brussels in 1929.';

  // Temporary sample content. Replace when questions are loaded.
  static const List<String> readingOrderingSentences = [
    'Following her successful acting career, she dedicated herself to '
        'humanitarian work.',
    'Although her career had begun in London, she became famous when she '
        'starred in the American film, "Roman Holiday".',
    'After travelling to many countries to help poor children, she was '
        'diagnosed with cancer and passed away.',
    'As a child, she grew up in Belgium, England and the Netherlands.',
    'As a result, she won an Oscar, a BAFTA, and Golden Globe for the same '
        'performance.',
  ];

  // --- Reading: word-bank gap-fill (R3) ------------------------------
  static const String readingWordBankInstruction =
      'Read the text and complete each gap with a word from the list at the '
      'bottom of the page.';
  static const String readingWordBankTitle = 'Galileo Galilei';
  static const int readingWordBankGapCount = 8;
  static const String readingWordBankFirstAnswer = 'referred';

  // Text either side of each gap: length == gap count + 1. Replace when
  // questions are loaded.
  static const List<String> readingWordBankSegments = [
    'Often ',
    " to as 'the father of modern physics', Galileo Galilei was born in Pisa, "
        'Italy, in 1564, the son of a mathematician and musician. He attended '
        'university in Pisa but had to leave due to a ',
    ' of funds, and later taught sciences at the University of Padua. It was ',
    ' his time there that Galileo did a large number of ',
    ', the most famous involving dropping balls of different sizes from ',
    ' heights to determine the law of acceleration of falling bodies. Indeed, '
        'he is credited with several important scientific ',
    ', and is still considered a great genius. Unfortunately, however, he died '
        'in prison in 1642, whilst ',
    ' a life sentence for publishing works suggesting that the earth moved ',
    ' the sun – something that went against accepted thinking at the time.',
  ];
  static const List<String> readingWordBankTiles = [
    'various',
    'discoveries',
    'taking',
    'lot',
    'around',
    'during',
    'lack',
    'at',
    'serving',
    'experiments',
  ];

  // --- Exam app bar --------------------------------------------------
  static const String screenLabel = 'Screen ';
  static const String screenOf = ' of ';
  static const String timerMins = 'Mins';
  static const String timerSecs = 'Secs';

  /// Two-line label rendered inside the circular toggle button.
  static const String hideTime = 'Hide\ntime';
  static const String showTime = 'Show\ntime';

  // --- Brand text (British Council / Aptis lockup) -------------------
  static const String brandBritishCouncil = 'BRITISH\nCOUNCIL';
  static const String brandAptis = 'Aptis';
  static const String brandAptisTagline = 'Forward thinking\nEnglish testing';

  // --- Exam bottom bar -----------------------------------------------
  static const String back = 'Back';
  static const String flag = 'Flag';
  static const String next = 'Next';

  // --- Speaking ------------------------------------------------------
  static const String speakingPartOneLabel = 'Part One';
  static const String speakingPartTwoLabel = 'Part Two';
  static const String speakingPartThreeLabel = 'Part Three';
  static const String speakingPartFourLabel = 'Part Four';
  static const String speakingPartOneIntro =
      'Part One. In this part I am going to ask you three short questions '
      'about yourself and your interests. You will have 30 seconds to reply '
      'to each question. Begin speaking when you hear this sound.';
  static const String speakingPartTwoPrompt = 'Describe this picture.';
  static const String speakingSampleImageLabel = 'Sample image';

  static const String speakingRecording = 'RECORDING';
  static const String speakingCompleted = 'COMPLETED';
  static const String speakingClickToRecord = 'CLICK TO RECORD';
  
  static const String speakingImageA = 'Image A';
  static const String speakingImageB = 'Image B';

  static const String speakingTimerPrep = 'PREPARATION TIME';
  static const String speakingTimerRecording = 'RECORDING TIME';
  static const String speakingTimerRecordingReady = 'RECORDING TIME (READY)';
  static const String speakingTimerRecordingSpeak = 'RECORDING TIME (SPEAK NOW)';
  static const String speakingTimerCompleted = 'RECORDING COMPLETED';

  // --- Login ---------------------------------------------------------
  static const String loginCandidateTitle = 'Candidate Login';
  static const String loginCandidateSubtitle =
      'Please enter your credentials to begin the assessment.';
  static const String loginAccountLabel = 'Account';
  static const String loginAccountHint = 'Enter username';
  static const String loginPasswordLabel = 'Password';
  static const String loginPasswordHint = 'Enter password';
  static const String loginAccessKeyLabel = 'Access Key';
  static const String loginAccessKeyHint = 'Enter access key';
  static const String loginButton = 'LOGIN';
  static const String loginInternetSupport = 'Internet Support';
  static const String loginPrivacyPolicy = 'Privacy Policy';
  static const String loginTermsOfUse = 'Terms of Use';
  static const String loginCopyright = '© British Council 2024';
  static const String loginGenericError =
      'Login failed. Please check your credentials.';
  static const String loginStudentOnlyError =
      'This desktop app is for candidate accounts only.';
  static const String loginMissingAccount = 'Please enter your username.';
  static const String loginMissingPassword = 'Please enter your password.';
}
