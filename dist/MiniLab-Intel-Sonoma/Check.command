#!/bin/zsh
cd "${0:A:h}"
task_bundle="$PWD/MiniLab Piano Intel Sonoma.app"
{
  echo "MiniLab Piano · Intel / Sonoma diagnostics"
  sw_vers
  uname -m
  echo "Executable:"
  file "$task_bundle/Contents/MacOS/MiniLabPiano"
  ls -l "$task_bundle/Contents/MacOS/MiniLabPiano"
  echo "Code signature:"
  codesign --verify --deep --strict --verbose=2 "$task_bundle"
  echo "Signature result: $?"
  echo "macOS launch assessment:"
  spctl --assess --type execute --verbose=4 "$task_bundle"
  echo "Assessment result: $?"
  echo "Built-in tests and dynamic loader:"
  "$task_bundle/Contents/MacOS/MiniLabPiano" --self-test
  echo "Test result: $?"
} 2>&1 | tee "$PWD/diagnostics.txt"
echo "Готово. Результат сохранён рядом: diagnostics.txt"
read -r "task_reply?Нажмите Enter, чтобы закрыть окно. "
