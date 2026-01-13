local logic = require('bidi.logic')

local function assert_eq(expected, actual, context)
  if expected ~= actual then
    print(string.format("FAIL: %s\nExpected: '%s'\nActual:   '%s'", context, expected, actual))
    os.exit(1)
  else
    print(string.format("PASS: %s", context))
  end
end

local function run_tests()
  print("Running Bidi Tests...")

  -- Test 1: Simple Hebrew (RTL) in LTR View
  -- Logical: "ABC" (Hebrew) -> Visual: "CBA"
  -- A=א, B=ב, C=ג
  local hebrew = "אבג"
  local res = logic.process_line(hebrew, logic.Dir.LTR)
  -- "א" is first logical. "ג" is last.
  -- Visual in LTR terminal: "גבא" (reversed).
  local reversed_hebrew = "גבא"
  assert_eq(reversed_hebrew, res, "Simple Hebrew Reverse")

  -- Test 2: Hebrew English (RTL Para)
  -- Logical: "SHALOM WORLD."
  -- SHALOM (R), WORLD (L), . (N->R)
  -- Reorder: . WORLD SHALOM
  -- Render: . WORLD MOLAHS (reversed Hebrew)
  -- Visual: ". WORLD םולש"
  local mixed = "שלום WORLD."
  -- "שלום" is 4 chars.
  -- "ש" is first logical. "ם" is last.
  -- Visual should be: ".WORLD םולש" (Space is attached to Hebrew "שלום ", so reversed " םולש")
  local expected = ".WORLD םולש"
  res = logic.process_line(mixed, logic.Dir.LTR)
  assert_eq(expected, res, "Hebrew English Mixed (RTL Para)")

  -- Test 3: English Hebrew (LTR Para)
  -- "HELLO שלום"
  -- HELLO (L), SPACE (N->L), SHALOM (R)
  -- Base LTR (0).
  -- HELLO (0), SPACE (0), SHALOM (1).
  -- Reorder: HELLO SPACE SHALOM (No reorder needed, 0 then 1).
  -- Render: HELLO SPACE MOLAHS
  -- Visual: "HELLO םולש"
  mixed = "HELLO שלום"
  expected = "HELLO םולש"
  res = logic.process_line(mixed, logic.Dir.LTR)
  assert_eq(expected, res, "English Hebrew Mixed (LTR Para)")

end

run_tests()