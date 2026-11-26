import ast
import unittest
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

SOURCE = Path(__file__).with_name('render_showcase.py')

class BadgeLayoutTests(unittest.TestCase):
    def test_badge_contains_text_with_padding(self):
        tree = ast.parse(SOURCE.read_text())
        nodes = [n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'pill']
        namespace = {'font': lambda size, bold: ImageFont.truetype('/usr/share/fonts/TTF/DejaVuSans-Bold.ttf', size)}
        exec(compile(ast.Module(body=nodes, type_ignores=[]), str(SOURCE), 'exec'), namespace)
        class RecordedDraw:
            def __init__(self):
                self.delegate = ImageDraw.Draw(Image.new('RGB', (1000, 100)))
            def rounded_rectangle(self, bounds, **kwargs): self.bounds = bounds
            def text(self, position, text, **kwargs):
                self.text_bounds = self.delegate.textbbox(position, text, font=kwargs['font'])
            def textbbox(self, *args, **kwargs): return self.delegate.textbbox(*args, **kwargs)
        for label in ('RETAIL + FOREVER', 'RETAIL AND FOREVER EDITIONS'):
            draw = RecordedDraw()
            namespace['pill'](draw, (81, 10), label)
            left, top, right, bottom = draw.bounds
            text_left, text_top, text_right, text_bottom = draw.text_bounds
            self.assertGreaterEqual(text_left - left, 12)
            self.assertGreaterEqual(right - text_right, 12)
            self.assertGreaterEqual(text_top, top)
            self.assertLessEqual(text_bottom, bottom)

if __name__ == '__main__': unittest.main()
