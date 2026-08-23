/// Sample content for Summarize Written Text and Write Essay used during
/// development before the writing backend lands. Mimics the "replace when
/// questions load" TODO convention used by `core_test` and `reading`.
library;

const String kSummarizeWrittenTextInstruction =
    'Read the passage below and summarize it in one sentence (5 to 75 words).';

const String kSummarizeWrittenTextPassage = '''
In the late 19th century, the rapid expansion of urban centres across Europe created
unprecedented public-health challenges. Crowded tenements, contaminated water supplies,
and the absence of organised waste collection allowed cholera, typhus, and tuberculosis
to spread quickly through working-class districts. Local authorities, often reluctant to
intervene in what they regarded as private housing matters, responded slowly even as
death rates climbed. A handful of reformers, most famously Edwin Chadwick in Britain,
argued that sanitation was a collective responsibility: clean water, sewerage, and
ventilated streets would benefit everyone, rich and poor alike. Their reports persuaded
parliaments to pass sweeping public-health acts that funded municipal waterworks and
sewage systems, laying the foundation for the modern expectation that governments
take an active role in protecting the health of their citizens.
''';

const String kSummarizeWrittenTextMinWords = '5';
const String kSummarizeWrittenTextMaxWords = '75';
const int kSummarizeWrittenTextDurationSeconds = 600; // 10 minutes.

const String kWriteEssayInstruction =
    'You will have 20 minutes to plan, write and revise an essay about the topic below.';

const String kWriteEssayPrompt = '''
Some people believe that the most important function of universities is to prepare
students for their future careers. Others argue that universities should focus
primarily on broad personal development rather than vocational training.

Discuss both views and give your own opinion.
''';

const String kWriteEssayMinWords = '200';
const String kWriteEssayMaxWords = '300';
const int kWriteEssayDurationSeconds = 1200; // 20 minutes.
