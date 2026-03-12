import unittest
from btl_calc.calculations import calculate_effective_rate, calculate_total_fees

class TestCalculations(unittest.TestCase):

    def test_calculate_effective_rate(self):
        # Example test case for effective rate calculation
        principal = 100000
        interest_rate = 0.05
        term_years = 30
        expected_effective_rate = 0.05  # Replace with the expected value based on your logic
        result = calculate_effective_rate(principal, interest_rate, term_years)
        self.assertAlmostEqual(result, expected_effective_rate, places=5)

    def test_calculate_total_fees(self):
        # Example test case for total fees calculation
        fees = [100, 200, 300]
        expected_total_fees = 600  # Replace with the expected value based on your logic
        result = calculate_total_fees(fees)
        self.assertEqual(result, expected_total_fees)

if __name__ == '__main__':
    unittest.main()