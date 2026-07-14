#!/bin/bash
# Coding Standards violation check — warning-only (exit 0)
# Surfaces common violations but does NOT block merge

WARN=0

echo "=== aptis-app Coding Standards Check ==="
echo ""

# Check hardcoded color values
HARDCODED_COLORS=$(grep -rn "Color(0x\|Color.fromARGB\|Color.fromRGBO" \
  --include="*.dart" lib/ 2>/dev/null | grep -v "//.*Color" | grep -v "app_colors.dart" | head -20)

if [ -n "$HARDCODED_COLORS" ]; then
  echo "[WARN] Hardcoded colors found (should use AppColors.*):"
  echo "$HARDCODED_COLORS"
  echo ""
  WARN=1
fi

# Check hardcoded strings in widget files
HARDCODED_STRINGS=$(grep -rn "Text('" \
  --include="*.dart" lib/features/ 2>/dev/null | grep -v "//.*Text" | grep -v "app_strings.dart" | head -20)

if [ -n "$HARDCODED_STRINGS" ]; then
  echo "[WARN] Hardcoded strings in Text() widgets (should use AppStrings.*):"
  echo "$HARDCODED_STRINGS"
  echo ""
  WARN=1
fi

# Check BuildContext usage after await without mounted check
UNMOUNTED=$(grep -rn -A2 "await " --include="*.dart" lib/ 2>/dev/null | \
  grep -B1 "context\." | grep -v "mounted" | grep "await" | head -10)

if [ -n "$UNMOUNTED" ]; then
  echo "[WARN] Potential BuildContext-after-await without mounted check:"
  echo "$UNMOUNTED"
  echo ""
  WARN=1
fi

# Check files over 300 lines
LARGE_FILES=$(find lib/ -name "*.dart" 2>/dev/null | while read f; do
  lines=$(wc -l < "$f")
  if [ "$lines" -gt 300 ]; then
    echo "$lines $f"
  fi
done | sort -rn | head -10)

if [ -n "$LARGE_FILES" ]; then
  echo "[WARN] Files exceeding 300 lines:"
  echo "$LARGE_FILES"
  echo ""
  WARN=1
fi

# Check potential secret hardcoding
SECRETS=$(grep -rn -i "apiKey\s*=\s*'\|secret\s*=\s*'\|password\s*=\s*'" \
  --include="*.dart" lib/ 2>/dev/null | grep -v "//.*=" | head -10)

if [ -n "$SECRETS" ]; then
  echo "[WARN] Potential secrets hardcoded in Dart source (should be env vars / flutter_dotenv):"
  echo "$SECRETS"
  echo ""
  WARN=1
fi

if [ "$WARN" -eq 0 ]; then
  echo "[OK] No violations detected."
fi

echo ""
echo "=== Check complete (warning-only — merge not blocked) ==="
exit 0
