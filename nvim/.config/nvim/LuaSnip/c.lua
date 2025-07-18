local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

return {
  s("for2", {
    t({"for (int i = ", ""}), i(1, "0"), t("; i < "), i(2, "n"), t("; ++i) {"),
    t({"", "\t"}), i(3),
    t({"", "}"}),
  })
}
