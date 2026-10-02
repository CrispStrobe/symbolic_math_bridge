"""Runtime contract tests for the actual built Linux CAS shared library."""
import ctypes
import math
from pathlib import Path
import re
import sys
import unittest

LIBRARY = ctypes.CDLL(str(Path(sys.argv.pop(1)).resolve()))
LIBRARY.flutter_symengine_free_string.argtypes = [ctypes.c_void_p]
LIBRARY.flutter_symengine_free_string.restype = None

def call(name, *args):
    function = getattr(LIBRARY, 'flutter_symengine_' + name)
    function.argtypes = [ctypes.c_int if isinstance(a, int) else ctypes.c_char_p for a in args]
    function.restype = ctypes.c_void_p
    pointer = function(*(a if isinstance(a, int) else a.encode() for a in args))
    if not pointer:
        raise AssertionError(f'{name} returned null')
    try:
        return ctypes.string_at(pointer).decode()
    finally:
        LIBRARY.flutter_symengine_free_string(pointer)

def polynomial_value(expression, x):
    if not re.fullmatch(r'[x0-9+\-*/^().\s]+', expression):
        raise AssertionError(f'Unexpected polynomial syntax: {expression}')
    return eval(expression.replace('^', '**'), {'__builtins__': {}}, {'x': x})

class NativeCas(unittest.TestCase):
    def test_factoring_changes_form_and_preserves_values(self):
        for source, expected in [('x^2-9', lambda x: x*x-9),
                                 ('x^4+4', lambda x: x**4+4)]:
            result = call('factor', source)
            self.assertIn(')*(', result.replace(' ', ''), result)
            for x in [-3, -0.75, 0, 0.3, 2.5]:
                self.assertAlmostEqual(polynomial_value(result, x), expected(x), places=10)

    def test_rational_cancellation(self):
        result = call('simplify', '(x^2-1)/(x-1)')
        self.assertIn(result.replace(' ', ''), ['1+x', 'x+1'])
        for x in [-3, -0.75, 0, 1, 2.5]:
            self.assertAlmostEqual(polynomial_value(result, x), x+1, places=10)

    def test_series_coefficients(self):
        result = call('series', 'exp(x)', 'x', '0', 5)
        for x in [-2, -0.75, 0, 0.3, 2.5]:
            expected = sum(x**k / math.factorial(k) for k in range(5))
            self.assertAlmostEqual(polynomial_value(result, x), expected, places=10)

    def test_shifted_series(self):
        result = call('series', 'x^2', 'x', '2', 3)
        for x in [-2, -0.75, 0, 0.3, 2.5]:
            self.assertAlmostEqual(polynomial_value(result, x), x*x, places=10)

    def test_invalid_orders_return_errors(self):
        for order in [0, 65, -1]:
            self.assertTrue(call('series', 'exp(x)', 'x', '0', order).startswith('Error'))

if __name__ == '__main__':
    unittest.main()
