"""Run the standalone Lua 5.1 tests; requires lupa on the development machine only."""
from pathlib import Path
from lupa.lua51 import LuaRuntime

root = Path(__file__).resolve().parents[1]
lua = LuaRuntime(unpack_returned_tuples=True)
lua.globals().ADDON_ROOT = root.as_posix()
compile_lua = lua.eval("function(source, name) local fn, err = loadstring(source, name); assert(fn, err) end")
manifest = root / "ChromieCrafting.toc"
for line in manifest.read_text(encoding="utf-8").splitlines():
    if line.strip() and not line.startswith("#"):
        source = root / line.strip()
        compile_lua(source.read_text(encoding="utf-8"), source.name)
print("PASS: fichiers TOC présents et syntaxe Lua 5.1", flush=True)
lua.execute((root / "tests" / "model_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "integration_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "ui_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "chat_link_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "minimap_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "window_state_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "catalog_data_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "account_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "dashboard_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "modern_ui_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "combat_window_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "withdrawal_test.lua").read_text(encoding="utf-8"))
lua.execute((root / "tests" / "live_state_test.lua").read_text(encoding="utf-8"))
