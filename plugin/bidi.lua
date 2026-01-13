local bidi = require("bidi")

-- Setup the plugin (activates by default)
bidi.setup()

-- Create the user command
vim.api.nvim_create_user_command("Bidi", function(opts)
	local arg = opts.args:lower()
	if arg == "enable" then
		bidi.enable()
	elseif arg == "disable" then
		bidi.disable()
	else
		vim.notify("Invalid Bidi argument: " .. arg, vim.log.levels.ERROR)
	end
end, {
	nargs = 1,
	complete = function()
		return { "enable", "disable" }
	end,
	desc = "Bidi activation/deactivation"
})
