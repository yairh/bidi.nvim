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
	local hebrew = "אבג"
	local res = logic.process_line(hebrew, logic.Dir.LTR)
	assert_eq("גבא", res, "Simple Hebrew Reverse")

	-- Test 2: Hebrew English (RTL Para)
	local mixed = "שלום WORLD."
	local expected = ".WORLD םולש"
	res = logic.process_line(mixed, logic.Dir.LTR)
	assert_eq(expected, res, "Hebrew English Mixed (RTL Para)")

	-- Test 3: English Hebrew (LTR Para)
	mixed = "HELLO שלום"
	expected = "HELLO םולש"
	res = logic.process_line(mixed, logic.Dir.LTR)
	assert_eq(expected, res, "English Hebrew Mixed (LTR Para)")

	-- Test 4: Hebrew with Parentheses (All RTL)
	-- Logical: "א (ב) ג"
	-- RTL Context.
	-- 1. Mirroring: "א )ב( ג"
	-- 2. Reversal: "ג (ב) א"
	-- Visual result should look like "(ב)" but characters are swapped.
	mixed = "א (ב) ג"
	expected = "ג (ב) א"
	res = logic.process_line(mixed, logic.Dir.LTR)
	assert_eq(expected, res, "Hebrew with Parentheses (All RTL)")

	-- Test 5: Mixed with Parentheses (RTL Para)
	-- Logical: "שלום (WORLD)!"
	-- Para RTL.
	-- Run 1 (RTL): "שלום (" -> Mirrored: "שלום )" -> Reversed: ") םולש"
	-- Run 2 (LTR): "WORLD" -> Kept: "WORLD"
	-- Run 3 (RTL): ")!" -> Mirrored: "(!" -> Reversed: "!("
	-- Sequence: R3 R2 R1
	-- "!(" + "WORLD" + ") םולש"
	-- Result: "!(WORLD) םולש"
	mixed = "שלום (WORLD)!"
	expected = "!(WORLD) םולש"
	res = logic.process_line(mixed, logic.Dir.LTR)
	assert_eq(expected, res, "Mixed with Parentheses (RTL Para)")

	-- Test 6: English with Hebrew Parentheses (LTR Para)
	-- Logical: "HELLO (שלום)!"
	-- Result: "HELLO (םולש)!"
	mixed = "HELLO (שלום)!"
	expected = "HELLO (םולש)!"
	res = logic.process_line(mixed, logic.Dir.LTR)
	assert_eq(expected, res, "English with Hebrew Parentheses (LTR Para)")
end

run_tests()

