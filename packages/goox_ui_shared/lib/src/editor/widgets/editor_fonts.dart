const List<String> kSystemMonospaceFonts = <String>[
  'monospace',
  'SF Mono',
  'Menlo',
  'Consolas',
  'Cascadia Code',
  'Fira Code',
  'JetBrains Mono',
  'Source Code Pro',
  'Roboto Mono',
  'Inconsolata',
  'Ubuntu Mono',
  'Courier New',
];

const List<String> kGoogleMonospaceFonts = <String>[
  'Anonymous Pro',
  'B612 Mono',
  'Cousine',
  'Cutive Mono',
  'DM Mono',
  'Fira Code',
  'Fragment Mono',
  'IBM Plex Mono',
  'Inconsolata',
  'JetBrains Mono',
  'Major Mono Display',
  'Noto Sans Mono',
  'PT Mono',
  'Red Hat Mono',
  'Roboto Mono',
  'Share Tech Mono',
  'Source Code Pro',
  'Space Mono',
  'Spline Sans Mono',
  'Ubuntu Mono',
  'Victor Mono',
];

List<String> editorFontChoices() {
  final choices = <String>{
    ...kSystemMonospaceFonts,
    ...kGoogleMonospaceFonts,
  }.toList(growable: false);
  choices.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return choices;
}

bool isGoogleMonospaceFont(String family) {
  return kGoogleMonospaceFonts.any(
    (candidate) => candidate.toLowerCase() == family.toLowerCase(),
  );
}
