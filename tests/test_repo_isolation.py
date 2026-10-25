"""Shared tooling by design: negative fixtures deliberately contain foreign identifiers."""
import importlib.util, unittest
from pathlib import Path
root=Path(__file__).resolve().parents[1]
spec=importlib.util.spec_from_file_location('repo_guard',root/'tools/check_repo_isolation.py')
guard=importlib.util.module_from_spec(spec);spec.loader.exec_module(guard)
class IsolationTests(unittest.TestCase):
    def test_wrong_content_is_blocked(self):
        other='Heirs of Fortune' if guard.PROFILE=='a_Variant' else 'Marchland Oaths'
        self.assertTrue(guard.inspect_text('scripts/Shipping.gd', 'var title="'+other+'"'))
    def test_other_moods_are_blocked(self):
        other='tycoon' if guard.PROFILE=='a_Variant' else 'combat'
        self.assertTrue(guard.inspect_text('assets/audio/catalog.json', '{"music":{"'+other+'":{}}}'))
    def test_key_material_is_blocked_even_in_shared_tools(self):
        secret='AIza'+'X'*35
        self.assertTrue(guard.inspect_text('tools/generate_audio.py',secret))
    def test_shared_tooling_is_explained(self):
        self.assertEqual([],guard.inspect_text('tools/generate_audio.py','Marchland Oaths Heirs of Fortune'))
        self.assertIn('shared tooling by design',guard.EXCEPTIONS['tools/generate_audio.py'])
    def test_normal_text_is_allowed(self):
        self.assertEqual([],guard.inspect_text('scripts/Shipping.gd','var amount=1.0 # no credential'))
if __name__=='__main__': unittest.main()
